function moon_transfer
{
    // Parking Orbit Params
    global target_ap_km is 120.
    global target_pe_km is target_ap_km.
    global target_inc is 0.
    global target_ap is target_ap_km*1000.
    global target_pe is target_pe_km*1000.

    // Target Body Orbit Params
    local tbody is Mun.
    set target to tbody.
    global next_inc is 0.
    global next_ap_km is 400.
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
    if (kuniverse:activevessel <> core:vessel)
    {
        kuniverse:forcesetactivevessel(core:vessel).
        unlock steering.
        set target to tbody.
        AG1 on.
    }
    wait 5.
    lock steering to prograde.
    wait 5.

    activate_engines().
    wait 2.
    moon_midcourse_correction().
    wait 5.
    capture_next_body().
    print "In Moon Orbit".
}

