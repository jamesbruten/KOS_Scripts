function ang_to_long
{
    local diff is burn_start_long - (ship:longitude + 360).
    print ship:longitude.
    if (diff < 0) set diff to diff + 360.
    print diff.
    return diff.
}

runpath("0:/boot/load_scripts.ks").
clearscreen.
global target_ap is 2863.33406 * 1000.
global target_pe is target_ap.
global burn_start_long is 0.

lock steering to prograde.

// deploy_antenna().
// wait 3.
// deploy_solar_panels().
// wait 20.

lock throttle to 0.
list engines in ship_engines.
for en in ship_engines
{
    if not en:ignition en:activate.
}


local ang is ang_to_long().
local wait_time is ship:orbit:period * ang / 360.
print "Wait Time: " + wait_time.
kuniverse:timewarp:warpto(time:seconds + 0.9*wait_time).
set ang to ang_to_long().
set wait_time to ship:orbit:period * ang / 360.
print "Wait Time: " + wait_time.
wait until ang_to_long < 0.5.

adjust_apsides("np").

wait 10.
adjust_apsides("a").
wait 10.
adjust_apsides("p").