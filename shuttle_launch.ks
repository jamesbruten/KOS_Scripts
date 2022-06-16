function shuttle_launch_to_ap
{
    parameter auto.
    set steeringmanager:maxstoppingtime to 0.1.

    resetoss().

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

    // Do Launch to 150m - steering up, thrust max
    initial_launch(150).

    // fly on defined pitch + heading to 10km
    shuttle_pitch_over().

    // fly prograde until apoapsis height reached.
    shuttle_prograde_climb().

    if (alt:radar >= 69800) wait 5.
    else wait until alt:radar >= 70000.
    set steeringmanager:maxstoppingtime to 0.5.

    // circularise the shuttle
    shuttle_circularise().
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

    lock steering to offsetSteering(heading(needed_az, current_pitch, 180)).

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
    
    local max_pitch is 45.
    local min_pitch is 10.
    
    set prograde_pitch to 90 - vang(ship:srfprograde:vector, up:vector).
    set current_pitch to max(min(prograde_pitch, max_pitch), min_pitch).
    set needed_az to inst_az(target_inc).

    // lock steering to offsetSteering(heading(needed_az, current_pitch, 180)).
    lock steering to heading(needed_az, current_pitch, 180).
    when (ship:altitude > 45000) then lock steering to offsetSteering(heading(needed_az, current_pitch)).

    when (alt:radar > 60000) then set min_pitch to 5.
    when (alt:radar > 70000) then set min_pitch to 0.
    when (ship:velocity:orbit:mag > 2150) then lock steering to offsetSteering(prograde).

    until (ship:apoapsis > target_ap)
    {
        if (ship:velocity:orbit:mag < 1650) set prograde_pitch to 90 - vang(ship:srfprograde:vector, up:vector).
        else set prograde_pitch to 90 - vang(ship:prograde:vector, up:vector).

        set current_pitch to max(min(prograde_pitch, max_pitch), min_pitch).
        set needed_az to inst_az(target_inc).

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
    adjust_apsides("a", ship:apoapsis, false).
    set mnv to nextnode.
    set pid_gforce:setpoint to 3.
    set burn_duration to mnv:deltav:mag/pid_gforce:setpoint.

    RCS on.

    wait 5.
    do_warp(mnv:eta-90-burn_duration/2).
    wait until mnv:eta <= (burn_duration/2 + 87).
    
    wait until mnv:eta <= (burn_duration/2 + 30).
    RCS off.
    lock steering to offsetSteering(prograde).
    lock throttle to thrott_pid.
    until (ship:periapsis > 29750)
    {
        set accvec to ship:sensors:acc - ship:sensors:grav.
        set gforce to accvec:mag / g_pid.
        set thrott_pid to max(0, min(1, thrott_pid + pid_gforce:update(time:seconds, gforce))).
        
        if (check_stage_thrust() = false) break. 
    }

    wait 1.
    stage.
    lock steering to prograde.
    resetoss().
    wait 1.
    AG17 on.

    if (eta:apoapsis > eta:periapsis)
    {
        lock steering to prograde.
        wait 5.
        lock throttle to 1.
        wait until ship:periapsis > 70000.
        lock throttle to 0.
    }
    adjust_apsides("a", ship:apoapsis, false).

}