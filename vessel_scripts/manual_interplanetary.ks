// Parking Orbit Params
global target_ap_km is 120.
global target_pe_km is target_ap_km.
global target_inc is 0.
global target_ap is target_ap_km*1000.
global target_pe is target_pe_km*1000.

local target_body is Dres.
if (target_body:body = Sun) set target to target_body.
else set target to target_body:body.

if (ship:status = "prelaunch") {

    // do launch until apoapsis in parking orbit
    launch_to_ap(true).

    lights on.
    set steeringmanager:maxstoppingtime to 0.5.

    wait 5.
    deploy_solar_panels().
    wait 5.
    deploy_antenna().
    wait 5.
}

set steeringmanager:maxstoppingtime to 0.5.

transfer_orbit_interplanetary().
wait 5.

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
    unlock steering.
    SAS on.

    if (ship:body = target_body:body) set target to target_body.
    local next_soi is "None".
    if (ship:orbit:hasnextpatch) set next_soi to ship:orbit:nextpatch:body.

    local options is list("Execute Next Maneuver Node (must manually create node first)",
                          "Warp to next SOI - " + next_soi,
                          "Circularise at next Apside",
                          "Finish Script").

    clearscreen.
    local lgui is gui(200, 7).
    set lgui:x to -250.
    set lgui:y to 200.
    local label is lgui:addlabel("Select Next Option").
    set label:style:align to "center".
    set label:style:hstretch to true.
    local bpressed is false.
    local inp is 0.
    local onum is 1.
    for o in options {
        local b is lgui:addbutton(o).
        set b:onclick to {
            set inp to b:text.
            set bpressed to true.
        }.
        set onum to onum + 1.
    }
    local closeButton is lgui:addbutton("Close").
    set closeButton:onclick to {clearguis().}.
    lgui:show().
    wait until bpressed.
    clearguis().

    SAS off.
    if (inp = options[0])
    {
        print "Maneuver Node Chosen".
        if (hasnode = false) print "No Maneuver Node Planned".
        else execute_mnv().
    }
    else if (inp = options[1])
    {
        print "Next SOI Chosen".
        if (ship:orbit:hasnextpatch = true)
        {
            set wait_time to ship:orbit:nextpatcheta.
            set wait_end to time:seconds + wait_time + 15.
            do_warp(wait_time).
            wait until time:seconds > wait_end.
        }
    }
    else if (inp = options[2])
    {
        print "Circularise Chosen".
        if (eta:apoapsis < eta:periapsis) adjust_apsides("a", ship:apoapsis).
        else adjust_apsides("p", ship:periapsis).
    }
    else if(inp = options[3])
    {
        print "Ending Program".
        break.
    }
    else print "Invalid Option".

    wait 5.
}