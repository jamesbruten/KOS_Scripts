function ang_to_long
{
    local long is ship:longitude.
    if (long < 0) set long to 180 + abs(180 + ship:longitude).
    local diff is burn_start_long - long.
    if (diff < 0) set diff to diff + 360.
    return diff.
}

runpath("0:/boot/load_scripts.ks").
clearscreen.
global target_ap is 2863.33406 * 1000.
global target_pe is target_ap.
global burn_start_long is 270.

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


local ang is ang_to_long().
local wait_time is ship:orbit:period * ang / 360.
print "Wait Time: " + wait_time.
wait until ang_to_long < 6.

adjust_apsides("np").

wait 10.
adjust_apsides("a").