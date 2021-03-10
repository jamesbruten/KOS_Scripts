function moon_return
{
    lock throttle to 0.
    lock steering to prograde.

    local ang_vel is vang(ship:velocity:orbit, ship:body:velocity).
    local target_ang is 180.
    if (ship:orbit:inclination > 90) set target_ang to 0.
    local diff is abs(ang_vel - target_ang).
    local warp_level is 0.
    
    until false
    {
        clearscreen.
        print "Warping to Opposite Kerbin".
        print "Current: " + ang_vel + "    Diff: " + diff + "   Warp Level: " + warp_level.
        if (diff < 0.2)
        {
            set warp to 0.
            wait until ship:unpacked.
            break.
        }
        else if (diff < 1)
        {
            set warp to 2.
            set warp_level to 2.
        }
        else if (diff < 10)
        {
            set warp to 4.
            set warp_level to 4.
        }
        else
        {
            set warp to 5.
            set warp_level to 5.
        }
    }

    wait 10.
    lock throttle to 0.
    until false
    {
        if (ship:orbit:hasnextpatch)
        {
            if (ship:orbit:nextpatch:periapsis < 30000) break.
        }
    }
    lock throttle to 0.

    print "Warping to Next Body".
    local old_body is ship:body.
    do_warp(ship:orbit:nextpatcheta).
    wait until old_body <> ship:body.
    wait 5.

    reentry().
}

function kerbin_deorbit
{
    lock steering to retrograde.
    wait 10.
    lock throttle to 1.
    wait until ship:periapsis < 30000.
    lock throttle to 0.

    reentry().
}

function reentry
{
    if (eta:periapsis > 20*60)
    {
        local wait_time is eta:periapsis - 20*60.
        local wait_end is time:seconds + wait_time.
        do_warp(wait_time-5).
        wait until time:seconds > wait_end.
    }

    lock steering to retrograde.
    wait 10.
    print "Set Decouple to AG 9".
    lock inp to terminal:input:getchar().
    print "Hit 'l' to continue".
    wait until inp = "l".
    AG9 on. 

    set warp to 4.
    wait until ship:altitude < 70000.
    set warp to 0.
    wait until alt:radar < 60000.
    print "Steering Off".
    unlock steering.
    wait until alt:radar < 6000.
    print "Deploy Chutes".
    chutes on.
}