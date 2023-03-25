function moon_return
{
    lock throttle to 0.
    lock steering to prograde.

    local pos_ang is vang(ship:position - ship:body:position, kerbin:position - ship:body:position).
    local target_ang is 0.
    if (ship:orbit:inclination > 90) set target_ang to 180.
    local diff is abs(pos_ang - target_ang).
    local warp_level is 0.

    if (ship:body = Minmus)
    {
        until false
        {
            local lat_minmus is ship:body:latitude.

            set warp_level to warp_at_level(0.229, 0.23, 0.27, abs(lat_minmus), 6).
            if (warp_level = 0) break.

            clearscreen.
            print "Warping to 0 Latitude Kerbin".
            print "Lat: " + round(lat_minmus, 2) + "   Warp Level: " + warp_level.
        }
    }
    
    until false
    {
        set pos_ang to vang(ship:position - ship:body:position, kerbin:position - ship:body:position).
        set diff to abs(pos_ang - target_ang).

        set warp_level to warp_at_level(5, 6, 12, diff).
        if (warp_level = 0) break.

        clearscreen.
        print "Warping to Opposite Kerbin".
        print "Current: " + round(pos_ang, 2) + "    Diff: " + round(diff, 2) + "   Warp Level: " + warp_level.
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
    wait 5.

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
    wait until ship:periapsis < 20000.
    lock throttle to 0.

    reentry().
}

function deploy_chutes {
    print "Deploy Drogues".
    for p in ship:parts {
        if p:title:tolower:contains("drogue") {
            local dp is p:getmodule("realchutemodule").
            if dp:hasevent("deploy chute") dp:doevent("deploy chute").
        }
    }
    wait until alt:radar < 1500.
    print "Deploy Mains".
    for p in ship:parts {
        if p:title:tolower:contains("parachute") {
            local dp is p:getmodule("realchutemodule").
            if dp:hasevent("deploy chute") dp:doevent("deploy chute").
        }
    }
    when (alt:radar < 650) then print "Inflate Mains".
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
    
    wait 2.
    lock steering to vcrs(ship:velocity:orbit, -body:position).
    wait 1.

    deploy_dp_shield("close").
    retract_solar_panels().


    local check is false.
    for p in ship:parts
    {
        if (p:tag = "reentry")
        {
            print "Decoupling for Reentry".
            wait 5.
            if (p:hasmodule("moduledecouple")) p:getmodule("moduledecouple"):doevent("decouple").
            set check to true.
            break.
        }
    }
    if (check = false)
    {
        print "Set Decouple to AG 9".
        lock inp to terminal:input:getchar().
        print "Hit 'l' to continue".
        wait until inp = "l".
        AG9 on. 
    }
    wait 5.

    lock steering to retrograde.
    wait 5.

    set warp to 4.
    wait until ship:altitude < 70000.
    set warp to 0.
    wait until alt:radar < 60000.
    print "Steering Off".
    unlock steering.
    wait until alt:radar < 4000.
    deploy_chutes().
}