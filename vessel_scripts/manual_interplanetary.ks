// Parking Orbit Params
global target_ap_km is 120.
global target_pe_km is target_ap_km.
global target_inc is 0.
global target_ap is target_ap_km*1000.
global target_pe is target_pe_km*1000.

local target_body is Moho.
if (target_body:body = Sun) set target to target_body.
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

local wait_end is time:seconds + 180.
do_warp(180).
wait until time:seconds > wait_end.

transfer_orbit_interplanetary().
wait 5.

// deploy_payload("final").
// lock throttle to 0.
// wait 1.
// activate_engines().

print "Warping Until Outside Kerbin SOI".
local time_kerbol is ship:orbit:nextpatcheta.
local wait_time is time_kerbol + 300.
local wait_end is time:seconds + wait_time + 15.
do_warp(wait_time).
wait until time:seconds > wait_end.

until (false)
{
    if (ship:body = target_body:body) set target to target_body.
    local next_soi is "None".
    if (ship:orbit:hasnextpatch) set next_soi to ship:orbit:nextpatch:body.

    local options is list("Execute Next Maneuver Node (must manually create node first)",
                          "Warp to next SOI - " + next_soi,
                          "Circularise at next Apside",
                          "Finish Script").

    clearscreen.
    local gui is gui(200, 7).
    set gui:x to -250.
    set gui:y to 200.
    local label is gui:addlabel("Select Next Option").
    set label:style:align to "center".
    set label:style:hstretch to true.
    local bpressed is false.
    local inp is 0.
    local onum is 1.
    for o in options {
        local b is gui:addbutton(o).
        set o:onclick to {
            set inp to onum.
            set bpressed to true.
        }.
        set onum to onum + 1.
    }
    local closeButton is gui:addbutton("Close").
    set closeButton:onclick to {clearguis().}.
    gui:show().
    wait until bpressed.
    clearguis().

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