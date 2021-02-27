function wait_for_landing
{
    //  waits for srfpos to be underneat orbitable, at launch give target and ship
    parameter landing_lat, landing_long, orbitable.

    // The angle rotated by body during one orbit
    local rot_ang is 360 * orbitable:orbit:period / orbitable:body:rotationperiod.

    // srfpos is normal vector to a flat body at the given lat/long
    local orbit_normal is vcrs(orbitable:velocity:orbit, orbitable:body:position-orbitable:position):normalized.
    local srfpos is ship:body:position - latlng(landing_lat, landing_long):position.
    local body_normal is srfpos:normalized.
    local ang is vang(orbit_normal, body_normal).
    local diff is abs(90 - ang).
    if (diff < 10) do_warp(orbitable:body:rotationperiod/4).

    local warp_level is 0.
    until false
    {
        local orbit_normal is vcrs(orbitable:velocity:orbit, orbitable:body:position-orbitable:position):normalized.
        local srfpos is ship:body:position - latlng(landing_lat, landing_long):position.
        local body_normal is srfpos:normalized.
        local ang is vang(orbit_normal, body_normal).
        local diff is abs(90 - ang).
        if (diff < 10)
        {
            set warp to 0.
            wait until ship:unpacked.
            break.
        }
        else if (diff < 11)
        {
            set warp to 2.
            set warp_level to 2.
        }
        else if (diff < 20)
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
        print "Warping to 10 Deg".
        print round(ang, 2) + "      " + round(diff, 2) + "      " + warp_level.
    }
    wait 3.
}

function lower_periapsis
{
    // waits until opposite landing site then lowers periapsis to 9000m
    parameter landing_lng.

    if (ship:periapsis < 10000)
    {
        print "No Periapsis Lowering Required".
        return.
    }

    local burn_lng is landing_lng - 180.
    if (burn_lng < -180) set burn_lng to 360 + burn_lng.
    set burn_lng to burn_lng + 180.

    local lng1 is ship:geoposition:lng + 180.
    local ang_diff is 0.//ANGLE DIFFERENCE CALC
    
    print "Warping to Opposite Side".

    local wait_time is ship:orbit:period * ang_diff / 360.
    local wait_end is time:seconds + wait_time.
    do_warp(wait_time - 15).
    wait until time:seconds > wait_end.

    print "Pointing Retrograde".
    lock steering to retrograde.
    wait 15.
    print "Retrograde Burn".
    lock throttle to 0.25.
    wait until ship:periapsis < 9000.
    lock throttle to 0.
    print "Shutdown".

    return wait_end + ship:orbit:period / 2.
}

function correct_landing_inc
{
    parameter landing_lat, landing_lng, eta_landing.

    local wait_time is (eta_landing - time:seconds) / 2.
    local wait_end is wait_time + time:seconds.
    do_warp(wait_time - 5).
    wait until time:seconds > wait_end.

    local vel_vect is vxcl(up:vector, ship:velocity:orbit).
    local target_vect is vxcl(up:vector, latlng(landing_lat, landing_lng):position).

    local ang is vang(vel_vect, target_vect).

}