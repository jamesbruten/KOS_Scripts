@lazyglobal off.
core:part:getmodule("KOSProcessor"):doevent("Open Terminal").
runpath("0:/boot/load_scripts.ks").

// if using boot_deorbit set main_cpu tag
// Call final decoupler 'payload_deploy'     --- IMPORTANT ---

declare global target_ap_km to 130.
declare global target_pe_km to 130.
declare global target_inc to 0.

if (target_ap_km < target_pe_km)
{
    local temp is target_ap_km.
    set target_ap_km to target_pe_km.
    set target_pe_km to temp.
}

declare global target_ap to target_ap_km * 1000.
declare global target_pe to target_pe_km * 1000.
set steeringmanager:maxstoppingtime to 0.1.

launch_to_ap().

adjust_apsides("a").

wait 10.
deploy_payload("payload1").
wait 10.
deploy_payload("payload2").
if (ship:apoapsis > 750000) wait until eta:apoapsis < 60.
lock steering to retrograde.
wait 60.
lock throttle to 0.3.
wait 10.
lock throttle to 1.
wait until ship:periapsis < 15000.
lock throttle to 0.
unlock steering.
// wait 10.
// deploy_antenna().
// wait 3.
// deploy_solar_panels().
// wait 20.

wait until false.