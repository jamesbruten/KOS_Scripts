function shuttle_launch_to_ap
{
    parameter auto.
    set steeringmanager:maxstoppingtime to 0.1.

    print "Target Apoapsis:    " + target_ap_km.
    print "Target Periapsis:   " + target_pe_km.
    print "Target Inclination: " + target_inc.

    if (auto = false)
    {
        local gui is gui(150,30).
        set gui:x to -250.
        set gui:y to 200.
        local label is gui:addlabel("Press to Launch").
        set label:style:align to "center".
        set label:style:hstretch to true.
        local bpressed is false.
        local b is gui:addbutton("Launch").
        set b:onclick to {set bpressed to true.}.
        gui:show().
        wait until bpressed.
        clearguis().
    }

    pid_throttle_gforce().
    set pid_gforce:minoutput to 0.4.
    
    // Do Countdown
    countdown().

    // Do Launch to Xm - steering up, thrust max
    initial_launch(90).

    // fly on defined pitch + heading to 10km
    shuttle_pitch_over().

    // fly prograde until apoapsis height reached.
    shuttle_prograde_climb().

    lock steering to prograde.

    if (alt:radar >= 69800) wait 5.
    else wait until alt:radar >= 70000.

    // circularise the shuttle
    shuttle_circularise().

    deploy_bay_doors().
    deploy_dp_shield().
}

function shuttle_pitch_over
{
    // Then pitches over to reach 45 degrees in set amount of time
    // The path is a quadratic given by pitch_over_params
    // Higher orbits == longer pitch over times
    // calculates heading from inst_az calculation

    local pitch_params is pitch_over_params().
    local pitch1 is pitch_params[0].
    local pitch2 is pitch_params[1].
    local pitch3 is pitch_params[2].
    local final_alt is pitch_params[3].

    print "Initiating Pitch and Roll Maneuver".
    set current_pitch to 90.
    set needed_az to inst_az(target_inc).

    lock steering to heading(needed_az, current_pitch, 180).

    until (alt:radar > final_alt)
    {
        if (alt:radar > 500)
        {
            set current_pitch to pitch1*alt:radar*alt:radar + pitch2*alt:radar + pitch3.
            set needed_az to inst_az(target_inc).
        }

        set accvec to ship:sensors:acc - ship:sensors:grav.
        set gforce to accvec:mag / g_pid.
        set thrott_pid to max(0, min(1, thrott_pid + pid_gforce:update(time:seconds, gforce))).

        if (check_stage_thrust() = false) autostage().
    }
    AG18 on.
}

function shuttle_prograde_climb
{
    // Holds ship at 45 degrees or the pitch of prograde vector - whichever is lower
    // Prograde initially from surface velocity - changes to orbital when orbital speed > 1650
    // Cuts engines when target apoapsis reached

    print "Climbing on Prograde Pitch".

    set pid_gforce:setpoint to 2.5.
    
    local max_pitch is 50.
    local min_pitch is 15.
    
    set prograde_pitch to 90 - vang(ship:srfprograde:vector, up:vector).
    set current_pitch to max(min(prograde_pitch, max_pitch), min_pitch).
    set needed_az to inst_az(target_inc).

    lock steering to heading(needed_az, current_pitch-5, 180).

    when (alt:radar > 60000) then set min_pitch to 5.
    when (alt:radar > 70000) then set min_pitch to 0.

    until (ship:apoapsis > target_ap)
    {
        if (ship:velocity:orbit:mag < 1650) set prograde_pitch to 90 - vang(ship:srfprograde:vector, up:vector).
        else set prograde_pitch to 90 - vang(ship:prograde:vector, up:vector).

        set current_pitch to max(min(prograde_pitch, max_pitch), min_pitch).
        if (ship:velocity:orbit:mag < 2150) set needed_az to inst_az(target_inc).
        else set needed_az to compass_for().

        set accvec to ship:sensors:acc - ship:sensors:grav.
        set gforce to accvec:mag / g_pid.
        set thrott_pid to max(0, min(1, thrott_pid + pid_gforce:update(time:seconds, gforce))).

        if (check_stage_thrust() = false) autostage().
    }
    
    if (alt:radar < 60000) wait 0.2.
    else if (alt:radar < 65000) wait 0.1.

    lock throttle to 0.
    lock steering to prograde.
    print "Engine Shutdown".
}

function shuttle_circularise
{
    AG17 on.
    set steeringmanager:maxstoppingtime to 2.

    adjust_apsides("a", ship:apoapsis, false).
    set mnv to nextnode.
    lock np to lookdirup(mnv:deltav, up:vector).
    lock steering to np.

    //print out node's basic parameters - ETA and deltaV
    print "Node in: " + round(mnv:eta) + ", DeltaV: " + round(mnv:deltav:mag).

    //calculate ship's max acceleration
    set max_acc to ship:maxthrust/ship:mass.

    //now we just need to divide deltav:mag by our ship's max acceleration
    set burn_duration to mnv:deltav:mag/max_acc.
    print "Estimated burn duration: " + round(burn_duration) + "s".

    wait 5.
    do_warp(mnv:eta-60-burn_duration).

    RCS on.

    //now we need to wait until the burn vector and ship's facing are aligned
    wait until abs(np:pitch - facing:pitch) < 0.3 and abs(np:yaw - facing:yaw) < 0.3.
    wait until mnv:eta <= burn_duration.
    lock throttle to 1.
    until (ship:periapsis > 29750)
    {
        for p in ship:parts {
            for r in p:resources {
                if (r:enabled = true and r:name = "liquidfuel" and r:amount < 1) break.
            }
        } 
    }
    lock throttle to 0.
    wait 5.
    stage.
    for p in ship:parts {
        for r in p:resources {
            if (r:enabled = false) set r:enabled to true.
        }
    }
    wait 3.
    RCS off.
    unlock steering.
    remove_maneuver(mnv).

    adjust_apsides("a", ship:apoapsis).
}