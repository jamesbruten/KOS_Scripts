function wait_for_launch
{
    // Calculate time until target obit crosses launch pad

    local ecliptic_normal is vcrs(target:velocity:orbit, target:body:position-target:position):normalized.
    local planet_normal is heading(0, ship:latitude):vector.
    local body_inc is vang(planet_normal, ecliptic_normal).
    local beta is arccos(max(-1, min(1, cos(body_inc)*sin(ship:latitude)/sin(body_inc)))).
    local int_dir is vcrs(planet_normal, ecliptic_normal):normalized.
    local int_pos is -vxcl(planet_normal, ecliptic_normal):normalized.
    local lt_dir is cos(ship:latitude)*(int_dir*sin(beta) +int_pos*cos(beta)) + sin(ship:latitude)*planet_normal.
    local time_to_launch is body:rotationperiod * vang(lt_dir, ship:position-body:position) / 360.
    if (vcrs(lt_dir, ship:position - body:position)*planet_normal < 0) set time_to_launch to body:rotationperiod - time_to_launch.

    if (time_to_launch > body:rotationperiod/2)
    {
        set time_to_launch to time_to_launch - body:rotationperiod/2. 
        set target_inc to -1 * target_inc.
    }

    local launch_time is time:seconds + time_to_launch.
    local lh is round(time_to_launch/3600 - 0.5).
    local lm is round((time_to_launch-lh*3600)/60 - 0.5)-2.

    print "Launch In: " + time_to_launch.
    print "Launch In: " + lh + " hours + " + lm + " minutes".
    wait until time:seconds > launch_time - 40.
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

    local current_pa is get_phase_angle().
    print "Transfer Angle: " + transfer_angle.
    print "Phase Angle   : " + current_pa.
    until (abs(transfer_angle - current_pa) < 0.25)
    {
        set current_pa to get_phase_angle().
        clearscreen.
        print "Transfer Angle: " + transfer_angle.
        print "Phase Angle   : " + current_pa.
        wait 0.1.
    }

    local rad is ship:altitude + body:radius.
    local vinit is sqrt(body:mu*(2/rad - 1/ship:orbit:semimajoraxis)).
    local vfinal is sqrt(body:mu*(2/rad - 1/t_semi_major)).
    local dv is vfinal - vinit.
    local burn_time is calc_burn_time(dv).

    local mnv is node(timespan(burn_time/2 + 20), 0, 0, dv+0.1).
    print "Maneuver: ".
    print mnv.
    add_maneuver(mnv).
    execute_mnv().
}

function get_phase_angle
{
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
    if (sign < 0) return -phase.
    else return phase.
}

function final_rendezvous
{
    // Get Ship to within 250m and kill velocity
    print "Performing Final Rendezvous".

    local wanted_min is 200.
    
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

        print "Burn in: " + time_until_burn.
        print "Burn DV: " + vel_diff:mag.
        print "Burn Time: " + killdv_time.
        print "Min Sep: " + min_dist.
        print "    ".
        local mnv is node(min_time, vel_diff:mag, 0, 0).
        add_maneuver(mnv).

        lock steering to lookdirup(-1*vel_diff, north:vector).
        wait until time:seconds >= min_time - killdv_time / 2.
        remove_maneuver(mnv).
        lock throttle to 1.
        wait until time:seconds >= min_time + killdv_time / 2.
        lock throttle to 0.
        set dist to ship:position - target:position.
        if (dist:mag < 250) break.

        list engines in ship_engines.
        for en in ship_engines
        {
            if (en:ignition = true) set en:thrustlimit to 10.
        }

        lock steering to lookdirup(target:position, north:vector).
        wait 10.
        lock throttle to 1.
        local app_vel is 5.
        if (dist < 500) set app_vel to 2.5.
        until false
        {
            set current_vel to ship:velocity:orbit - target:velocity:orbit.
            if (current_vel:mag >= app_vel) break.
        }
        lock throttle to 0.
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
        set end_time to time:seconds + 300.
    }

    local t is start_time.
    local min_dist is 2^64.
    local min_time is 0.
    until (t > end_time)
    {
        local dist is positionat(ship, t) - positionat(target, t).
        set dist to dist:mag.
        if (dist < wanted_min) break.
        if (dist < min_dist and dist >= wanted_min)
        {
            set min_dist to dist.
            set min_time to t.
        }
        set t to t + 1.
    }
    return list(min_time, min_dist).
}