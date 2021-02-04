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

// lib_lazcalc.ks - provides the user with a launch azimuth based on a desired target orbit altitude and inclination and can continued to be used throughout ascent to update the heading. It bases this calculation on the vessel's launch and current geoposition.
// Copyright © 2015,2017 KSLib team 
// Lic. MIT

//~~Version 2.2~~
//~~Created by space-is-hard~~
//~~Updated by TDW89~~
//~~Auto north/south switch by undercoveryankee~~

//To use: RUN LAZcalc.ks. SET data TO LAZcalc_init([desired circular orbit altitude in meters],[desired orbital inclination; negative if launching from descending node, positive otherwise]). Then loop SET myAzimuth TO LAZcalc(data).

FUNCTION LAZ_calc_init 
{
    PARAMETER
        desiredAlt, //Altitude of desired target orbit (in *meters*)
        desiredInc. //Inclination of desired target orbit

    PARAMETER autoNodeEpsilon IS 10. // How many m/s north or south
        // will be needed to cause a north/south switch. Pass zero to disable
        // the feature.
    SET autoNodeEpsilon to ABS(autoNodeEpsilon).
    
    //We'll pull the latitude now so we aren't sampling it multiple times
    LOCAL launchLatitude IS SHIP:LATITUDE.
    
    LOCAL data IS LIST().   // A list is used to store information used by LAZcalc
    
    //Orbital altitude can't be less than sea level
    IF desiredAlt <= 0
    {
        PRINT "Target altitude cannot be below sea level".
        SET launchAzimuth TO 1/0.		//Throws error
    }
    
    //Determines whether we're trying to launch from the ascending or descending node
    LOCAL launchNode TO "Ascending".
    IF desiredInc < 0
    {
        SET launchNode TO "Descending".
        
        //We'll make it positive for now and convert to southerly heading later
        SET desiredInc TO ABS(desiredInc).
    }
    
    //Orbital inclination can't be less than launch latitude or greater than 180 - launch latitude
    IF ABS(launchLatitude) > desiredInc
    {
        SET desiredInc TO ABS(launchLatitude).
        HUDTEXT("Inclination impossible from current latitude, setting for lowest possible inclination.", 10, 2, 30, RED, FALSE).
    }
    
    IF 180 - ABS(launchLatitude) < desiredInc
    {
        SET desiredInc TO 180 - ABS(launchLatitude).
        HUDTEXT("Inclination impossible from current latitude, setting for highest possible inclination.", 10, 2, 30, RED, FALSE).
    }
    
    //Does all the one time calculations and stores them in a list to help reduce the overhead or continuously updating
    LOCAL equatorialVel IS (2 * CONSTANT():Pi * BODY:RADIUS) / BODY:ROTATIONPERIOD.
    LOCAL targetOrbVel IS SQRT(BODY:MU/ (BODY:RADIUS + desiredAlt)).
    data:ADD(desiredInc).       //[0]
    data:ADD(launchLatitude).   //[1]
    data:ADD(equatorialVel).    //[2]
    data:ADD(targetOrbVel).     //[3]
    data:ADD(launchNode).       //[4]
    data:ADD(autoNodeEpsilon).  //[5]
    RETURN data.
}

FUNCTION LAZcalc
{
    PARAMETER
        data. //pointer to the list created by LAZcalc_init
    LOCAL inertialAzimuth IS ARCSIN(MAX(MIN(COS(data[0]) / COS(SHIP:LATITUDE), 1), -1)).
    LOCAL VXRot IS data[3] * SIN(inertialAzimuth) - data[2] * COS(data[1]).
    LOCAL VYRot IS data[3] * COS(inertialAzimuth).
    
    // This clamps the result to values between 0 and 360.
    LOCAL Azimuth IS MOD(ARCTAN2(VXRot, VYRot) + 360, 360).

    IF data[5]
    {
        LOCAL NorthComponent IS VDOT(SHIP:VELOCITY:ORBIT, SHIP:NORTH:VECTOR).
        IF NorthComponent > data[5]
        {
            SET data[4] TO "Ascending".
        }
        ELSE IF NorthComponent < -data[5]
        {
            SET data[4] to "Descending".
        }
    }
    
    //Returns northerly azimuth if launching from the ascending node
    IF (data[4] = "Ascending") RETURN Azimuth.
    ELSE IF data[4] = "Descending" //Returns southerly azimuth if launching from the descending node
    {
        IF (Azimuth <= 90) RETURN 180 - Azimuth.
        ELSE IF (Azimuth >= 270) RETURN 540 - Azimuth.
    }
}