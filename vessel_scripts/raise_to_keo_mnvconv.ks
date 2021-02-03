runpath("0:/boot/load_scripts.ks").
clearscreen.
global wanted_ap is 2863.33406 * 1000.
global wanted_arg_ap is 90.

local min_start is time:seconds + 900.

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

local params is list(min_start, 0).
set params to converge_on_mnv(params, score_aph_aparg@, list(wanted_ap, wanted_arg_ap), min_start).

set mnv to node(params[0], 0, 0, params[1]).
print "Maneuver Burn:".
print mnv.
add_maneuver(mnv).

local nd is nextnode.
print nd:orbit:apoapsis.
print nd:orbit:argumentofperiapsis.
print nd:orbit:longitudeofascendingnode.

execute_mnv().

wait 10.
global target_pe is ship:apoapsis.
adjust_apsides("a").