function moon_midcourse_correction
{
    print "Doing Mid-Course Correction".
    local wait_time is "x".
    local wait_end is "x".
    local step_sizes is "x".
    if (ship:orbit:hasnextpatch = false or ship:orbit:nextpatch:body <> target)
    {
        set wait_time to eta:apoapsis/3.
        set wait_end to time:seconds + wait_time + 15.
        set step_sizes to list(100, 10, 1, 0.1, 0.01).
    }
    else
    {
        local time_body is ship:orbit:nextpatcheta.
        set wait_time to time_body/2 - 120.
        set wait_end to time:seconds + wait_time + 15.
        set step_sizes to list(10, 1, 0.1, 0.01).
    }
    do_warp(wait_time).
    wait until time:seconds > wait_end.

    local step_sizes is list(100, 10, 1, 0.1, 0.01).

    local min_start is time:seconds + 120.
    local params is list(0, 0).
    set params to converge_on_mnv(params, score_moon_midcourse_correction@, list(10000, next_inc), min_start, step_sizes).

    set mnv to node(min_start, 0, params[0], params[1]).
    print "Maneuver Burn:".
    print mnv.
    add_maneuver(mnv).
    execute_mnv().
    wait 5.
}

function transfer_orbit_moon
{
    local t_semi_major is (ship:orbit:semimajoraxis + target:orbit:semimajoraxis)/2.
    local transit_time is 2*constant:pi*sqrt(t_semi_major^3/body:mu).
    local transfer_angle is 180 - 180*transit_time/target:orbit:period.

    print "Transfer Angle: " + transfer_angle.

    until false
    {
        local time_to_mnv is time_to_pa(transfer_angle).
        local time_of_mnv is time:seconds + time_to_mnv.

        local vinit is velocityat(ship, time_of_mnv):orbit:mag.
        local burn_radius is ship:body:altitudeof(positionat(ship, time_of_mnv)) + ship:body:radius.
        local transfer_vel is sqrt(ship:body:mu * (2/burn_radius - 1/t_semi_major)).
        local dv is transfer_vel - vinit.

        local mnv is node(timestamp(time_of_mnv), 0, 0, dv).
        add_maneuver(mnv).
        
        if (mnv:orbit:hasnextpatch = true and mnv:orbit:nextpatch:body <> target)
        {
            remove_maneuver(mnv).
            print "Waiting 1 Orbit to avoid interaction".
            local wait_time is ship:orbit:period.
            local wait_end is time:seconds + wait_time + 5.
            do_warp(wait_time).
            wait until time:seconds > wait_end.
        }
        else
        {
            print "Transfer Maneuver:".
            print mnv.
            break.
        }
    }
    execute_mnv().
}

function transfer_orbit_interplanetary
{
    local t_semi_major is (ship:body:orbit:semimajoraxis + target:orbit:semimajoraxis)/2.
    local burn_radius is ship:body:orbit:semimajoraxis.
    local body_vel is body:velocity:orbit - sun:velocity:orbit.
    local transfer_vel is sqrt(ship:body:body:mu * (2/burn_radius - 1/t_semi_major)) - body_vel:mag.

    until false
    {
        local ejection_angle is calc_ejection_angle(transfer_vel).
        print ejection_angle.
        local ang is current_ejection_angle().
        print ang.
        local ang_left is ejection_angle - ang.
        if (ang_left < 0) set ang_left to 360 + ang_left.
        local time_to_mnv is ship:orbit:period * ang_left / 360.
        local time_of_mnv is time:seconds + time_to_mnv.

        local r1 is ship:body:altitudeof(positionat(ship, time_of_mnv)) + ship:body:radius.
        local r2 is body:soiradius.
        local wanted_v is sqrt((r1 * (r2*transfer_vel*transfer_vel - 2*body:mu) + 2*r2*body:mu) / (r1*r2)).
        local vinit is velocityat(ship, time_of_mnv):orbit:mag.
        local dv is wanted_v - vinit.

        local mnv is node(timestamp(time_of_mnv), 0, 0, dv).
        add_maneuver(mnv).

        if (mnv:orbit:nextpatch:body <> sun)
        {
            remove_maneuver(mnv).
            print "Waiting 1 Orbit to avoid interaction".
            local wait_time is ship:orbit:period.
            local wait_end is time_seconds + wait_time + 10.
            do_warp(wait_time).
            wait until time:seconds > wait_end.
        }
        else
        {
            print "Transfer Maneuver:".
            print mnv.
            break.
        }
    }

    execute_mnv().
}

function calc_ejection_angle
{
    // Returns the ejection angle for transfer burn to target

    parameter v_inf.  // velocity you need to have relative to the current body when leaving its SOI

    set v_esc to sqrt(2 * body:mu / ship:orbit:semimajoraxis).  // escape velocity from parking orbit.  
    set v to sqrt ( v_esc^2 + v_inf^2).                             // velocity of hyperbolic trajectory at periapsis  
    set r to ship:orbit:semimajoraxis.  
    set L to v * r.                                             // v-cross-r, without direction  
    set En to v^2/2 - body:mu / r.                              //specific orbital energy. Is negative unless you're on an escape trajectory  

    set e to sqrt(1 + (2*En*L^2)/(body:mu ^2)).                // eccentricity. Should be > 1.  
    set theta to arccos(1/e).  

    set theta to 180 - theta.
    
    if (target:orbit:semimajoraxis > body:orbit:semimajoraxis) set theta to 360 - theta.
    else set theta to 180 - theta.

    return theta.
}

function current_ejection_angle
{
    // returns the angle between orbiting body prograde and ship prograde
    // returns false if current body is Kerbol

    if (ship:body = sun) return false.

    local ship_vel is ship:velocity:orbit.
    local body_vel is body:velocity:orbit - sun:velocity:orbit.
    local ship_vel_sun is ship_vel - sun:velocity:orbit.
    local orb_vel1 is ship_vel_sun:mag - body_vel:mag.
    wait 0.1.
    set ship_vel to ship:velocity:orbit.
    set body_vel to body:velocity:orbit - sun:velocity:orbit.
    set ship_vel_sun to ship_vel - sun:velocity:orbit.
    set ang to vang(ship_vel, body_vel).
    local orb_vel2 is ship_vel_sun:mag - body_vel:mag.
    if (orb_vel2 > orb_vel1) set ang to 360 - ang.
    return ang - 90.
}

function capture_next_body
{
    lock steering to retrograde.
    print "Warping to Next Body".
    local old_body is ship:body.
    do_warp(ship:orbit:nextpatcheta).
    wait until old_body <> ship:body.

    wait 5.
    adjust_apsides("p", next_ap).
    wait 5.
    local diff1 is abs(ship:apoapsis - next_ap).
    local diff2 is abs(ship:periapsis - next_pe).
    if (diff1 < diff2) adjust_apsides("a", next_pe).
    else adjust_apsides("p", next_ap).
    wait 5.
}

function moon_transfer_functions
{
    // Need to set global next_ap, next_pe, next_inc and set target

    transfer_orbit_moon().
    wait 5.
    deploy_payload("payload").
    activate_engines().
    wait 5.
    moon_midcourse_correction().
    wait 5.
    capture_next_body().
}

function moon_transfer
{
    // Parking Orbit Params
    global target_ap_km is 120.
    global target_pe_km is target_ap_km.
    global target_inc is 0.
    global target_ap is target_ap_km*1000.
    global target_pe is target_pe_km*1000.

    // Target Body Orbit Params
    local tbody is Minmus.
    set target to tbody.
    global next_inc is 40.
    global next_ap_km is 50.
    global next_pe_km is next_ap_km.
    global next_ap is next_ap_km * 1000.
    global next_pe is next_pe_km * 1000.

    // do launch until apoapsis in parking orbit
    launch_to_ap(true).

    lights on.
    set steeringmanager:maxstoppingtime to 0.5.

    // circularise parking orbit
    adjust_apsides("a", ship:apoapsis).

    wait 5.
    deploy_solar_panels().
    deploy_antenna().
    deploy_dp_shield().


    transfer_orbit_moon().
    wait 5.

    deploy_payload("payload").
    activate_engines().
    wait 5.

    if (kuniverse:activevessel <> core:vessel)
    {
        kuniverse:forcesetactivevessel(core:vessel).
        unlock steering.
        set target to tbody.
        AG1 on.
        wait 5.
        lock steering to prograde.
        wait 5.
    }

    moon_midcourse_correction().
    wait 5.
    capture_next_body().
    print "In Moon Orbit".
}