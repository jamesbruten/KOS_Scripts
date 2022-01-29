@lazyglobal off.
runpath("0:/boot/load_scripts.ks").

declare global target_ap_km to 170.
declare global target_pe_km to 170.
declare global target_inc to 0.

if (target_ap_km < target_pe_km)
{
    local temp is target_ap_km.
    set target_ap_km to target_pe_km.
    set target_pe_km to temp.
}

declare global target_ap to target_ap_km * 1000.
declare global target_pe to target_pe_km * 1000.

launch_to_ap(false).

adjust_apsides("a", ship:apoapsis).

// wait 10.
// deploy_payload("payload1").
// wait 10.
// deploy_payload("payload2").
// wait 10.
// deploy_payload("payload3").

// if (ship:apoapsis > 750000) wait until eta:apoapsis < 60.
// lock steering to retrograde.
// wait 60.
// lock throttle to 0.3.
// wait 10.
// lock throttle to 1.
// wait until ship:periapsis < 0.
// lock throttle to 0.
// unlock steering.

// wait until false.