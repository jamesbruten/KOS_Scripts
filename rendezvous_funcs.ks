function wait_for_launch
{
    // Calculate time until target obit crosses launch pad

    // Normal to plane of target around body
    local ecliptic_normal is vcrs(target:velocity:orbit, target:body:position-target:position):normalized.

    // Normal to ship at launch pad
    local planet_normal is heading(0, ship:latitude).
    local body_inc is vang(planet_normal, ecliptic_normal).
    local beta is arccos(max(-1, min(1, cos(body_inc)*sin(ship:latitude)/sin(body_inc)))).
    local int_dit is vcrs(planet_normal, ecliptic_normal):normalized.
    local int_pos is -vxcl(planet_normal, ecliptic_normal):normalized.
    local lt_dir is cos(ship:latitude)*(int_dir*sin(beta) +int_pos*cos(beta)) + sin(ship:latitude)*planet_normal.
    local launch_time is body:rotationperiod * vang(lt_dir, ship:position-body:position) / 360.
    if (vcrs(lt_dir, ship:position - body:position)*planet_normal < 0) set launch_time to body:rotationperiod - launch_time.

    add_maneuver(node(timespan(launch_time-120),0,0,0)).
    wait until time:seconds + launch_time - 120.
    remove_maneuver(nextnode).
}