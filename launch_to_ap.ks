// functions to go from countdown to engine shutdown when apoapsis >= target

function launch_to_ap
{
    parameter auto.
    set steeringmanager:maxstoppingtime to 0.1.

    print "Target Apoapsis:    " + target_ap_km.
    print "Target Periapsis:   " + target_pe_km.
    print "Target Inclination: " + target_inc.

    if (auto = false)
    {
        lock inp to terminal:input:getchar().
        print "Hit 'l' to launch".
        wait until inp = "l".
    }

    pid_throttle_gforce().
    
    // Do Countdown
    countdown().

    // Do Launch to 1500 - steering up, thrust max
    initial_launch().

    // fly on defined pitch heading to 10km
    to_ten_km().

    // fly prograde until apoapsis height reached.
    prograde_climb().

    if (alt:radar >= 69800) wait 10.
    else wait until alt:radar >= 70000.
    set steeringmanager:maxstoppingtime to 0.5.
}

function countdown
{
    // Countdown and ignition of engines
    local tminus is 5.
    until (tminus < 1)
    {
        clearscreen.
        print "Target Apoapsis:    " + target_ap_km.
        print "Target Periapsis:   " + target_pe_km.
        print "Target Inclination: " + target_inc.
        print " ".
        print "Initiating Launch Program".
        print "t-minus: " + tminus.
        if (tminus < 2)
        {
            print "Engine Ignition".
            if (tminus = 1) stage.
        }
        set tminus to tminus - 1.
        WAIT 1.
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
    set accvec to ship:sensors:acc - ship:sensors:grav.
    set gforce to accvec:mag / g_pid.
    lock steering to heading(0, 90, 0).
    print "Liftoff".
    print "Climbing to 700m".
    stage.
    until (alt:radar > 700)
    {
        set accvec to ship:sensors:acc - ship:sensors:grav.
        set gforce to accvec:mag / g_pid.
        set thrott_pid to max(0, min(1, thrott_pid + pid_gforce:update(time:seconds, gforce))).
        if (check_stage_thrust() = false) autostage().
        wait 0.01.
    }
}

function to_ten_km
{
    // Will fly this path calculated from WA
    // -8.94037×10^-8 x^2 - 0.00370273 x + 91.4233 (quadratic) where x is altitude
    // Starts at 700m with pitch of 90
    // Ends at 10km with pitch of 45
    // Currently just following inclination azimuth

    print "Initiating Pitch and Roll Maneuver".
    set accvec to ship:sensors:acc - ship:sensors:grav.
    set gforce to accvec:mag / g_pid.
    set current_pitch to -8.94037E-8 * ship:altitude * ship:altitude - 0.00370273 * ship:altitude + 91.4233.
    set needed_az to inst_az(target_inc).
    lock steering to heading(needed_az, current_pitch).
    until (ship:altitude > 10000)
    {
        set accvec to ship:sensors:acc - ship:sensors:grav.
        set gforce to accvec:mag / g_pid.
        set current_pitch to -8.94037E-8 * ship:altitude * ship:altitude - 0.00370273 * ship:altitude + 91.4233.
        set needed_az to inst_az(target_inc).
        set thrott_pid to max(0, min(1, thrott_pid + pid_gforce:update(time:seconds, gforce))).
        if (check_stage_thrust() = false) autostage().
    }
}

function prograde_climb
{
    // Holds ship at 45 degrees or the pitch of prograde vector - whichever is lower
    // Prograde initially from surface velocity - changes to orbital when orbital speed > 1650
    // Cuts engines when target apoapsis reached
    // Deploys fairings once above 65km

    print "Climbing on Prograde Pitch".

    set accvec to ship:sensors:acc - ship:sensors:grav.
    set gforce to accvec:mag / g_pid.
    set pid_gforce:setpoint to 2.5.
    local fairings_deployed is false.
    local max_pitch is 45.
    local min_pitch is 15.
    set prograde_pitch to 90 - vang(ship:srfprograde:vector, up:vector).
    set current_pitch to max(min(prograde_pitch, max_pitch), min_pitch).
    set needed_az to inst_az(target_inc).

    lock steering to heading(needed_az, current_pitch).

    when (alt:radar > 27000) then set pid_gforce:setpoint to 3.0.
    when (alt:radar > 60000) then set min_pitch to 8.
    when (alt:radar > 70000) then set min_pitch to 0.
    when (ship:velocity:orbit:mag > 2150) then lock steering to prograde.

    until (ship:apoapsis > target_ap)
    {
        set accvec to ship:sensors:acc - ship:sensors:grav.
        set gforce to accvec:mag / g_pid.
        if (ship:velocity:orbit:mag < 1650) set prograde_pitch to 90 - vang(ship:srfprograde:vector, up:vector).
        else set prograde_pitch to 90 - vang(ship:prograde:vector, up:vector).
        set current_pitch to max(min(prograde_pitch, max_pitch), min_pitch).
        set needed_az to inst_az(target_inc).
        set thrott_pid to max(0, min(1, thrott_pid + pid_gforce:update(time:seconds, gforce))).

        if (fairings_deployed = false and alt:radar > 55000)
        {
            set fairings_deployed to true.
            deploy_fairing().
        }

        if (check_stage_thrust() = false) autostage().
    }
    
    if (alt:radar < 60000) wait 0.2.            // these two lines boost apoapsis slightly to negate for atmospheric drag
    else if (alt:radar < 65000) wait 0.1.

    lock throttle to 0.
    lock steering to prograde.
    print "Engine Shutdown".

    for p in ship:parts
    {
        if (p:tag = "stage1")
        {
            print "Dropping 1st Stage".
            wait 5.
            stage.
            wait 1.
            stage.
            wait 5.
        }
    }

    if (fairings_deployed = false)
    {
        until (alt:radar > 55000) wait 0.1.
        deploy_fairing().
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

    local needed_az is inst_az(orb_inc).
    local last_heading is needed_az.
    
    local tminus is 5.
    until (tminus < 1)
    {
        clearscreen.
        print "Target Apoapsis: " + ap_height/1000.
        print "Target Inclination: " + orb_inc.
        print "t-minus: " + tminus.
        set tminus to tminus - 1.
        wait 1.
    }
    clearscreen.
    print "Target Apoapsis: " + ap_height.
    print "Target Inclination: " + orb_inc.
    print "Liftoff".

    lock throttle to 1.
    wait 1.
    
    lock steering to heading(needed_az, 45).
    gear off.
    when (alt:radar > 1000) then lock steering to heading(needed_az, 0).
    until (ship:apoapsis >= ap_height - 100)
    {
        if (ship:periapsis < -30000)
        {
           set needed_az to inst_az(orb_inc).
           set last_heading to needed_az.
        }
        else set needed_az to last_heading.
    }
    print "Shutdown".
    lock throttle to 0.
    lock steering to prograde.
}