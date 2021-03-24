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
	local impact_pos is ground_track(positionat(ship,impactUTs), impactUTs).
	local newImpactHeight is impact_pos:terrainheight.
	set impact_UTs_impactHeight to (impact_UTs_impactHeight + newImpactHeight) / 2.
	return LEX("time", impactUTs, //the UTs of the ship's impact
	"impactHeight", impact_UTs_impactHeight, //the aprox altitude of the ship's impact
	"converged", ((abs(impact_UTs_impactHeight - newImpactHeight) * 2) < min_error),
	"point", impact_pos). //will be true when the change in impactHeight between runs is less than the minError
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