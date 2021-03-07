function wait_for_landing
{
    //  waits for srfpos to be underneat orbitable, at launch give target and ship
    parameter landing_lat, landing_long, orbitable.

    // the angle that the body rotates during one orbit of ship
    // will wait until landing site within this angle of orbit
    local ang_error is 360 * ship:orbit:period / body:rotationperiod.
    print "ang_error: " + ang_error.
    set landing_long to landing_long - ang_error.
    if (landing_long < -180) set landing_long to landing_long + 360.

    if (ship:orbit:inclination < 5)
    {
        print "Aligned with landing".
        wait 5.
        return.
    }
    else if (ship:orbit:inclination > 80 and abs(landing_lat) > 80)
    {
        print "Aligned with landing".
        wait 5.
        return.
    }

    local warp_level is 0.
    until false
    {
        local orbit_normal is vcrs(orbitable:velocity:orbit, orbitable:body:position-orbitable:position):normalized.
        local srfpos is ship:body:position - latlng(landing_lat, landing_long):position.
        local body_normal is srfpos:normalized.
        local ang is vang(orbit_normal, body_normal).
        local diff is abs(90 - ang).
        if (diff < 0.25)
        {
            set warp to 0.
            wait until ship:unpacked.
            break.
        }
        else if (diff < 0.5)
        {
            set warp to 2.
            set warp_level to 2.
        }
        else if (diff < 5)
        {
            set warp to 4.
            set warp_level to 4.
        }
        else
        {
            set warp to 5.
            set warp_level to 5.
        }
        clearscreen.
        print "Warping to " + 90 + " Deg Normal Angle".
        print round(ang, 2) + "      " + round(diff, 2) + "      " + warp_level.
    }
    wait 3.
}

function lower_periapsis_lng
{
    // waits until opposite landing site then lowers periapsis to 9000m
    parameter landing_lng.

    local p_val is 1.15 * body:radius - body:radius.

    local transfer_semimajor is (ship:orbit:semimajoraxis + p_val + body:radius) / 2.
    local transfer_t is 2*constant:pi*sqrt(transfer_semimajor^3 / body:mu). // orbital period of transfer orbit.
    local body_rot is  360 * 0.5 * transfer_t / body:rotationperiod.

    local burn_lng is landing_lng - 180.
    if (burn_lng < -180) set burn_lng to burn_lng + 360.
    set burn_lng to burn_lng + body_rot.
    if (burn_lng > 180) set burn_lng to burn_lng - 360.

    local a1 is burn_lng + 180.
    if (a1 >= 360) set a1 to a1 - 360.
    local warp_level is 0.
    until false
    {
        local a2 is ship:geoposition:lng + 180.
        if (a2 >= 360) set a2 to a2 - 360.
        local diff is a1 - a2.
        if (diff < 0) set diff to diff + 360.
        clearscreen.
        print "Warping to Longitude: " + burn_lng.
        print round(ship:geoposition:lng, 2) + "     " + round(diff, 2) + "     " + warp_level.

        if (diff < 0.25)
        {
            set warp to 0.
            wait until ship:unpacked.
            break.
        }
        else if (diff < 1)
        {
            set warp to 2.
            set warp_level to 2.
        }
        else if (diff < 10)
        {
            set warp to 4.
            set warp_level to 4.
        }
        else
        {
            set warp to 5.
            set warp_level to 5.
        }
    }

    print "Body Rot: " + body_rot.
    print "Pointing Retrograde".
    lock steering to retrograde.
    wait 15.
    print "Retrograde Burn".
    lock throttle to 0.25.
    wait until ship:periapsis < p_val+100.
    lock throttle to 0.
    print "Shutdown".
    wait 2.

    return eta:periapsis + time:seconds.
}

function lower_periapsis_lat
{
    // waits until opposite landing site then lowers periapsis to 9000m
    parameter landing_lat.

    local p_val is 1.15 * body:radius - body:radius.

    local burn_lat is -1 * landing_lat.

    local a1 is burn_lat.
    local warp_level is 0.
    until false
    {
        local a2 is ship:geoposition:lat.
        local diff is abs(a1 - a2).
        clearscreen.
        print "Warping to Latitude: " + burn_lat.
        print round(ship:geoposition:lat, 2) + "     " + round(diff, 2) + "     " + warp_level.

        if (diff < 1)
        {
            set warp to 0.
            wait until ship:unpacked.
            break.
        }
        else if (diff < 2)
        {
            set warp to 2.
            set warp_level to 2.
        }
        else if (diff < 10)
        {
            set warp to 4.
            set warp_level to 4.
        }
        else
        {
            set warp to 5.
            set warp_level to 5.
        }
    }

    print "Pointing Retrograde".
    lock steering to retrograde.
    wait 10.
    print "Retrograde Burn".
    lock throttle to 0.25.
    wait until ship:periapsis < p_val+100.
    lock throttle to 0.
    print "Shutdown".
    wait 2.

    return eta:periapsis + time:seconds.
}

function correct_landing_inc
{
    parameter landing_lat, landing_lng, eta_landing, warp_mode.

    if (warp_mode = true)
    {
        local wait_time is 2 * (eta_landing - time:seconds) / 3.
        local wait_end is wait_time + time:seconds.
        print "Warping: " + wait_time.
        do_warp(wait_time - 5).
        wait until time:seconds > wait_end.
    }

    print "Adjusting Direction Towards Landing Site".

    local normal is vcrs(ship:velocity:orbit, -body:position).
    lock steering to normal.
    wait 10.

    local vel_vect is vxcl(up:vector, ship:velocity:orbit).
    local target_vect is vxcl(up:vector, latlng(landing_lat, landing_lng):position).
    local ang_init is vang(vel_vect, target_vect).
    local ang is ang_init.

    local t_val is 0.5.
    lock throttle to t_val.
    when (ang < 0.5) then set t_val to 0.25.
    wait 0.1.
    until false
    {
        set vel_vect to vxcl(up:vector, ship:velocity:orbit).
        set target_vect to vxcl(up:vector, latlng(landing_lat, landing_lng):position).
        set ang to vang(vel_vect, target_vect).
        if (ang > ang_init)
        {
            lock throttle to 0.
            lock steering to -1 * normal.
            wait 10.
            set ang_init to 500.
            lock throttle to t_val.
        }
        if (ang < 0.025) break.
        set normal to vcrs(ship:velocity:orbit, -body:position).
        clearscreen.
        print "Targeting Landing Site      Difference: " + round(ang, 2).
    }
    lock throttle to 0.
    wait 0.5.
    lock steering to retrograde.
    wait 2.

    // clearvecdraws().
    // vecdraw(v(0,0,0), vel_vect:normalized, RGB(1,0,0), "Vel", 2, True, 0.2, True, True).
    // vecdraw(v(0,0,0), target_vect:normalized, RGB(0,1,0), "Tgt", 2, True, 0.2, True, True).
}

function intercept_landing_site
{
    parameter landing_lat, landing_lng.

    local cancel_dv_time is calc_burn_time(ship:velocity:orbit:mag).
    local wait_time is eta:periapsis - (3 * cancel_dv_time + 30).
    local wait_end is wait_time + time:seconds.
    do_warp(wait_time - 10).
    wait until time:seconds > wait_end.

    correct_landing_inc(landing_lat, landing_lng, 0, false).

    local delta_lng is 360 * eta:periapsis / ship:body:rotationperiod.
    set landing_lng to landing_lng + delta_lng.

    print("Impacting Landing Site").

    lock steering to retrograde.
    wait 10.
    lock throttle to 1.
    local tot_diff_old is 1000.
    local tot_diff_new is 1000.
    local diff_lng is 100.
    when (diff_lng < 2) then lock throttle to 0.5.
    until false
    {
        if addons:tr:hasimpact
        {
            local impact_lat is addons:tr:impactpos:lat.
            local impact_lng is addons:tr:impactpos:lng.
            local diff_lat is abs(impact_lat - landing_lat).
            set diff_lng to abs(impact_lng - landing_lng).
            if (abs(landing_lat) > 80) set diff_lng to 0.
            if (diff_lng > 180) set diff_lng to 360 - diff_lng.
            clearscreen.
            print "Ilat: " + round(impact_lat, 2) + " Ilng: " + round(impact_lng, 2).
            print "Tlat: " + round(landing_lat, 2) + " Tlng: " + round(landing_lng, 2).
            print "Dlat: " + round(diff_lat, 2) + " Dlng: " + round(diff_lng, 2).
            set tot_diff_new to diff_lat + diff_lng.
            if (tot_diff_new > tot_diff_old and diff_lng < 0.5 and diff_lat < 1.0)
            {
                lock throttle to 0.
                wait 0.5.
                break.
            }
            if (ship:groundspeed < 20)
            {
                lock throttle to 0.
                wait 0.5.
                break.
            }
            set tot_diff_old to tot_diff_new.
        }
    }
    wait 5.
}

function final_landing
{
    parameter skycrane.

    lock steering to srfretrograde.
    wait 5.
    when (alt:radar < 250) then gear on.

    local pct is stopping_distance() / (distance_to_impact() - 50).
    until false
    {
        set pct to stopping_distance() / (distance_to_impact() - 50).
        if (pct >= 1.0) break.
        clearscreen.
        print "Throttle Percent: " + pct.
        print "Waiting for Landing Burn".
        wait 0.1.
    }

    lock throttle to max(0, min(pct, 1)).

    until false
    {
        set pct to stopping_distance() / (distance_to_impact() - 50).
        clearscreen.
        print "Throttle Percent: " + pct.
        print "Initial Landing Burn".

        if (alt:radar < 50 or ship:verticalspeed >= 0 or abs(ship:groundspeed) < 0.2)
        {
            when (ship:groundspeed < 0.15) then lock steering to lookdirup(up:forevector, ship:facing:topvector).
            until false
            {
                set pct to touch_down_throttle().
                clearscreen.
                print "Throttle Percent: " + pct.
                print "Final Landing Burn".
                if (ship:status = "landed" or alt:radar < 3) break.
            }
            if (skycrane = false)
            {
                lock throttle to 0.
                unlock steering.
                clearscreen.
                print "Touch Down".
                print "Throttle Zero".
                print "Steering Unlocked".
                break.
            }
            else
            {
                brakes on.
                print "Decouple Rover".
                skycrane_decouple().
                break.
            }
        }
    }
}

function distance_to_impact
{
    local impact_data is impact_UTs().
    local time_to_impact is impact_data["time"] - time:seconds.
    return ship:velocity:surface:mag * time_to_impact.
}

function stopping_distance
{
    local grav is constant:g * body:mass / body:radius^2.
    local max_decel is (ship:availablethrust / ship:mass) - grav.
    return ship:velocity:surface:mag^2 / (2*max_decel).
}

function touch_down_throttle
{
    if (ship:verticalspeed > -0.5) return 0.
    else return stopping_distance() / (alt:radar - 3).
}

function skycrane_decouple
{
    for p in ship:parts
    {
        if (p:tag = "rover_dc")
        {
            local a is ship:apoapsis.
            p:getmodule("moduledecouple"):doevent("decouple").
            lock throttle to 1.
            lock steering to heading(0, 45, 0).
            wait until ship:apoapsis > a + 4000.
            wait 2.
            lock throttle to 0.
        }
    }
}

function impact_UTs
{   
    //returns the UTs of the ship's impact, NOTE: only works for non hyperbolic orbits
	parameter min_error is 1.

	if not (defined impact_UTs_impactHeight) {global impact_UTs_impactHeight is 0.}

	local startTime is time:seconds.
	local sma is ship:orbit:semimajoraxis.
	local ecc is ship:orbit:eccentricity.
	local craftTA is ship:orbit:trueanomaly.
	local orbitPeriod is ship:orbit:period.
	local ap is ship:apoapsis.
	local pe is ship:periapsis.
	local impactUTs is time_betwene_two_ta(ecc, orbitPeriod, craftTA, alt_to_ta(sma, ecc, ship:body, max(min(impact_UTs_impactHeight, ap-1), pe+1))[1]) + startTime.
	local newImpactHeight is ground_track(positionat(ship,impactUTs), impactUTs):terrainheight.
	set impact_UTs_impactHeight to (impact_UTs_impactHeight + newImpactHeight) / 2.
	return LEX("time", impactUTs, //the UTs of the ship's impact
	"impactHeight", impact_UTs_impactHeight, //the aprox altitude of the ship's impact
	"converged", ((abs(impact_UTs_impactHeight - newImpactHeight) * 2) < min_error)). //will be true when the change in impactHeight between runs is less than the minError
}

function alt_to_ta
{
    //returns a list of the true anomalies of the 2 points where the craft's orbit passes the given altitude
	parameter sma, ecc, bodyIn, altIn.
	local rad is altIn + bodyIn:radius.
	local taOfAlt is arccos((-sma * ecc^2 + sma - rad) / (ecc * rad)).
	return list(taOfAlt, 360-taOfAlt). //first true anomaly will be as orbit goes from PE to AP
}

function time_betwene_two_ta
{
    //returns the difference in time between 2 true anomalies, traveling from taDeg1 to taDeg2
	parameter ecc, periodIn, taDeg1, taDeg2.
	
	local maDeg1 is ta_to_ma(ecc, taDeg1).
	local maDeg2 is ta_to_ma(ecc, taDeg2).
	
	local timeDiff is periodIn * ((maDeg2 - maDeg1) / 360).
	
	return mod(timeDiff + periodIn, periodIn).
}

function ta_to_ma
{
    //converts a true anomaly(degrees) to the mean anomaly (degrees) NOTE: only works for non hyperbolic orbits
	parameter ecc, taDeg.
	local eaDeg is arctan2(sqrt(1-ecc^2) * sin(taDeg), ecc + cos(taDeg)).
	local maDeg is eaDeg - (ecc * sin(eaDeg) * CONSTANT:RADtoDEG).
	return mod(maDeg + 360,360).
}

function ground_track
{	
    //returns the geocoordinates of the ship at a given time(UTs) adjusting for planetary rotation over time, only works for non tilted spin on bodies 
	parameter pos, posTime, localBody is ship:body.
	local bodyNorth is v(0,1,0).//using this instead of localBody:NORTH:VECTOR because in many cases the non hard coded value is incorrect
	local rotationalDir is vdot(bodyNorth,localBody:angularvel) * constant:radtodeg. //the number of degrees the body will rotate in one second
	local posLATLNG is localBody:geopositionof(pos).
	local timeDif is posTime - TIME:SECONDS.
	local longitudeShift is rotationalDir * timeDif.
	local newLNG is mod(posLATLNG:LNG + longitudeShift,360).
	IF newLNG < - 180 { set newLNG to newLNG + 360. }
	IF newLNG > 180 { set newLNG to newLNG - 360. }
	return latlng(posLATLNG:LAT,newLNG).
}