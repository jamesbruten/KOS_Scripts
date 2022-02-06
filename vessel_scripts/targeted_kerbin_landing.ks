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

if (runway = "Kerbin")
{
    set landing_lat to -0.1025.
    set landing_lng to -74.57528.
}
else if (runway = "Woomerang")
{
    set landing_lat to 45.29.
    set landing_lng to 136.11.
}
else if (runway = "Island")
{
    set landing_lat to -1.540833.
    set landing_lng to -71.90972.
}
else if (runway = "Desert")
{
    set landing_lat to -6.599444.
    set landing_lng to -144.0406.
}
else if (runway = "Glacier")
{
    set landing_lat to 73.56.
    set landing_lng to 84.27.
}
else if (runway = "Mahi Mahi")
{
    set landing_lat to -49.8.
    set landing_lng to -120.77.
}
else if (runway = "Custom")
{
    set landing_lat to 0.
    set landing_lng to 0.
}

// kerbin_landing_window(landing_lat, landing_lng).

// undock_leave().

// deploy_dp_shield().

intercept_landing_site_atmosphere(landing_lat, landing_lng).

spaceplane_reeentry().


function kerbin_landing_window {

    parameter target_lat, target_lng.

    local opp_lat is -1 * target_lat.
    local opp_lng is target_lng + 180.
    if (opp_lng > 180) set opp_lng to opp_lng - 360.
    local body_rot is 180 * ship:orbit:period / ship:body:rotationperiod.
    set opp_lng to opp_lng + body_rot.
    if (opp_lng > 180) set opp_lng to opp_lng - 360.

    // max distance based on 4 deg at equator
    local maxDist is greatCircle_dist(0, 0, 0, 4).

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
    // set addons:tr:descentangles to list(60, 45, 30, 5).
    // set addons:tr:descentangles to list(40, 35, 20, 5).
    set addons:tr:descentangles to list(40, 40, 40, 40).

    lock steering to retrograde.
    RCS on.
    wait until vang(ship:facing:forevector, retrograde:vector) < 2.
    wait 1.
    RCS off.
    wait 6.

    lock throttle to 1.
    wait until addons:tr:hasimpact = true.
    wait until addons:tr:timetillimpact < 0.65 * ship:orbit:period.
    local distList is list(1E64, 1E64, 1E64, 1E64, 1E64, 1E64, 1E64, 1E64, 1E64, 1E64).
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
    set warp to 4.
    when (ship:altitude < 100000) then set warp to 2.
    when (ship:altitude < 85000) then set warp to 0.
    clearscreen.
    wait until ship:altitude < 85000.

    AG6 on.    // unlock aero
    print "Aerodynamic Control Surfaces Unlocked".
    print "Holding Pitch until AG7". 

    global manualControl is false.

    local prograde_heading is compass_for_vec().
    global pitch is 40.
    global roll is 0.
    global steering_heading is prograde_heading.
    global steering_pitch is pitch.
    lock steering to heading(steering_heading, steering_pitch, -1 * roll).

    when (ship:altitude < 50000) then RCS on.

    local gui is gui(300).
    set gui:x to -350.
    set gui:y to -250.
    local label1 is gui:addlabel("Reentry Control").
    set label1:style:align to "center".
    set label1:style:hstretch to true.

    // Pitch Slider
    local label2 is gui:addlabel("Pitch Slider (0 - 60):").
    set label2:style:align to "center".
    set label2:style:hstretch to true.
    local pitchSlider is gui:addhslider(pitch, 0, 60).
    set pitchSlider:onchange to pitch_delegate@.

    // Pitch Reset Button
    local b_pitch_reset is gui:addbutton("Reset Auto Pitch").
    set b_pitch_reset:onclick to {set manualControl to false.}.

    // Roll Slider
    local label3 is gui:addlabel("Roll Slider (-45 - +45)").
    set label3:style:align to "center".
    set label3:style:hstretch to true.
    local rollSlider is gui:addhslider(0, -45, 45).
    set rollSlider:onchange to roll_delegate@.

    // Roll Reset Button
    local b_roll_reset is gui:addbutton("Set Roll to 0").
    set b_roll_reset:onclick to {set roll to 0. set rollSlider:value to 0.}.

    // AG7 button
    local b_ag7 is gui:addbutton("Activate AG7").
    set b_ag7:onclick to {AG7 on.}.
    gui:show().

    on AG7 {
        print "Unlocking Steering and Setting SAS to Prograde".
        unlock steering.
        unlock throttle.
        SAS on.
        RCS off.
        clearguis().
    }

    local gval is kerbin:mu / kerbin:radius^2.
    until AG7 {
        calculate_steering().
        if not manualControl {
            // if (ship:altitude < 25000) set pitch to 20.
            // else if (ship:altitude < 30000) set pitch to 30.
            // else if (ship:altitude < 40000) set pitch to 40.
            // else if (ship:altitude < 45000) set pitch to 50.
            // else set pitch to 40.
            set pitchSlider:value to pitch.
            set manualControl to false.
        }
        if (ship:groundspeed < 300) AG7 on.
        clearscreen.
        print "Aerodynamic Control Surfaces Unlocked".
        print "Holding Pitch until AG7".
        if manualControl print "Taking Over Manual Control - Pitch Will Not Change Automatically".
        print "Current Pitch: " + round(pitch, 1) + "     Current Roll: " + round(roll, 1).
        wait 0.2.
    }

    wait 5.
    core:part:getmodule("kosprocessor"):doevent("close terminal").
    when (alt:radar < 125) then gear on.
    when (alt:radar < 10) then {
        brakes on.
        chutes on.
    }
    wait until ship:groundspeed < 10.
}

function pitch_delegate {
    parameter newPitch.
    set pitch to newPitch.
    if (pitch <> 60) set manualControl to true.
}

function roll_delegate {
    parameter newRoll.
    set roll to newRoll.
}

function calculate_steering {
    set steering_pitch to cos(roll) * pitch.
    local prograde_heading is compass_for_vec().
    local yaw is sin(abs(roll)) * pitch.
    if (roll < 0) set yaw to -1 * yaw.
    set steering_heading to prograde_heading + yaw.
}