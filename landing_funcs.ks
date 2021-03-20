function wait_for_landing
{
    //  waits for srfpos to be underneat orbitable, at launch give target and ship
    parameter landing_lat, landing_long, orbitable.

    // the angle that the body rotates during one orbit of ship
    // will wait until landing site within this angle of orbit
    local ang_error is 360 * ship:orbit:period / body:rotationperiod.
    set landing_long to landing_long + ang_error.
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

        set warp_level to warp_at_level(0.25, 0.35, 1.3, diff).

        if (warp_level = 0) break.
        
        clearscreen.
        print "Warping to " + 90 + " Deg Normal Angle".
        print round(ang, 2) + "      " + round(diff, 2) + "      " + warp_level.
    }
    wait 1.
}

function lower_periapsis
{
    // waits until opposite landing site then lowers periapsis to 9000m
    parameter landing_lat, landing_lng.

    local mode is 0.
    if (ship:orbit:inclination < 5) set mode to 1.

    local p_val is 1.15 * body:radius - body:radius.
    until false
    {
        if (p_val - latlng(landing_lat,landing_lng):terrainheight < 7000) set p_val to p_val + 1000.
        else break.
    }

    local transfer_semimajor is (ship:orbit:semimajoraxis + p_val + body:radius) / 2.
    local transfer_t is 2*constant:pi*sqrt(transfer_semimajor^3 / body:mu). // orbital period of transfer orbit.
    local body_rot is  360 * 0.5 * transfer_t / body:rotationperiod.

    set landing_lng to landing_lng + body_rot.
    if (landing_lng > 180) set landing_lng to landing_lng - 360.
    local burn_lng is landing_lng - 180.
    if (burn_lng < -180) set burn_lng to burn_lng + 360.

    local burn_lat is -1 * landing_lat.

    local lat1 is burn_lat.
    local lng1 is burn_lng + 180.
    if (lng1 >= 360) set lng1 to lng1 - 360.
    local warp_level is 0.
    local diff is 0.
    until false
    {
        local lng2 is ship:geoposition:lng + 180.
        if (lng2 >= 360) set lng2 to lng2 - 360.
        local lat2 is ship:geoposition:lat.
        
        local dlat is abs(lat1 - lat2).
        local dlng is lng1 - lng2.
        if (dlng < 0) set dlng to dlng + 360.

        if (mode = 0)
        {
            set diff to dlat.
            if (dlng > body_rot) set diff to max(1.1, dlat).
            set warp_level to warp_at_level(1, 2, 10, diff).
        }
        else
        {
            set diff to dlng.
            set warp_level to warp_at_level(0.25, 1, 10, diff).
        }

        if (warp_level = 0) break.

        clearscreen.
        print "Mode: " + mode.
        print "Warping to Latitude: " + round(burn_lat, 2) + "   Longitude: " + round(burn_lng, 2).
        print "DLNG: " + round(dlng, 2) + "  DLAT: " + round(dlat, 2) + "   WL: " + warp_level.
    }

    print "Body Rot: " + body_rot.
    print "Pointing Retrograde".
    lock steering to retrograde.
    wait 15.
    print "Retrograde Burn until: " + p_val.
    lock throttle to 0.25.
    wait until ship:periapsis < p_val+100.
    lock throttle to 0.
    print "Shutdown".
    wait 2.
}

function correct_landing_inc
{
    parameter landing_lat, landing_lng.

    local wait_time is 2 * eta:periapsis / 3.
    local wait_end is wait_time + time:seconds.
    print "Warping: " + wait_time.
    do_warp(wait_time - 2).
    wait until time:seconds > wait_end.

    print "Adjusting Direction Towards Landing Site".

    local normal is vcrs(ship:velocity:orbit, -body:position).
    
    set landing_lng to landing_lng + 360 * eta:periapsis / body:rotationperiod.
    if (landing_lng > 180) set landing_lng to landing_lng - 360.

    local vel_vect is vxcl(up:vector, ship:velocity:orbit).
    local target_vect is vxcl(up:vector, latlng(landing_lat, landing_lng):position).
    local ang is vang(vel_vect, target_vect).

    local t1 is vang(target_vect, normal).
    local t2 is vang(target_vect, -1*normal).
    lock steering to normal.
    if (t2 < t1) lock steering to -1 * normal.
    wait 10.

    local t_val is 0.5.
    lock throttle to t_val.
    when (ang < 0.5) then set t_val to 0.25.
    until false
    {
        set vel_vect to vxcl(up:vector, ship:velocity:orbit).
        set target_vect to vxcl(up:vector, latlng(landing_lat, landing_lng):position).
        set ang to vang(vel_vect, target_vect).
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
    parameter landing_lat, landing_lng, eta_landing.

    local cancel_dv_time is calc_burn_time(ship:velocity:orbit:mag).
    local wait_time is eta_landing - (3 * cancel_dv_time + 60).
    local wait_end is wait_time + time:seconds.
    do_warp(wait_time - 5).
    wait until time:seconds > wait_end.

    print("Impacting Landing Site").

    lock steering to retrograde.
    wait 10.
    lock throttle to 1.
    wait until addons:tr:hasimpact = True.
    wait 1.
    until false
    {
        local impact_lat is addons:tr:impactpos:lat.
        local impact_lng is addons:tr:impactpos:lng.

        local diff_lat is abs(impact_lat - landing_lat).
        local diff_lng is abs(impact_lng - landing_lng).
        if (diff_lng > 180) set diff_lng to 360 - diff_lng.

        if (diff_lat < 5)
        {
            if (diff_lng < 5) break.
            else if abs(landing_lat > 80) break.
        }
        
        clearscreen.
        print "Ilat: " + round(impact_lat, 2) + " Ilng: " + round(impact_lng, 2).
        print "Tlat: " + round(landing_lat, 2) + " Tlng: " + round(landing_lng, 2).
        print "Dlat: " + round(diff_lat, 2) + " Dlng: " + round(diff_lng, 2).
    }
    lock throttle to 0.
    wait 3.
}

function initial_landing_burn
{
    parameter landing_lat, landing_lng.

    lock steering to srfretrograde.

    local time_of_closest is lspot_closest(landing_lat, landing_lng).

    until false
    {
        local speed is ship:velocity:surface:mag.
        local burn_time is calc_burn_time(speed).
        local time_to_closest is time_of_closest - time:seconds.
        local dclose is ship:velocity:surface:mag * time_to_closest.
        local dstop is dist_during_burn(burn_time, ship:groundspeed, ship:groundspeed).
        if (dclose - dstop < dstop/6) break.
        clearscreen.
        print "Diff: " + round(dclose-dstop) + "    Dc: " + round(dclose) + "    Ds: " + round(dstop).
    }

    lock throttle to 1.
    until false
    {
        clearscreen.
        print "Surface Vel: " + round(ship:velocity:surface:mag, 2).    

        local vel_vect is vxcl(up:vector, ship:velocity:orbit).
        local target_vect is vxcl(up:vector, latlng(landing_lat, landing_lng):position).
        local ang is vang(vel_vect, target_vect).
        if (ship:velocity:surface:mag < 70 and ang < 80) break.
        if (ship:velocity:surface:mag < 20) break.
    }
    lock throttle to 0.
    wait 0.01.
}

function final_landing_burn
{
    parameter landing_lat, landing_lng.

    local landing_spot is latlng(landing_lat, landing_lng).

    local dir_params is align_landing_spot(landing_spot).
    local steer is dir_params[0].
    local dh_spot is dir_params[1].
    local vh_spot is dir_params[2].
    lock steering to lookdirup(steer, ship:facing:topvector).

    pid_throttle_vspeed().
    when (alt:radar < 250) then gear on.
    local pause is true.
    local pause_alt is 100.
    until false
    {
        local params is landing_speed_params().
        set pid_vspeed:setpoint to params[0] * alt:radar + params[1].
        set thrott_pid to pid_vspeed:update(time:seconds, ship:verticalspeed).
        
        set dir_params to align_landing_spot(landing_spot).
        set steer to dir_params[0].
        set dh_spot to dir_params[1].
        set vh_spot to dir_params[2].

        if (dh_spot < 5 and vh_spot:mag < 1) set pause to false.

        if (alt:radar < pause_alt and pause = true)
        {
            set pid_vspeed:setpoint to 0.
            until false
            {
                set thrott_pid to pid_vspeed:update(time:seconds, ship:verticalspeed).
                
                set dir_params to align_landing_spot(landing_spot).
                set steer to dir_params[0].
                set dh_spot to dir_params[1].
                set vh_spot to dir_params[2].
                
                if (dh_spot < 5 and vh_spot:mag < 1) break.

                clearscreen.
                print "Pausing to Translate".
                print "Throttle: " + round(thrott_pid, 2) + "   Vspeed: " + round(pid_vspeed:setpoint, 2) + "   Target: " + round(pid_vspeed:setpoint, 2).
                print "TDist: " + round(dh_spot, 2).
            }
            set pause to false.
        }

        if (ship:status = "landed") break.

        clearscreen.
        print "Final Landing Burn".
        print "Throttle: " + round(thrott_pid, 2) + "   Vspeed: " + round(pid_vspeed:setpoint, 2) + "   Target: " + round(pid_vspeed:setpoint, 2).
        print "TDist: " + round(dh_spot, 2).
    }
    wait 0.5.
    lock throttle to 0.
    unlock steering.
    clearscreen.
    print "Touch Down".
    print "Throttle Zero".
    print "Steering Unlocked".
}

function align_landing_spot
{
    parameter landing_spot.

    // Max angle where ship can maintain vspeed=0,  max of 75 deg
    local max_ang is arccos((body:mu * ship:mass) / (body:radius * body:radius * ship:availablethrust)).
    set max_ang to min(max_ang, 75).
    // Max decel assuming for max_ang vspeed of 0 less 25% for potential vertical deceleration
    local max_hdecel is 0.75 * sin(max_ang) * ship:availablethrust / (1000 * ship:mass).

    // current velocity towards landing spot
    local vh_spot is heading(landing_spot:heading, 0):vector * vdot(heading(landing_spot:heading,0):vector, ship:velocity:surface).
    set vh_spot to vxcl(up:vector, vh_spot).
    local sh_spot is vh_spot:mag.

    // current horizontal distance to landing spot
    local dh_spot is landing_spot:position + alt:radar*up:vector.
    set dh_spot to dh_spot:mag.

    // time to spot at current vel
    local th_spot is dh_spot / sh_spot.
    if (th_spot < 0) set th_spot to dh_spot / 0.5.      // if moving away from target set time to time assuming velocity of 0.5m/s

    // wanted velocity towards landing spot - min of distance/7.5 or 30
    local vel_targ is min(dh_spot/7.5, 30) * heading(landing_spot:heading, 0):vector.

    // acceleration to reach target velocity in 2 seconds
    if (dh_spot > 10) local acc_rec is (vel_targ - vh_spot) / 2.
    else local acc_rec is (vel_targ - vh_spot) / th_spot.

    // set acceleration to be maximum of acc due to gravity - limits pitch to 45 deg
    local acc_tgt is 3*acc_rec:normalized * min(min(acc_rec:mag, ship:sensors:grav:mag), sqrt((ship:maxthrust/ship:mass)^2-ship:sensors:grav:mag^2)).
    // velocity perpendicular to target
    local vside is ship:velocity:surface - vh_spot - up:vector * vdot(up:vector, ship:velocity:surface).
    local acc_side is -vside / 2.  // acceleration to cancel sideways velocity in 2 secs
    local acc_vec is acc_tgt + acc_side - ship:sensors:grav.

    return list(acc_vec, dh_spot, vh_spot).
}

function landing_speed_params
{
    if (body = Mun)
    {
        if (alt:radar < 15) return list(0, -1).
        if (alt:radar < 40) return line_params(-8, -1, 40, 15).
        if (alt:radar < 100) return line_params(-20, -8, 100, 40).
        if (alt:radar < 500) return line_params(-50, -20, 500, 100).
        return list(0, -50).
    }
    else
    {
        if (alt:radar < 15) return list(0, -1).
        if (alt:radar < 40) return line_params(-8, -1, 40, 15).
        if (alt:radar < 100) return line_params(-20, -8, 100, 40).
        if (alt:radar < 200) return line_params(-30, -20, 200, 100).
        return list(0, -30).
    }
}

function dist_during_burn
{
    parameter burn_time, burn_dv, speed.
    local mean_acc is burn_dv / burn_time.
    return speed * burn_time - 0.5 * mean_acc * burn_time * burn_time.
}

function lspot_closest
{
    parameter landing_lat, landing_lng.

    local search_start is eta:periapsis * 2.
    if (addons:tr:hasimpact = true) set search_start to addons:tr:timetillimpact + time:seconds.
    local t_calc is search_start.
    local landing_spot is latlng(landing_lat, landing_lng).
    local min_dist is 2^50.
    local min_time is 0.

    until false
    {
        local ship_pos is positionat(ship, t_calc).
        local dist is ship_pos  - landing_spot:position.
        if (dist:mag < min_dist)
        {
            set min_dist to dist:mag.
            set min_time to t_calc.
        }
        else break.
        set t_calc to t_calc - 1.
    }
    return min_time.
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

function line_params
{
    parameter y1, y2, x1, x2.

    local m is (y2 - y1) / (x2 - x1).
    local c is y1 - m * x1.

    return list(m, c).
}