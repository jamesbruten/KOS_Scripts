function wait_for_landing
{
    //  waits for srfpos to be underneat orbitable, at launch give target and ship
    parameter landing_lat, landing_long, orbitable.

    local srfpos is ship:body:position - latlng(landing_lat, landing_long):position.
    set srfpos to srfpos:normalized.

    local warp_level is 0.
    until false
    {
        local orbit_normal is vcrs(orbitable:velocity:orbit, orbitable:body:position-orbitable:position):normalized.
        local body_normal is srfpos.
        local ang is vang(orbit_normal, body_normal).
        local diff is abs(90 - ang).
        if (diff < 0.5)
        {
            set warp to 0.
            wait until ship:unpacked.
            break.
        }
        else if (diff < 2)
        {
            set warp to 2.
            set warp_level to 2.
        }
        else if (diff < 15)
        {
            set warp to 4.
            set warp_level to 4.
        }
        else
        {
            set warp to 5.
            set warp_level to 5.
        }
        clearscreen.
        print "Warping to Window".
        print round(ang, 2) + "      " + round(diff, 2) + "      " + warp_level.
    }
    wait 3.
}

wait_for_landing(15.9, -95.4, target).