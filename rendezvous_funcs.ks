function wait_for_window
{
    //  waits for srfpos to be underneath orbitable, at launch give target and ship
    parameter orbitable, srfpos.

    if (target:orbit:inclination < 5)
    {
        print "Target Orbit Equatorial - No Wait Necessary".
        wait 2.
        return.
    }

    local warp_level is 0.
    until false
    {
        local orbit_normal is vcrs(orbitable:velocity:orbit, orbitable:body:position-orbitable:position):normalized.
        local body_normal is srfpos:body:position - srfpos:position.
        local ang is vang(orbit_normal, body_normal).
        local diff is abs(90 - ang).

        if (ship:latitude < 45) set warp_level to warp_at_level(0.5, 1, 15, diff).
        else set warp_level to warp_at_level(0.5, 0.8, 8, diff).

        if (warp_level = 0) break.
        
        clearscreen.
        print "Warping to Window".
        print round(ang, 2) + "      " + round(diff, 2) + "      " + warp_level.
    }
    wait 3.
    
    local orbit_normal is vcrs(orbitable:velocity:orbit, orbitable:body:position-orbitable:position):normalized.
    local body_normal is srfpos:body:position - srfpos:position.
    local cross is vcrs(orbit_normal, body_normal).
    local yval is cross:y.
    if (yval > 0) set target_inc to -1 * target_inc.
}

function match_inclination
{
    print "Matching Inclination".
    
    // Orbit Normal Vectors - angular momenta
    local h_ship is vcrs(ship:position - ship:body:position, ship:velocity:orbit).
    local h_targ is vcrs(target:position - target:body:position, target:velocity:orbit).

    local DNvector is vcrs(h_targ, h_ship).
    local taDN is "x".
    local taAN is "x".
    local taS is ship:orbit:trueanomaly.

    // TA of DN
    if (vdot(DNvector + body:position, ship:velocity:orbit) > 0)
    {
        set taDN to ship:orbit:trueanomaly + vang(DNvector, ship:position - ship:body:position).
    }
    else
    {
        set taDN to ship:orbit:trueanomaly - vang(DNvector, ship:position - ship:body:position).
    }

    until (taDN >= 0)
    {
        set taDN to taDN + 360.
    }
    if (taDN >= 360) set taDN to taDN - 360.


    // TA of AN
    set taAN to taDN + 180.
    until (taAN < 360)
    {
        set taAN to taAN - 360.
    }

    local e is ship:orbit:eccentricity.

    // Eccentric and Mean Anomalies of ship, AN, DN
    local Es is eccentricity_anom(e, taS).
    local Ean is eccentricity_anom(e, taAN).
    local Edn is eccentricity_anom(e, taDN).
    local Ms is mean_anom(e, Es).
    local Man is mean_anom(e, Ean).
    local Mdn is mean_anom(e, Edn).

    local n is sqrt(ship:body:mu / ship:orbit:semimajoraxis^3).

    local time_an is (Man - Ms) / n.
    if (time_an < 0) set time_an to time_an + ship:orbit:period.
    if (time_an > ship:orbit:period) set time_an to time_an - ship:orbit:period.
    local time_of_an is time:seconds + time_an.
    
    local time_dn is (Mdn - Ms) / n.
    if (time_dn < 0) set time_dn to time_dn + ship:orbit:period.
    if (time_dn > ship:orbit:period) set time_dn to time_dn - ship:orbit:period.
    local time_of_dn is time:seconds + time_dn.

    local angle_change is vang(h_targ, h_ship).

    local vel_an is velocityat(ship, time_of_an):orbit:mag.
    local vel_dn is velocityat(ship, time_of_dn):orbit:mag.

    local dv_an is 2 * vel_an * sin(angle_change / 2).
    local dv_dn is 2 * vel_dn * sin(angle_change / 2).

    local time_of_burn is "x".
    local burn_dv is "x".
    if (dv_an < dv_dn)
    {
        set time_of_burn to time_of_an.
        set burn_dv to -1 * dv_an.
    }
    else
    {
        set time_of_burn to time_of_dn.
        set burn_dv to dv_dn.
    }

    local mnv is node(time_of_burn, 0, burn_dv, 0).
    print "Maneuver: ".
    print mnv.
    add_maneuver(mnv).
    execute_mnv().
    wait 2.
}

function eccentricity_anom
{
    parameter e, ta.        // eccentricity and true anomaly
    local tanE2 is sqrt((1-e)/(1+e)) * tan(ta/2).
    return 2 * arctan(tanE2).
}

function mean_anom
{
    parameter e, ea.       // eccentricity and eccentricity anomaly
    return (ea - e*sin(ea))*constant:pi/180.
}

function transfer_orbit
{
    local t_semi_major is (ship:orbit:semimajoraxis + target:orbit:semimajoraxis)/2.
    local transit_time is 2*constant:pi*sqrt(t_semi_major^3/body:mu).
    local transfer_angle is 180 - 180*transit_time/target:orbit:period.

    local warp_level is 0.
    until false
    {
        local current_pa is get_phase_angle().
        local diff is abs(transfer_angle - current_pa).

        set warp_level to warp_at_level(0.28, 0.55, 3, diff).

        if (warp_level = 0) break.

        clearscreen.
        print "Warping to Transfer Angle".
        print "TA: " + round(transfer_angle, 2) + "    PA: " + round(current_pa, 2) + "    Diff: " + round(diff, 2) + "   WL: " + warp_level.
    }

    local vinit is ship:velocity:orbit:mag.
    local burn_radius is ship:altitude + ship:body:radius.
    local transfer_vel is sqrt(ship:body:mu * (2/burn_radius - 1/t_semi_major)).
    local dv is transfer_vel - vinit.

    local mnv is node(timespan(30), 0, 0, dv).
    add_maneuver(mnv).
    execute_mnv().
}

function get_phase_angle
{
    // returns current phase angle to target in range 0-360

    local common_ancestor is 0.
    local my_ancestors is list().
    local your_ancestors is list().

    my_ancestors:add(ship:body).
    until not(my_ancestors[my_ancestors:length-1]:hasBody)
    {
        my_ancestors:add(my_ancestors[my_ancestors:length-1]:body).
    }

    your_ancestors:add(target:body).
    until not(your_ancestors[your_ancestors:length-1]:hasBody)
    {
        your_ancestors:add(your_ancestors[your_ancestors:length-1]:body).
    }

    for my_ancestor in my_ancestors
    {
        local found is false.
        for your_ancestor in your_ancestors
        {
            if my_ancestor = your_ancestor
            {
                set common_ancestor to my_ancestor.
                set found to true.
                break.
            }
        }
        if (found = true) break.
    }

    local vel is ship:velocity:orbit.
    local my_ancestor is my_ancestors[0].
    until my_ancestor = common_ancestor
    {
        set vel to vel + my_ancestor:velocity:orbit.
        set my_ancestor to my_ancestor:body.
    }

    local binormal is vcrs(-common_ancestor:position:normalized, vel:normalized):normalized.
    local phase is vang(-common_ancestor:position:normalized,
                    vxcl(binormal, target:position - common_ancestor:position):normalized).
    local signVector is vcrs(-common_ancestor:position:normalized,
                        (target:position - common_ancestor:position):normalized).

    local sign is vdot(binormal, signVector).
    if (sign < 0) return 360 - phase.
    else return phase.
}

function final_rendezvous
{
    // Get Ship to within 400m and kill velocity
    print "Performing Final Rendezvous to within 400m".

    local wanted_min is 350.

    pid_throttle_accel().
    
    local dist is ship:position - target:position.
    local current_vel is ship:velocity:orbit - target:velocity:orbit.
    until false
    {
        set dist to ship:position - target:position.
        if (dist:mag < 10000) local rlist is closest_approach(wanted_min, 0).
        else local rlist is closest_approach(wanted_min, eta:apoapsis).
        local min_time is rlist[0].
        local min_dist is rlist[1].
        local time_until_burn is min_time - time:seconds.

        // Required burn dv and burn time to kill velocity relative to target
        local vel_diff is velocityat(ship, min_time):orbit - velocityat(target, min_time):orbit.
        local killdv_time is calc_burn_time(vel_diff:mag).

        print "Burn in: " + round(time_until_burn, 2).
        print "Burn DV: " + round(vel_diff:mag, 2).
        print "Burn Time: " + round(killdv_time, 2).
        print "Min Sep: " + round(min_dist, 2).
        print "    ".
        local mnv is node(min_time, vel_diff:mag, 0, 0).
        add_maneuver(mnv).

        lock steering to lookdirup(-1*vel_diff, north:vector).
        set pid_accel:setpoint to vel_diff / 4.
        when (vel_diff:mag < 1.5) then set pid_accel:setpoint to 1.

        do_warp(mnv:eta-60-killdv_time/2).
        local max_time is min_time + 1.5*killdv_time.
        wait until time:seconds >= min_time - killdv_time / 2.
        remove_maneuver(mnv).
        
        until false
        {
            set accel to ship:sensors:acc - ship:sensors:grav.
            set thrott_pid to max(0, min(1, thrott_pid + pid_accel:update(time:seconds, accel))).
            set vel_diff to ship:velocity:orbit - target:velocity:orbit.
            lock steering to lookdirup(-1*vel_diff, north:vector).
            if (vel_diff:mag < 0.2) break.
            if (time:seconds > max_time) break.
        }
        set thrott_pid to 0.
        
        set dist to ship:position - target:position.
        if (dist:mag < 500) break.

        local app_vel is 5.
        if (dist:mag < 900) set app_vel to 3.
        if (dist:mag > 1500) set app_vel to 8.
        set pid_accel:setpoint to app_vel / 4.             // set acceleration to reach app_vel in 4 secs

        lock np to lookdirup(target:position, ship:facing:topvector).
        lock steering to np.    
        wait until abs(np:pitch - facing:pitch) < 1 and abs(np:yaw - facing:yaw) < 1.

        lock throttle to 1.
        until false
        {
            set accel to ship:sensors:acc - ship:sensors:grav.
            set thrott_pid to max(0, min(1, thrott_pid + pid_accel:update(time:seconds, accel))).
            set current_vel to ship:velocity:orbit - target:velocity:orbit.
            if (current_vel:mag >= app_vel) break.
        }
        set thrott_pid to 0.
    }
    print "Rendezvous Complete".
}

function closest_approach
{
    // Function that will calculate closest approach distance and time
    // If closest approach less than wanted distance will get time to wanted distance
    parameter wanted_min, search_param.

    // start and end times for searching for closest approach
    local start_time is 0.
    local end_time is 0.
    if (search_param > 0)
    {
        set start_time to time:seconds + 0.5 * eta:apoapsis.
        set end_time to time:seconds + 1.5 * eta:apoapsis.
    }
    else
    {
        set start_time to time:seconds + 2.
        set end_time to min(1.2*(ship:position-target:position):mag, 0.5*ship:orbit:period).
        set end_time to end_time + time:seconds.
    }

    local t is start_time.
    local min_dist is 2^64.
    local min_time is 0.
    until false
    {
        local dist is positionat(ship, t) - positionat(target, t).
        set dist to dist:mag.
        if (dist < wanted_min) break.
        if (dist < min_dist and dist >= wanted_min)
        {
            set min_dist to dist.
            set min_time to t.
        }
        // if (dist > min_dist + 1) break.
        set t to t + 1.
        if (t > end_time) break.
    }
    return list(min_time, min_dist).
}