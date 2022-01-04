@lazyglobal off.
runpath("0:/boot/load_scripts.ks").

print "Select Landing Site:".
print "1 - Kerbin Runway".
print "2 - Island Runway".
print "3 - Desert Runway".
print "4 - Glacier Runway".
print "5 - Mahi Mahi Runway".
print "6 - Custom".

local inp is 0.
until false
{
    terminal:input:clear().
    set inp to terminal:input:getchar().
    set inp to inp:tonumber(-999).
    if (inp=1 or inp=2 or inp=3 or inp=4 or inp=5 or inp=6) break.
}

local landing_lat is 0.
local landing_lng is 0.

if (inp = 1)
{
    set landing_lat to -0.1025.
    set landing_lng to -74.57528.
}
else if (inp = 2)
{
    set landing_lat to -1.540833.
    set landing_lng to -71.90972.
}
else if (inp = 3)
{
    set landing_lat to -6.599444.
    set landing_lng to -144.0406.
}
else if (inp = 4)
{
    set landing_lat to 73.56.
    set landing_lng to 84.27.
}
else if (inp = 5)
{
    set landing_lat to -49.8.
    set landing_lng to -120.77.
}
else if (inp = 6)
{
    set landing_lat to 0.
    set landing_lng to 0.
}

kerbin_landing_window(landing_lat, landing_lng).

kuniverse:quicksave().

undock_leave().

deploy_dp_shield().

intercept_landing_site_atmosphere(landing_lat, landing_lng).

spaceplane_reeentry().


function kerbin_landing_window
{
    parameter target_lat, target_lng.

    local burn_lat is -1 * target_lat.
    local burn_lng is target_lng + 180.
    if (burn_lng > 180) set burn_lng to burn_lng - 360.         // opposite longitude to landing
    local body_rot is 180 * ship:orbit:period / ship:body:rotationperiod. // degrees of body rotation in half orbit
    set burn_lng to burn_lng + body_rot.                        // now opposite of where site will be with half orbit rotation
    if (burn_lng > 180) set burn_lng to burn_lng - 360.   


    local warp_level is 0.
    until false
    {
        local diff_lat is abs(ship:geoposition:lat - burn_lat).
        local diff_lng is abs(ship:geoposition:lng - burn_lng).

        if (diff_lat < 10 and diff_lng > 5) set diff_lat to 12.

        set warp_level to warp_at_level(1, 2, 10, diff_lat).

        if (warp_level = 0) break.
        
        clearscreen.
        print "Warping to " + 90 + " Deg Normal Angle".
        print round(diff_lat, 2) + "      " + round(diff_lng, 2) + "      " + warp_level.
    }
    wait 1.
}

function intercept_landing_site_atmosphere
{
    parameter target_lat, target_lng.

    print("Impacting Landing Site").

    set addons:tr:descentangles to list(60, 60, 30, 30).

    lock steering to retrograde.
    RCS on.
    wait until vang(ship:facing:forevector, retrograde:vector) < 2.
    wait 3.
    RCS off.
    lock throttle to 1.
    wait until addons:tr:hasimpact = true.
    wait 0.5.
    // local record is list(99999,99999,99999,99999,99999,99999,99999,99999,99999,99999).
    // local lastAv is 99999.
    until false
    {
        local impact_params is addons:tr:impactpos.
        local impact_lat is impact_params:lat.
        local impact_lng is impact_params:lng.

        local diff_lat is abs(impact_lat - target_lat).
        local diff_lng is abs(impact_lng - target_lng).
        if (diff_lng > 180) set diff_lng to 360 - diff_lng.

        local tot_diff is diff_lat + diff_lng.

        local targetPos is latlng(target_lat, target_lng):position:mag.
        local impactPos is latlng(impact_lat, impact_lng):position:mag.

        if (tot_diff < 8 and impactPos < targetPos) break.

        // record:add(tot_diff).
        // record:remove(0).
        // local av is 0.
        // for r in record {
        //     set av to av + r.
        // }
        // set av to av / 10.
        // if (av > lastAv and impactPos < targetPos) break.
        // set lastAv to av.

        clearscreen.
        print "Ilat: " + round(impact_lat, 2) + " Ilng: " + round(impact_lng, 2).
        print "Tlat: " + round(target_lat, 2) + " Tlng: " + round(target_lng, 2).
        print "Dlat: " + round(diff_lat, 2) + " Dlng: " + round(diff_lng, 2).
        print "Total Diff: " + round(tot_diff, 2).
    }
    lock throttle to 0.
    wait 3.
}

function spaceplane_reeentry
{
    set warp to 4.
    when (ship:altitude < 100000) then set warp to 2.
    when (ship:altitude < 85000) then set warp to 0.
    wait until ship:altitude < 85000.

    local prograde_heading is compass_for_vec().
    AG6 on.    // unlock aero
    print "Aerodynamic Control Surfaces Unlocked".
    print "Holding 60 Pitch until 25000". 

    lock steering to heading(prograde_heading, 60, 0).

    when (ship:altitude < 50000) then RCS on.
    when (ship:altitude < 40000) then RCS off.

    on AG7
    {
        print "Unlocking Steering and Setting SAS to Prograde".
        unlock steering.
        SAS on.
    }

    until AG7
    {
        set prograde_heading to compass_for_vec().
        if (ship:altitude < 25000) AG7 on.
    }
    unlock throttle.

    when (alt:radar < 125) then gear on.

    when (alt:radar < 10) then
    {
        brakes on.
        chutes on.
    }
    wait until ship:groundspeed < 10.
}