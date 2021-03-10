function moon_return
{
    lock throttle to 0.
    lock steering to prograde.

    local pos_ang is vang(ship:position - ship:body:position, kerbin:position - ship:body:position).
    local target_ang is 0.
    if (ship:orbit:inclination > 90) set target_ang to 180.
    local diff is abs(pos_ang - target_ang).
    local warp_level is 0.
    
    until false
    {
        clearscreen.
        print "Warping to Opposite Kerbin".
        print "Current: " + pos_ang + "    Diff: " + diff + "   Warp Level: " + warp_level.
        if (diff < 5)
        {
            set warp to 0.
            wait until ship:unpacked.
            break.
        }
        else if (diff < 6)
        {
            set warp to 2.
            set warp_level to 2.
        }
        else if (diff < 12)
        {
            set warp to 4.
            set warp_level to 4.
        }
        else
        {
            set warp to 5.
            set warp_level to 5.
        }
        set pos_ang to vang(ship:position - ship:body:position, kerbin:position - ship:body:position).
        set diff to abs(pos_ang - target_ang).
    }

    wait 10.
    lock throttle to 1.
    until false
    {
        if (ship:orbit:hasnextpatch)
        {
            if (ship:orbit:nextpatch:periapsis < 30000) break.
        }
    }
    lock throttle to 0.
    lock steering to retrograde.

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
    wait 10.

    deploy_dp_shield().

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