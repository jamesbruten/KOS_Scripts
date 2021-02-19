// Parking Orbit Params
global target_ap_km is 80.
global target_pe_km is target_ap_km.
global target_inc is 0.
global target_ap is target_ap_km*1000.
global target_pe is target_pe_km*1000.

// Target Body Orbit Params
global next_ap_km is 400.
global next_pe_km is next_ap_km.
global next_ap is next_ap_km * 1000.
global next_pe is next_pe_km * 1000.

// do launch until apoapsis in parking orbit
launch_to_ap(true).

lights on.
set steeringmanager:maxstoppingtime to 0.5.

// circularise parking orbit
adjust_apsides("a", ship:apoapsis).

wait 5.
deploy_payload("payload").
lock throttle to 0.
list engines in ship_engines.
for en in ship_engines
{
    if not en:ignition en:activate.
}
wait 5.
deploy_solar_panels().
wait 5.
deploy_antenna().
wait 5.

transfer_orbit().
wait 5.

print "Doing Mid-Course Correction".
if (ship:orbit:hasnextpatch = false)
{
    print "No next orbit patch!".
    until false wait 0.01.
}
local time_body is ship:orbit:nextpatcheta.
local wait_time is time_body/2 - 120.
local wait_end is time:seconds + wait_time + 15.
do_warp(wait_time).
wait until time:seconds > wait_end.

local min_start is time:seconds + 120.
local params is list(0, 0).
set params to converge_on_mnv(params, score_mun_transfer@, list(9000, 90), min_start, list(10, 1, 0.1, 0.01)).

set mnv to node(min_start, 0, params[0], params[1]).
print "Maneuver Burn:".
print mnv.
add_maneuver(mnv).
execute_mnv().
wait 5.

print "Warping to Next Body".
local old_body is ship:body.
do_warp(ship:orbit:nextpatcheta).
wait until old_body <> ship:body.

wait 5.
adjust_apsides("p", next_ap).
wait 5.
adjust_apsides("a", next_pe).