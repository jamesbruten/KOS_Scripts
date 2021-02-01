// calculate heading based on inclination
// function to return prograde heading

function inst_az
{
	// This function calculates the direction a ship must travel to achieve the target inclination given the current ship's latitude and orbital velocity.
	parameter inc. // target inclination
	
	// find orbital velocity for a circular orbit at the current altitude.
	local V_orb is sqrt( body:mu / ( ship:altitude + body:radius)).
	
	// project desired orbit onto surface heading
    local arcsin_val is cos(inc) / cos(ship:latitude).
    set arcsin_val to min(1, arcsin_val).
	local az_orb is arcsin (arcsin_val).
	if (inc < 0)
	{
		set az_orb to 180 - az_orb.
	}
	
	// create desired orbit velocity vector
	local V_star is heading(az_orb, 0)*v(0, 0, V_orb).

	// find horizontal component of current orbital velocity vector
	local V_ship_h is ship:velocity:orbit - vdot(ship:velocity:orbit, up:vector)*up:vector.
	
	// calculate difference between desired orbital vector and current (this is the direction we go)
	local V_corr is V_star - V_ship_h.
	
	// project the velocity correction vector onto north and east directions
	local vel_n is vdot(V_corr, ship:north:vector).
	local vel_e is vdot(V_corr, heading(90,0):vector).
	
	// calculate compass heading
	local az_corr is arctan2(vel_e, vel_n).

    local prograde_heading is compass_for_vec().
    local heading_diff is abs(abs(az_corr) - prograde_heading).
    if (heading_diff > 360) set heading_diff to heading_diff - 360.


    // limit heading to no more than 10 degrees from prograde
    // if (heading_diff > 10 and ship:velocity:orbit:mag > 2000)
    // {
    //     if (abs(az_corr) < prograde_heading) return prograde_heading - 10.
    //     else return prograde_heading + 10.
    // }

    return az_corr.
}

function compass_for_vec
{
    // What direction is east right now, in unit vector terms (we really should provide this in kOS):
    local east_unit_vec is  vcrs(ship:up:vector, ship:north:vector).

    local ship_vel is ship:velocity:surface.
    if (ship:velocity:orbit:mag > 1650) set ship_vel to ship:velocity:orbit.

    // east component of vector:
    local east_vel is vdot(ship_vel, east_unit_vec). 

    // north component of vector:
    local north_vel is vdot(ship_vel, ship:north:vector).

    // inverse trig to take north and east components and make an angle:
    local compass is arctan2(east_vel, north_vel).

    // Note, compass is now in the range -180 to +180 (i.e. a heading of 270 is
    // expressed as -(90) instead.  This is entirely acceptable mathematically,
    // but if you want a number that looks like the navball compass, from 0 to 359.99,
    // you can do this to it:
    if (compass < 0) set compass to compass + 360.

    return compass.
}