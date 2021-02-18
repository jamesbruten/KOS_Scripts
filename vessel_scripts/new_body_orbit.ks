// Parking Orbit Params
global target_ap_km is 100.
global target_pe_km is target_ap.
global target_inc is 0.
global target_ap is target_ap_km*1000.
global target_pe is target_pe_km*1000.

// Target Body Orbit Params
global next_ap_km is 50.
global next_pe_km is next_ap.
global next_ap is next_ap_km * 1000.
global next_pe is next_pe_km * 1000.

// do launch until apoapsis in parking orbit
launch_to_ap(true).

lights on.
set steeringmanager:maxstoppingtime to 0.5.

// circularise parking orbit
adjust_apsides("a").

wait 5.
deploy_solar_panels().
wait 5.
deploy_antenna().
wait 5.
deploy_payload("payload").
lock throttle to 0.
list engines in ship_engines.
for en in ship_engines
{
    if not en:ignition en:activate.
}
wait 5.