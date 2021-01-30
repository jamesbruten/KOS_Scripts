// This function calculates the direction a ship must travel to achieve the
// target inclination given the current ship's latitude and orbital velocity.
// Written by BriarAndRye <https://www.reddit.com/r/Kos/comments/3a5hjq>
// Modified to use the target insertion velocity to compute the inclination
// instead of the ideal circular orbit velocity - this allows insertion into
// elliptical orbits.

@LAZYGLOBAL off.

function inst_az {
	parameter inc. // target inclination
    parameter tgt_vx. // target orbital speed
	
	// find orbital velocity for a circular orbit at the current altitude.
	//local V_orb is sqrt( body:mu / ( ship:altitude + body:radius)).
	local V_orb is tgt_vx.
    
	// project desired orbit onto surface heading
	local az_orb is arcsin ( cos(inc) / cos(ship:latitude)).
	if (inc < 0) {
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
	return az_corr.
}