function wait_for_landing
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

    if (time_to_launch > body:rotationperiod/2 and abs(ship:latitude)<2)
    {
        set time_to_launch to time_to_launch - body:rotationperiod/2. 
        set target_inc to -1 * target_inc.
    }

    local launch_time is time:seconds + time_to_launch.
    local lh is round(time_to_launch/3600 - 0.5).
    local lm is round((time_to_launch-lh*3600)/60 - 0.5)-2.

    print "Launch In: " + time_to_launch.
    print "Launch In: " + lh + " hours + " + lm + " minutes".
    print "Warping".
    wait 2.
    local warp_delta is time_to_launch - 60.
    do_warp(warp_delta).
    wait until time:seconds > launch_time - 40.
}