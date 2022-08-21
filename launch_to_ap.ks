// functions to go from countdown to engine shutdown when apoapsis >= target

function launch_to_ap
{
    parameter auto.

    for p in ship:parts
    {
        if (p:tag = "shuttle") 
        {
            print "Shuttle Launch".
            shuttle_launch_to_ap(auto).
            return.
        }
    }
    
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
        
    // Do Countdown
    countdown().

    pid_throttle_gforce().

    // Do Launch to 700m - steering up, thrust max
    initial_launch().

    // fly on defined pitch + heading to 10km
    pitch_over().

    // fly prograde until apoapsis height reached.
    prograde_climb().

    if (alt:radar >= 69800) wait 5.
    else wait until alt:radar >= 70000.
    set steeringmanager:maxstoppingtime to 0.5.

    adjust_apsides("a", ship:apoapsis).
}

function countdown
{
    // Countdown and ignition of engines
    local tminus is 5.
    set thrott_pid to 0.
    until (tminus < 1)
    {
        clearscreen.
        print "Target Apoapsis:    " + target_ap_km.
        print "Target Periapsis:   " + target_pe_km.
        print "Target Inclination: " + target_inc.
        print " ".
        print "Initiating Launch Program".
        print "t-minus: " + tminus.

        local tval is 0.
        lock throttle to tval.
        if (tminus < 3)
        {
            print "Engine Ignition".
            if (tminus = 2) stage.
            local tstep is 0.
            until (tstep = 20)
            {
                set tval to tval + 0.5 / 20.
                set tstep to tstep + 1.
                wait 0.05.
            }
        }
        else wait 1.
        set tminus to tminus - 1.
    }
    clearscreen.
    print "Target Apoapsis:    " + target_ap_km.
    print "Target Periapsis:   " + target_pe_km.
    print "Target Inclination: " + target_inc.
    print " ".
    print "Initiating Launch Program".
    print "t-minus: " + 0.
    print "Engine Ignition".
}

function initial_launch
{
    parameter initial_height is 500.

    lock steering to lookdirup(ship:up:vector, ship:facing:topvector).

    stage.
    print "Liftoff".
    print "Climbing to " + initial_height + "m".

    until (alt:radar > initial_height)
    {
        set accvec to ship:sensors:acc - ship:sensors:grav.
        set gforce to accvec:mag / g_pid.
        print "time: " + time:seconds + "   gforce: " + gforce.
        local update is pid_gforce:update(time:seconds, gforce).
        set thrott_pid to max(0, min(1, thrott_pid + update)).
        print "Gforce: " + gforce + "   TForce: " + pid_gforce:setpoint + "   throttle: " + thrott_pid + "   update: " + update.

        if (check_stage_thrust() = false) autostage().
    }
}

function pitch_over
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
    set current_pitch to pitch1*alt:radar*alt:radar + pitch2*alt:radar + pitch3.
    set needed_az to inst_az(target_inc).
    
    lock steering to heading(needed_az, current_pitch).

    until (alt:radar > final_alt)
    {
        set current_pitch to pitch1*alt:radar*alt:radar + pitch2*alt:radar + pitch3.
        set needed_az to inst_az(target_inc).

        set accvec to ship:sensors:acc - ship:sensors:grav.
        set gforce to accvec:mag / g_pid.
        set thrott_pid to max(0, min(1, thrott_pid + pid_gforce:update(time:seconds, gforce))).

        if (check_stage_thrust() = false) autostage().

        wait 0.01.
    }
}

function prograde_climb
{
    // Holds ship at 45 degrees or the pitch of prograde vector - whichever is lower
    // Prograde initially from surface velocity - changes to orbital when orbital speed > 1650
    // Cuts engines when target apoapsis reached
    // Deploys fairings once above 65km

    print "Climbing on Prograde Pitch".

    set pid_gforce:setpoint to 2.5.
    local fairings_deployed is false.
    
    local max_pitch is 45.
    local min_pitch is 10.
    
    set prograde_pitch to 90 - vang(ship:srfprograde:vector, up:vector).
    set current_pitch to max(min(prograde_pitch, max_pitch), min_pitch).
    set needed_az to inst_az(target_inc).

    lock steering to heading(needed_az, current_pitch).

    when (alt:radar > 60000) then set min_pitch to 5.
    when (alt:radar > 70000) then set min_pitch to 0.
    when (ship:velocity:orbit:mag > 2150) then lock steering to prograde.

    until (ship:apoapsis > target_ap)
    {
        if (ship:velocity:orbit:mag < 1650) set prograde_pitch to 90 - vang(ship:srfprograde:vector, up:vector).
        else set prograde_pitch to 90 - vang(ship:prograde:vector, up:vector).

        set current_pitch to max(min(prograde_pitch, max_pitch), min_pitch).
        set needed_az to inst_az(target_inc).

        set accvec to ship:sensors:acc - ship:sensors:grav.
        set gforce to accvec:mag / g_pid.
        set thrott_pid to max(0, min(1, thrott_pid + pid_gforce:update(time:seconds, gforce))).

        if (fairings_deployed = false and alt:radar > 55000)
        {
            set fairings_deployed to true.
            deploy_fairing().
        }

        if (check_stage_thrust() = false) autostage().

        wait 0.01.
    }
    
    if (alt:radar < 60000) wait 0.2.
    else if (alt:radar < 65000) wait 0.1.

    lock throttle to 0.
    lock steering to prograde.
    print "Engine Shutdown".

    if (fairings_deployed = false) deploy_fairing().

    for p in ship:parts
    {
        if (p:tag = "stage1")
        {
            local init_mass is ship:mass.
            print "Dropping 1st Stage".
            wait 3.5.
            stage.
            wait 1.
            if (ship:mass < 0.99 * init_mass) stage.
            wait 5.
        }
    }

    list engines in shipEngines.
    for en in shipEngines {
        if (en:tag = "en1") en:shutdown.
        if (en:tag = "en2") en:activate. 
    }
}

function launch_to_vac
{
    parameter ap_height, orb_inc.

    set steeringmanager:maxstoppingtime to 0.1.

    lock throttle to 0.
    list engines in ship_engines.
    for en in ship_engines
    {
        set en:thrustlimit to 100.
        en:activate.
    }
    lock steering to lookdirup(up:forevector, ship:facing:topvector).

    pid_throttle_gforce().
    set pid_gforce:setpoint to 3.0.
    set accvec to ship:sensors:acc - ship:sensors:grav.
    set gforce to accvec:mag / g_pid.
    lock throttle to thrott_pid.

    local needed_az is inst_az(orb_inc).
    local last_heading is needed_az.
    
    countdown().
    
    lock steering to heading(needed_az, 45).
    when (alt:radar > 150) then gear off.
    when (alt:radar > 500) then lock steering to heading(needed_az, 5).
    until (ship:apoapsis >= ap_height - 100)
    {
        set accvec to ship:sensors:acc - ship:sensors:grav.
        set gforce to accvec:mag / g_pid.
        set thrott_pid to max(0, min(1, thrott_pid + pid_gforce:update(time:seconds, gforce))).

        if (ship:periapsis < -40000)
        {
           set needed_az to inst_az(orb_inc).
           set last_heading to needed_az.
        }
        else set needed_az to last_heading.
    }
    print "Shutdown".
    lock throttle to 0.
    lock steering to prograde.
    set steeringmanager:maxstoppingtime to 0.75.
    wait 5.

    adjust_apsides("a", ship:apoapsis).
}

function pitch_over_params
{
    if (target_ap_km > 145) return list(-1.48781044e-07, -3.09494190e-03, 9.10359649e+01, 10000).
    return list(-3.91456583e-07, -2.65203081e-03, 9.11089286e+01, 8000).
}