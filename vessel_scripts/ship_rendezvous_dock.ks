if (target:body = ship:body)
{
    global target_ap is 0.75*target:apoapsis.
    global target_pe is target_ap.
    global target_inc is target:orbit:inclination.
    if (abs(ship:latitude) > target_inc) set target_inc to 1.01 * abs(ship:latitude).
    global target_ap_km is target_ap/1000.
    global target_pe_km is target_pe/1000.

    // wait for target orbit to be above ship
    wait_for_window(target, ship).

    retract_solar_panels().
    wait 5.

    // do launch until apoapsis in parking orbit
    if (ship:body = Kerbin) launch_to_ap(true).
    else if (ship:body:atm:height < 100) launch_to_vac(target_ap, target_inc).
    else
    {
        print "WARNING: Launching to Ap With Kerbin Profile".
        launch_to_ap(true).
    }

    lights on.

    // circularise parking orbit
    adjust_apsides("a", ship:apoapsis).

    wait 5.
    // deploy_payload("payload").
    // activate_engines().
    deploy_solar_panels().
    deploy_dp_shield().
    deploy_antenna().

    match_inclination().

    transfer_orbit().

    final_rendezvous().
    wait 5.

    dock_vessels().
}
else if (target:body:body = ship:body)
{
    global target_ap_km is 120.
    global target_pe_km is target_ap_km.
    global target_ap is target_ap_km * 1000.
    global target_pe is target_ap.
    global target_inc is 0.

    global next_inc is target:orbit:inclination.
    global next_ap is 0.75 * target:apoapsis.
    global next_pe is next_ap.
    local t1 is target.
    local tbody is target:body.
    set target to tbody.

    retract_solar_panels().

    // do launch until apoapsis in parking orbit
    if (ship:body = Kerbin) launch_to_ap(true).
    else if (ship:body:atm:height < 100) launch_to_vac().
    else
    {
        print "WARNING: Launching to Ap With Kerbin Profile".
        launch_to_ap(true).
    }

    lights on.

    // circularise parking orbit
    adjust_apsides("a", ship:apoapsis).

    wait 5.
    // deploy_payload("payload").
    // activate_engines().
    deploy_solar_panels().
    deploy_dp_shield().
    deploy_antenna().

    moon_transfer_functions().

    set target to t1.

    match_inclination().

    transfer_orbit().

    final_rendezvous().
    wait 5.

    dock_vessels().
}