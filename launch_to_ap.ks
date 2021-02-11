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
    lock accvec to ship:sensors:acc - ship:sensors:grav.
    lock gforce to accvec:mag / g_pid.
    lock current_pitch to 90.
    lock steering to heading(0, current_pitch, 0).
    print "Liftoff".
    print "Climbing to 700m".
    stage.
    until (alt:radar > 700)
    {
        set thrott_pid to max(0, min(1, thrott_pid + pid:update(time:seconds, gforce))).
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
    lock accvec to ship:sensors:acc - ship:sensors:grav.
    lock gforce to accvec:mag / g_pid.
    lock current_pitch to -8.94037E-8 * alt:radar * alt:radar - 0.00370273 * alt:radar + 91.4233.
    lock steering to heading(inst_az(target_inc), current_pitch).
    until (alt:radar > 10000)
    {
        set thrott_pid to max(0, min(1, thrott_pid + pid:update(time:seconds, gforce))).
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
    lock accvec to ship:sensors:acc - ship:sensors:grav.
    lock gforce to accvec:mag / g_pid.
    set pid:setpoint to 2.5.
    when (alt:radar > 30000) then set pid:setpoint to 3.0.
    declare local switch_to_orbit to false.
    declare local fairings_deployed to false.
    declare local max_pitch to 45.
    declare local min_pitch to 15.
    lock prograde_pitch to 90 - vang(ship:srfprograde:vector, up:vector).
    // lock current_pitch to max(min(prograde_pitch, max_pitch), min_pitch).
    lock steering to heading(inst_az(target_inc), prograde_pitch).
    until (ship:apoapsis > target_ap)
    {
        if (switch_to_orbit = false and ship:velocity:orbit:mag > 1650)
        {
            set switch_to_orbit to true.
            lock prograde_pitch to 90 - vang(ship:prograde:vector, up:vector).
        }
        if (fairings_deployed = false and alt:radar > 65000)
        {
            set fairings_deployed to true.
            deploy_fairing().
        }
        when (alt:radar > 60000) then set min_pitch to 8.
        when (alt:radar > 70000) then set min_pitch to 0.
        set thrott_pid to max(0, min(1, thrott_pid + pid:update(time:seconds, gforce))).
        if (check_stage_thrust() = false) autostage().
        wait 0.01.
    }
    if (alt:radar < 60000) wait 0.2.            // these two lines boost apoapsis slightly to negate for atmospheric drag
    else if (alt:radar < 65000) wait 0.1.

    lock throttle to 0.
    lock steering to prograde.
    print "Engine Shutdown".
    if (fairings_deployed = false)
    {
        until (alt:radar > 65000) wait 0.1.
        deploy_fairing().
    }
}