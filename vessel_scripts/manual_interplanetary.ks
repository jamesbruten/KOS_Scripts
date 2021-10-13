// Parking Orbit Params
global target_ap_km is 120.
global target_pe_km is target_ap_km.
global target_inc is 0.
global target_ap is target_ap_km*1000.
global target_pe is target_pe_km*1000.

local target_body is Duna.
if (target_body:body = Kerbol) set target to target_body.
else set target to target_body:body.

// do launch until apoapsis in parking orbit
launch_to_ap(true).

lights on.
set steeringmanager:maxstoppingtime to 0.5.

// circularise parking orbit
adjust_apsides("a", ship:apoapsis).

wait 5.
deploy_solar_panels().
wait 5.
deploy_antenna().
wait 5.

transfer_orbit_interplanetary().
wait 5.
unset target.

deploy_payload("final").
lock throttle to 0.
wait 1.
activate_engines().

print "Warping Until Outside Kerbin SOI".
local time_kerbol is ship:orbit:nextpatcheta.
local wait_time is time_kerbol + 300.
local wait_end is time:seconds + wait_time + 15.
do_warp(wait_time).
wait until time:seconds > wait_end.

until (false)
{
    local next_soi is "None".
    if (ship:orbit:hasnextpatch) set next_soi to ship:orbit:nextpatch:body.

    clearscreen.
    print "Choose an option from the list:".
    print "1: Execute Next Maneuver Node (must manually create node first)".
    print "2: Warp to next SOI - " + next_soi.
    print "3: Circularise at next Apside".
    print "4: Finish Script".
    until false
    {
        terminal:input:clear().
        set inp to terminal:input:getchar().
        set inp to inp:tonumber(-9999).
        if (inp > 0 and inp < 4) break.
    }

    if (inp = 1)
    {
        if (ship:hasnode = false) print "No Maneuver Node Planned".
        else execute_mnv().
    }
    else if (inp = 2)
    {
        if (ship:orbit:hasnextpatch = true)
        {
            set wait_time to ship:orbit:nextpatcheta.
            set wait_end to time:seconds + wait_time + 15.
            do_warp(wait_time).
            wait until time:seconds > wait_end.
        }
    }
    else if (inp = 3)
    {
        if (eta:apoapsis < eta:periapsis) adjust_apsides("a", ship:apoapsis).
        else adjust_apsides("p", ship:periapsis).
    }
    else if (inp = 4) break.
    else print "Invalid Option".

    wait 5.
}