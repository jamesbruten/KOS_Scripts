@lazyglobal off.
runpath("0:/boot/load_scripts.ks").

print "Select Landing Site:".
print "1 - Kerbin Runway".
print "2 - Island Runway".
print "3 - Desert Runway".

local inp is 0.
until false
{
    terminal:input:clear().
    set inp to terminal:input:getchar().
    set inp to inp:tonumber(-999).
    if (inp=1 or inp=2 or inp=3) break.
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
else
{
    set landing_lat to -6.599444.
    set landing_lng to -144.0406.
}

kerbin_landing_window(landing_lat, landing_lng).

undock_leave().

lock steering to retrograde.

// local wait_time is 0.25*ship:orbit:period - 60.
// local wait_end is time:seconds + wait_time + 10.
// do_warp(wait_time).
// wait until time:seconds > wait_end.

intercept_landing_site_atmosphere(landing_lat, landing_lng).

set warp to 4.
wait until ship:altitude < 71000.
lock steering to retrograde.
AG6.
RCS on.
print "Aerodynamic Control Surfaces Unlocked".
print "Holding Rretrograde until 20000". 
print "Hit AG7 to unlock steering and turn on SAS".
when ship:altitude < 30000 then RCS off.
if (ship:altitude < 20000 or AG7)
{
    unlock steering.
    SAS on.
}
wait until ship:altitude < 19000.


function kerbin_landing_window
{
    parameter target_lat, target_lng.

    local burn_lng is target_lng + 180.
    if (burn_lng > 180) set burn_lng to burn_lng - 360.         // opposite longitude to landing
    local body_rot is 180 * ship:orbit:period / ship:body:rotationperiod. // degrees of body rotation in half orbit
    set burn_lng to burn_lng + body_rot.                        // now opposite of where site will be with half orbit rotation
    if (burn_lng > 180) set burn_lng to burn_lng - 360.            

    local warp_level is 0.
    until false
    {
        local diff_lat is abs(ship:geoposition:lat - target_lat).
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

    lock steering to retrograde.
    wait 10.
    lock throttle to 1.
    wait until addons:tr:hasimpact = true.
    wait 0.5.
    local min_val is 9999.
    until false
    {
        local impact_params is addons:tr:impactpos.
        local impact_lat is impact_params:lat.
        local impact_lng is impact_params:lng.

        local diff_lat is abs(impact_lat - target_lat).
        local diff_lng is abs(impact_lng - target_lng).
        if (diff_lng > 180) set diff_lng to 360 - diff_lng.

        if (diff_lat<15)
        {
            local diff_val is diff_lng + diff_lat.
            local dist_site is ship:body:geopositionlatlng(target_lat, target_lng):position:mag.
            local dist_imp is ship:body:geopositionlatlng(impact_lat, impact_lng):position:mag.
            if (diff_val < min_val) set min_val to diff_val.
            else if (addons:tr:timetillimpact < 0.5*ship:orbit:period and dist_imp <= dist_site) break.
        }

        clearscreen.
        print "Ilat: " + round(impact_lat, 2) + " Ilng: " + round(impact_lng, 2).
        print "Tlat: " + round(target_lat, 2) + " Tlng: " + round(target_lng, 2).
        print "Dlat: " + round(diff_lat, 2) + " Dlng: " + round(diff_lng, 2).
    }
    lock throttle to 0.
    wait 3.
}