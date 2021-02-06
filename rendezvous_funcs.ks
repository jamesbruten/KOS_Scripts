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

    local i1 is ship:orbit:inclination.
    local i2 is target:orbit:inclination.
    local omega1 is ship:orbit:lan.
    local omega2 is target:orbit:lan.

    local a1 is sin(i1)*cos(omega1).
    local a2 is sin(i1)*sin(omega1).
    local a3 is cos(i1).

    local b1 is sin(i2)*cos(omega2).
    local b2 is sin(i2)*sin(omega2).
    local b3 is cos(i2).

    local c1 is a2*b3 - a3*b2.
    local c2 is a3*b1 - a1*b3.
    local c3 is a1*b2 - a2*b1.

    // latitude of AN
    local latAN is arctan(c3 / sqrt(c1*c1 + c2*c2)).
    // angle change needed for same inclination
    local theta is arccos(a1*b1 + a2*b2 + a3*b3).

    // central angle is angle between LAN and ship
    // taAN is true anomaly of ascending node
    local central_angle is arcsin(sin(latAN)/sin(i1)).
    local taAN is central_angle - ship:orbit:argumentofperiapsis.
    local taDN is 0.
    if (taAN < 180) set taDN to taAN + 180.
    else set taDN to taAN - 180.
    local taS is ship:orbit:trueanomaly.
    local e is ship:orbit:eccentricity.

    // E is eccentricity anomaly, M is mean anomaly
    local E0 is arccos((e+cos(taS))/(1+e*cos(taS))).
    local E1 is arccos((e+cos(taAN))/(1+e*cos(taAN))).
    local E2 is arccos((e+cos(taDN))/(1+e*cos(taDN))).
    local M0 is E0*constant:pi/180 - e*sin(E0).
    local M1 is E1*constant:pi/180 - e*sin(E1).
    local M2 is E2*constant:pi/180 - e*sin(E2).

    // mean motion
    local n is sqrt(body:mu / ship:orbit:semimajoraxis^3).

    local time_AN is (M1 - M0)/n.
    if (taS > taAN) set time_AN to ship:orbit:period - time_AN.
    local time_DN is (M2 - M0)/n.
    if (taS > taDN) set time_DN to ship:orbit:period - time_DN.

    // Now have the time to the ascending node, calculate delta v required

    // radius at AN/DN
    local r_AN is ship:orbit:semimajoraxis * (1 - e*cos(taAN)).
    local r_DN is ship:orbit:semimajoraxis * (1 - e*cos(taDN)).

    // velocity at AN/DN
    local v_AN is sqrt(body:mu * (2/r_AN - 1/ship:orbit:semimajoraxis)).
    local v_DN is sqrt(body:mu * (2/r_DN - 1/ship:orbit:semimajoraxis)).

    // delta v required at AN/DN
    local dv_AN is 2*v_AN*sin(theta/2).
    local dv_DN is 2*v_DN*sin(theta/2).

    local time_to_burn is 0.
    local burn_dv is 0.
    if (dv_AN < dv_DN)
    {
        set time_to_burn to time_AN.
        set burn_dv to dv_AN.
    }
    else
    {
        set time_to_burn to time_DN.
        set burn_dv to dv_DN.
    }

    local mnv is node(timespan(time_to_burn), 0, burn_dv, 0).
    print "Maneuver: ".
    print mnv.
    add_maneuver(mnv).
    execute_mnv().
}

function transfer_orbit
{
    local t_semi_major is (ship:orbit:semimajoraxis + target:orbit:semimajoraxis)/2.
    local transit_time is 2*constant:pi*sqrt(t_semi_major^3/body:mu).
    local phase_angle is 180 - 180*transit_time/target:orbit:period.

    lock current_pa to get_phase_angle().
    until (current_pa < )

    vinit = sqrt(body:mu*(2/))
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