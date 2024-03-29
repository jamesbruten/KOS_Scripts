@lazyglobal off.
runpath("0:/boot/load_scripts.ks").


local runways is list("Kerbin", "Island", "Woomerang", "Desert", "Glacier", "Mahi Mahi", "Custom").
local gui is gui(200, 7).
set gui:x to -250.
set gui:y to 200.
local label is gui:addlabel("Select Landing Runway").
set label:style:align to "center".
set label:style:hstretch to true.
local bpressed is false.
local runway is 0.
for r in runways {
    local b is gui:addbutton(r).
    set b:onclick to {
        set runway to b:text.
        set bpressed to true.
    }.
}
local closeButton is gui:addbutton("Close").
set closeButton:onclick to {clearguis().}.
gui:show().
wait until bpressed.
clearguis().

local landing_lat is 0.
local landing_lng is 0.

global rhead1 is 0.
global rhead2 is 0.

if (runway = "Kerbin") {
    set landing_lat to -0.1025.
    set landing_lng to -74.57528.
    set rhead1 to 90.
}
else if (runway = "Woomerang") {
    set landing_lat to 45.29.
    set landing_lng to 136.11.
    set rhead1 to 290.
}
else if (runway = "Island") {
    set landing_lat to -1.540833.
    set landing_lng to -71.90972.
    set rhead1 to 90.
}
else if (runway = "Desert") {
    set landing_lat to -6.599444.
    set landing_lng to -144.0406.
    set rhead1 to 0.
}
else if (runway = "Glacier") {
    set landing_lat to 73.56.
    set landing_lng to 84.27.
    set rhead1 to 140.
}
else if (runway = "Mahi Mahi") {
    set landing_lat to -49.8.
    set landing_lng to -120.77.
    set rhead1 to 220.
}
else if (runway = "Custom") {
    set landing_lat to 0.
    set landing_lng to 0.
}

set rhead2 to rhead1 + 180.
if (rhead2 >= 360) set rhead2 to rhead2 - 360.

local landing_pos is latlng(landing_lat, landing_lng).

kerbin_landing_window(landing_lat, landing_lng).

undock_leave().

lock steering to retrograde.

deploy_dp_shield("close").
deploy_bay_doors("close").

drain_fuel().

intercept_landing_site_atmosphere(landing_lat, landing_lng).

spaceplane_reeentry(landing_pos).


function kerbin_landing_window {

    parameter target_lat, target_lng.

    local opp_lat is -1 * target_lat.
    local opp_lng is target_lng + 180.
    if (opp_lng > 180) set opp_lng to opp_lng - 360.
    local body_rot is 180 * ship:orbit:period / ship:body:rotationperiod.
    set opp_lng to opp_lng + body_rot.
    if (opp_lng > 180) set opp_lng to opp_lng - 360.

    // max distance based on 5 deg at equator
    local maxDist is greatCircle_dist(0, 0, 0, 5).

    until false {
        local warpLevel is 5.

        local dist is greatCircle_dist(opp_lat, opp_lng, ship:geoposition:lat, ship:geoposition:lng).

        if (dist < 3.5 * maxDist) set warpLevel to 4.
        set warp to warpLevel.

        if (dist < maxDist) {
            set warp to 0.
            wait until ship:unpacked.
            wait 1.
            local warpTime is 20 * ship:orbit:period / 360.
            local endTime is warpTime + time:seconds.
            do_warp(warpTime).
            wait until time:seconds > endTime + 1.
            break.
        }

        clearscreen.
        print "Landing at " + runway.
        print "Warping until landing window".
        print "Max Dist: " + round(maxDist, 2) + "  Dist: " + round(dist, 2) + "  Warp: " + warpLevel.
    }
}

function greatCircle_dist {
    parameter lat1, lng1, lat2, lng2.

    set lat1 to lat1 * constant:pi / 180.
    set lat2 to lat2 * constant:pi / 180.
    set lng1 to lng1 * constant:pi / 180.
    set lng2 to lng2 * constant:pi / 180.

    local deltaLat is abs(lat1 - lat2).
    local deltaLng is abs(lng1 - lng2).
    local a is sin(0.5*deltaLat)*sin(0.5*deltaLat) + cos(lat1)*cos(lat2) * sin(0.5*deltaLng)*sin(0.5*deltaLng).
    local c is 2 * arctan2(sqrt(a), sqrt(1-a)).
    local d is ship:body:radius * c.

    return d.
}

function intercept_landing_site_atmosphere
{
    parameter target_lat, target_lng.

    print("Impacting Landing Site").

    set steeringmanager:maxstoppingtime to 0.5.

    // 70000, 35000, 17500, 3500
    set addons:tr:prograde to true.
    set addons:tr:descentangles to list(30, 30, 10, 0).
    for p in ship:parts{
        if (p:tag = "shuttle") set addons:tr:descentangles to list(20, 17, 8, 0).
    }

    lock steering to retrograde.
    RCS on.
    wait until vang(ship:facing:forevector, retrograde:vector) < 2.
    wait 1.
    RCS off.
    wait 6.

    lock throttle to 1.
    wait until addons:tr:hasimpact = true.
    wait until addons:tr:timetillimpact < 0.65 * ship:orbit:period.
    local distList is list().
    local i is 0.
    until (i = 10) {
        distList:add(1E64).
        set i to i+1.
    }
    local minAv is 2E64.
    wait 0.1.
    set_engine_limit(2).
    until false
    {
        local impact_params is addons:tr:impactpos.
        local impact_lat is impact_params:lat.
        local impact_lng is impact_params:lng.

        local impactDist is greatCircle_dist(impact_lat, impact_lng, target_lat, target_lng).
        distList:remove(0).
        distList:add(impactDist).
        local av is average(distList).
        if (av > minAv) break.
        if (av < minAv) set minAv to av.

        clearscreen.
        print "Landing at " + runway.
        print "Ilat: " + round(impact_lat, 2) + " Ilng: " + round(impact_lng, 2).
        print "Tlat: " + round(target_lat, 2) + " Tlng: " + round(target_lng, 2).
    }
    lock throttle to 0.
    wait 3.
}

function average {
    parameter avList.

    local sum is 0.
    for item in avList {
        set sum to sum + item.
    }

    return sum / avList:length.
}

function spaceplane_reeentry
{
    parameter target_pos.

    set warp to 4.
    when (ship:altitude < 90000) then set warp to 2.
    when (ship:altitude < 80000) then set warp to 0.
    clearscreen.
    wait until ship:altitude < 80000.

    local exitSpeed is 550.

    AG6 on.    // unlock aero
    print "Aerodynamic Control Surfaces Unlocked".
    print "Controlling Pitch and Steering Until AG7 at GroundSpeed = " + exitSpeed. 

    global pitch is 30.
    global roll is 0.
    global steering_heading is compass_for_vec().
    global steering_pitch is pitch.
    calculate_steering().
    lock steering to heading(steering_heading, steering_pitch, -1 * roll).
    pid_reentry_pitch().
    pid_reentry_roll().
    print Kp_rpitch + " " + Ki_rpitch + " " + Kd_rpitch.

    when (ship:altitude < 50000) then RCS on.
    when (ship:altitude < 20000) then RCS off.

    on AG7 {
        clearscreen.
        print "Unlocking Steering and Setting SAS".
        unlock steering.
        unlock throttle.
        SAS on.
        clearguis().
    }

    local headingDiff is min(abs(compass_for_vec()-rhead1), abs(compass_for_vec()-rhead2)).
    local offset is -5000.
    if (headingDiff > 45) set offset to 0.

    wait until ship:altitude < 70000.

    local count is 0.
    until AG7 {
        local distError is calculate_pitch(target_pos, offset).
        local relative_bearing is calc_relative_bearing(target_pos).
        calculate_roll(relative_bearing).
        calculate_steering().
        
        if (ship:groundspeed < exitSpeed) AG7 on.

        if (count = 0) {
            clearscreen.
            print "Aerodynamic Control Surfaces Unlocked".
            print "Controlling Pitch and Steering Until AG7 at GroundSpeed = " + exitSpeed. 
            print "Current Pitch: " + round(pitch, 1) + "     Current Roll: " + round(roll, 2).
            print "Current Distance Error: " + round(distError, 1) + "      Offset: " + offset.
            print "Relative Bearing to Landing Site: " + round(relative_bearing, 2).
        }
        set count to count + 1.
        if (count > 1) set count to 0.

        wait 0.2.
    }

    wait 5.
    core:part:getmodule("kosprocessor"):doevent("close terminal").
    when (alt:radar < 125) then gear on.
    when (alt:radar < 10) then {
        brakes on.
        chutes on.
        AG20 on.   // Chutes Bound to AG20
    }
    wait until ship:groundspeed < 10.
}

function calculate_roll {
    parameter relative_bearing.

    set roll to pid_rroll:update(time:seconds, -1*relative_bearing).
}

function calculate_steering {
    set steering_pitch to cos(roll) * pitch.
    local prograde_heading is compass_for_vec().
    local yaw is sin(abs(roll)) * pitch.
    if (roll < 0) set yaw to -1 * yaw.
    set steering_heading to prograde_heading + yaw.
}

function calc_relative_bearing {
    parameter target_pos.

    local normal is vcrs(ship:velocity:surface, -body:position).
    local vel_vect is vxcl(up:vector, ship:velocity:surface).
    local target_vect is vxcl(up:vector, target_pos:position).
    local relative_bearing is vang(vel_vect, target_vect).
    if (vang(target_vect, normal) < vang(target_vect, -1*normal)) set relative_bearing to -1 * relative_bearing.
    return relative_bearing.
}

function calculate_pitch {
    parameter target_pos, offset.

    local target_lat is target_pos:lat.
    local target_lng is target_pos:lng.
    local impact_params is addons:tr:impactpos.

    local impactDist is greatCircle_dist(impact_params:lat, impact_params:lng, ship:geoposition:lat, ship:geoposition:lng).
    local targetDist is greatCircle_dist(target_lat, target_lng, ship:geoposition:lat, ship:geoposition:lng).

    local diff is targetDist - impactDist + offset.

    set pitch to pid_rpitch:update(time:seconds, diff).

    return diff.
}

function drain_fuel
{
    local drain is false.
    local gui is gui(200, 7).
    set gui:x to -250.
    set gui:y to 200.
    local label is gui:addlabel("Drain Fuel?").
    set label:style:align to "center".
    set label:style:hstretch to true.
    set bpressed to false.
    local y is gui:addbutton("Yes").
    local n is gui:addbutton("No").
    set y:onclick to {
        set drain to true.
        set bpressed to true.
    }.
    set n:onclick to {set bpressed to true.}.
    gui:show().
    wait until bpressed.
    clearguis().
    if (drain = false) return.

    local next_pe is 35000.
    local next_vel is sqrt(ship:body:mu * (2/(body:radius + ship:altitude) - 1/(body:radius + next_pe))).
    local dv is abs(ship:velocity:orbit:mag - next_vel).

    until false
    {
        AG9 on.
        if (stage:deltav:current < dv) break.
    }
    AG10 on.

    return.
}