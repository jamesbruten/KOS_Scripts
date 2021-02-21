// Parking Orbit Params
global target_ap_km is 80.
global target_pe_km is target_ap_km.
global target_inc is 0.
global target_ap is target_ap_km*1000.
global target_pe is target_pe_km*1000.

// Target Body Orbit Params
set target to Duna.
local target_body is target.
global next_ap is 225000.       // gilly:periapsis - 1.1*gilly:soiradius.
global next_pe is next_ap.
global next_ap_km is next_ap / 100.
global next_pe_km is next_pe / 100.
local next_inc is 90.

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

// transfer_orbit_interplanetary().
// wait 5.

// deploy_payload("payload").
// lock throttle to 0.
// wait 1.
// list engines in ship_engines.
// for en in ship_engines
// {
//     if not en:ignition en:activate.
// }
// wait 5.

// print "Warping Until Outside Kerbin SOI".
// local time_kerbol is ship:orbit:nextpatcheta.
// local wait_time is time_kerbol + 300.
// local wait_end is time:seconds + wait_time + 15.
// do_warp(wait_time).
// wait until time:seconds > wait_end.

local mnum is 1.
until mnum > 2
{
    print "Doing Mid-Course Correction " + mnum.
    set wait_time to "x".
    set wait_end to "x".
    local step_sizes is "x".
    if (ship:orbit:hasnextpatch = false or ship:orbit:nextpatch:body <> target)
    {
        set wait_time to min(eta:apoapsis/3, eta:periapsis/2).
        set wait_end to time:seconds + wait_time + 15.
        set step_sizes to list(100, 10, 1, 0.1).
    }
    else
    {
        local time_body is ship:orbit:nextpatcheta.
        set wait_time to time_body/2 - 120.
        set wait_end to time:seconds + wait_time + 15.
        set step_sizes to list(10, 1, 0.1).
    }
    if mnum > 1
    {
        do_warp(wait_time).
        wait until time:seconds > wait_end.
    }

    local min_start is time:seconds + 2*60*60.
    local capture_pe is max(target:atm:height*1.5, 9000).
    local params is list(0, 0, 0).
    set params to converge_on_mnv(params, score_planet_midcourse_correction@, list(capture_pe, next_inc), min_start, step_sizes).

    set mnv to node(min_start, params[0], params[1], params[2]).
    print "Maneuver Burn:".
    print mnv.
    add_maneuver(mnv).
    execute_mnv().
    wait 5.
    for en in ship_engines
    {
        set en:thrustlimit to 5.
    }

    set mnum to mnum + 1.
}

for en in ship_engines
{
    set en:thrustlimit to 100.
}

until false
{
    print "Warping to Next Body".
    local old_body is ship:body.
    do_warp(ship:orbit:nextpatcheta).
    wait until old_body <> ship:body.
    wait 5.
    local b1 is true.
    if (ship:orbit:hasnextpatch = true)
    {
        if (ship:orbit:nextpatch:body <> sun and ship:orbit:nextpatcheta < eta:periapsis) set b1 to false.
    }
    if (ship:body = target_body and b1 = true) break.
}

wait 5.
adjust_apsides("p", 0.5*ship:body:soiradius).
wait 5.
adjust_apsides("a", next_pe).
wait 5.
adjust_apsides("p", ship:periapsis).
wait 5.

print "Finished Script".