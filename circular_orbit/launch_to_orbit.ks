function main
{
    // Do Countdown
    countdown().
    // Do Launch to 1500 - steering up, thrust max
    initial_launch().
    lock throttle to 0.
    stage.
}

function countdown
{
    // Countdown and ignition of engines
    lock throttle to 1.
    lock steering to up.
    local tminus is 5.
    until tminus < 0
    {
        clearscreen.
        print "Initiating Launch Program".
        print "t-minus: " + tminus.
        if tminus < 3
        {
            print "Engine Ignition".
            if tminus = 2 stage.
        }
        set tminus to tminus - 1.
        WAIT 1.
    }
}

function initial_launch
{
    clearscreen.
    print "Liftoff".
    print "Climbing to 1.5km".
    stage.
    until alt:radar > 1500
    {
        if check_stage_running() = false
        {
            autostage().
        }
        WAIT 0.1.
    }
}

function check_stage_running
{
    // make sure stage is still running
    return true.
}

function autostage
{
    // function to complete interstages
    // stages once for decoupler, then WAITs 0.3, then stages to ignite next stage
    WAIT 0.5.
    stage.
    WAIT 0.5.
    stage.
}

main().