global target_ap is 0.75*target:apoapsis.
global target_pe is target_ap.
global target_inc is target:orbit:inclination.
global target_ap_km is target_ap/1000.
global target_pe_km is target_pe/1000.

// // wait for target orbit to be above ship
// wait_for_launch().

// // do launch until apoapsis in parking orbit
// launch_to_ap(true).

// deploy payload vehicle
deploy_payload("payload1").

list engines in ship_engines.
for en in ship_engines
{
    en:activate().
}

// circularise parking orbit
adjust_apsides("a").

lock throttle to 0.
list engines in ship_engines.
for en in ship_engines
{
    if not en:ignition en:activate.
}

wait 5.
deploy_solar_panels().
wait 5.
deploy_dp_shield().
wait 5.

set steeringmanager:maxstoppingtime to 0.5.

match_inclination().

transfer_orbit().

final_rendezvous().

dock_vessels().