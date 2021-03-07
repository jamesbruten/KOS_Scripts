@lazyglobal off.
runpath("0:/boot/load_scripts.ks").

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
global next_ap_km is 50.
global next_pe_km is next_ap_km.
global next_ap is next_ap_km * 1000.
global next_pe is next_pe_km * 1000.

// // do launch until apoapsis in parking orbit
// launch_to_ap(true).

// lights on.
// set steeringmanager:maxstoppingtime to 0.5.

// // circularise parking orbit
// adjust_apsides("a", ship:apoapsis).

// wait 5.
// deploy_solar_panels().
// wait 5.
// deploy_antenna().
// wait 5.

// transfer_orbit_moon().
// wait 5.

deploy_dp_shield().
wait 5.
AG1 on.
if (kuniverse:activevessel <> core:vessel)
{
    kuniverse:forcesetactivevessel(core:vessel).
    set target to tbody.
}
kss_tug_move(1, 1).
wait 5.
deploy_payload("payload2").
wait 10.
lock steering to prograde.
wait 5.
list engines in ship_engines.
for en in ship_engines
{
    if (en:tag = "transfer_en") en:activate.
}

moon_midcourse_correction().

lock steering to retrograde.
print "Warping to Next Body".
local old_body is ship:body.
do_warp(ship:orbit:nextpatcheta).
wait until old_body <> ship:body.

wait 5.
adjust_apsides("p", next_ap).
wait 5.
local diff1 is abs(ship:apoapsis - next_ap).
local diff2 is abs(ship:periapsis - next_pe).
if (diff1 < diff2) adjust_apsides("a", next_pe).
else adjust_apsides("p", next_ap).
wait 10.

print "In Moon Orbit".