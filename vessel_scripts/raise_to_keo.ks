function ang_to_long
{
    local diff is burn_start_long - ship:longitude + 180.
    if (diff < 0) set diff to diff + 360.
    return diff.
}

runpath("0:/boot/load_scripts.ks").
clearscreen.
global target_ap is 2863.33406 * 1000.
global target_pe is target_ap.
global burn_start_long is 0.

lock steering to prograde.

deploy_antenna().
wait 3.
deploy_solar_panels().
wait 20.

lock throttle to 0.
list engines in ship_engines.
for en in ship_engines
{
    if not en:ignition en:activate.
}

local ang is 0.
local wait_time is 0.
lock ang to ang_to_long().
lock wait_time to ship:orbit:period * diff / 360.
print "Wait Time: " + wait_time.
kuniverse:timewarp(0.9*wait_time).
print "Wait Time: " + wait_time.
wait until ang < 0.5.

adjust_apsides("np").

wait 10.
adjust_apsides("a").
wait 10.
adjust_apsides("p").