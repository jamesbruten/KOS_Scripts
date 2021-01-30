function main
{
    declare global target_ap_km to 100.
    declare global target_pe_km to 100.
    declare global target_ap to target_ap_km * 1000.
    declare global target_pe to target_pe_km * 1000.
    declare global target_inc to 90.
    // Do Countdown
    countdown().
    // Do Launch to 1500 - steering up, thrust max
    initial_launch().
    // fly on defined pitch heading to 10km
    to_ten_km().
    // fly prograde until apoapsis height reached.
    prograde_climb().
    wait until false.
}

function countdown
{
    // Countdown and ignition of engines
    lock throttle to 1.
    local tminus is 5.
    until (tminus < 1)
    {
        clearscreen.
        print "Target Apoapsis:    " + target_ap_km.
        print "Target Periapsis:   " + target_pe_km.
        print "Target Inclination: " + target_inc.
        print "".
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
}

function initial_launch
{
    lock current_pitch to 90.
    lock steering to heading(0, current_pitch, 0).
    print "Liftoff".
    print "Climbing to 700m".
    stage.
    until (alt:radar > 700)
    {
        if (check_stage_thrust() = false) autostage().
        wait 0.02.
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
    lock current_pitch to -8.94037E-8 * alt:radar * alt:radar - 0.00370273 * alt:radar + 91.4233.
    lock steering to heading(target_inc, current_pitch).
    until (alt:radar > 10000)
    {
        if (check_stage_thrust() = false) autostage().
        wait 0.01.
    }
}

function prograde_climb
{
    // Holds ship at 45 degrees or the pitch of prograde vector - whichever is lower
    // Prograde initially from surface velocity - changes to orbital when orbital speed > 1650
    // Cuts engines when target apoapsis reached
    // Deploys fairings once above 50km

    print "Climbing on Prograde Pitch".
    declare local switch_to_orbit to false.
    declare local fairings_deployed to false.
    declare local max_pitch to 45.
    lock prograde_pitch to 90 - vang(ship:srfprograde:vector, up:vector).
    lock current_pitch to min(prograde_pitch, max_pitch).
    lock steering to heading(target_inc, current_pitch).
    until (ship:apoapsis > target_ap)
    {
        // print prograde_pitch.
        if (check_stage_thrust() = false) autostage().
        if (switch_to_orbit = false and ship:velocity:orbit:mag > 1650)
        {
            set switch_to_orbit to true.
            lock prograde_pitch to 90 - vang(ship:prograde:vector, up:vector).
        }
        if (fairings_deployed = false and alt:radar > 50000)
        {
            set fairings_deployed to true.
            deploy_fairing().

        }
        wait 0.01.
    }
    lock throttle to 0.
    print "Engine Shutdown".
    if (fairings_deployed = false)
    {
        until (alt:radar > 50000) wait 0.1.
        deploy_fairing().
    }
}

function check_stage_thrust
{
    // compares previous 
    if not (defined old_thrust) declare global old_thrust to ship:availablethrust.
    if (old_thrust = 0) set old_thrust to ship:availablethrust.
    if (ship:availablethrust < old_thrust - 2)
    {
        print "Flameout".
        set old_thrust to 0.
        return false.
    }
    return true.
}

function autostage
{
    // function to complete interstages
    // stages once for decoupler, then waits 0.5, then stages to ignite next stage
    print "Staging: Decoupler".
    WAIT 1.
    stage.
    if (ship:availablethrust < 0.1)
    {
        print "Staging: Ignition".
        WAIT 1.
        stage.
    }
}

function deploy_fairing
{
    // Function to deploy fairings

    print "Fairing Jettison".
    for p in ship:parts
    {
        if p:hasmodule("moduleproceduralfairing")
        {
            local decoupler is p:getmodule("moduleproceduralfairing").
            if decoupler:hasevent("deploy") decoupler:doevent("deploy").
        }
    }
}

main().