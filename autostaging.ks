// autostaging functions

function check_stage_thrust
{
    // compares old max thrust to current max thrust
    // stages if current less than old
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
    if (ship:availablethrust < 0.01)
    {
        print "Staging: Ignition".
        WAIT 2.
        stage.
    }
}