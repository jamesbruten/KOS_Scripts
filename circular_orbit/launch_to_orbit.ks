function main
{
    set steeringmanager:maxstoppingtime to 0.05. 
    declare global target_ap_km to 100.
    declare global target_pe_km to target_ap_km.
    declare global target_ap to target_ap_km * 1000.
    declare global target_pe to target_ap.
    declare global target_inc to 90.
    // Do Countdown
    countdown().
    // Do Launch to 1500 - steering up, thrust max
    initial_launch().
    // fly on defined pitch heading to 10km
    to_ten_km().
    // fly prograde until apoapsis height reached.
    prograde_climb().
    wait until alt:radar > 70000.
    local burn_time is create_mnv().
    execute_mnv(burn_time).
    wait until false.
}

function countdown
{
    // Countdown and ignition of engines
    lock throttle to 1.
    local tminus is 5.
    until (tminus < 1)
    {
        clearscreen.
        print "Target Apoapsis:    " + target_ap_km.
        print "Target Periapsis:   " + target_pe_km.
        print "Target Inclination: " + target_inc.
        print "".
        print "Initiating Launch Program".
        print "t-minus: " + tminus.
        if (tminus < 2)
        {
            print "Engine Ignition".
            if (tminus = 1) stage.
        }
        set tminus to tminus - 1.
        WAIT 1.
    }
}

function initial_launch
{
    lock current_pitch to 90.
    lock steering to heading(0, current_pitch, 0).
    print "Liftoff".
    print "Climbing to 700m".
    stage.
    until (alt:radar > 700)
    {
        if (check_stage_thrust() = false) autostage().
        wait 0.02.
    }
}

function to_ten_km
{
    // Will fly this path calculated from WA
    // -8.94037×10^-8 x^2 - 0.00370273 x + 91.4233 (quadratic) where x is altitude
    // Starts at 700m with pitch of 90
    // Ends at 10km with pitch of 45
    // Currently just following inclination azimuth

    print "Initiating Pitch and Roll Maneuver".
    lock current_pitch to -8.94037E-8 * alt:radar * alt:radar - 0.00370273 * alt:radar + 91.4233.
    lock steering to heading(inst_az(target_inc), current_pitch).
    until (alt:radar > 10000)
    {
        if (check_stage_thrust() = false) autostage().
        wait 0.01.
    }
}

function prograde_climb
{
    // Holds ship at 45 degrees or the pitch of prograde vector - whichever is lower
    // Prograde initially from surface velocity - changes to orbital when orbital speed > 1650
    // Cuts engines when target apoapsis reached
    // Deploys fairings once above 50km

    print "Climbing on Prograde Pitch".
    declare local switch_to_orbit to false.
    declare local fairings_deployed to false.
    declare local max_pitch to 45.
    lock prograde_pitch to 90 - vang(ship:srfprograde:vector, up:vector).
    lock current_pitch to min(prograde_pitch, max_pitch).
    lock steering to heading(inst_az(target_inc), current_pitch).
    until (ship:apoapsis > target_ap)
    {
        // print prograde_pitch.
        if (check_stage_thrust() = false) autostage().
        if (switch_to_orbit = false and ship:velocity:orbit:mag > 1650)
        {
            set switch_to_orbit to true.
            lock prograde_pitch to 90 - vang(ship:prograde:vector, up:vector).
        }
        if (fairings_deployed = false and alt:radar > 50000)
        {
            set fairings_deployed to true.
            deploy_fairing().

        }
        wait 0.01.
    }
    if (alt:radar < 60000) wait 0.4.
    lock throttle to 0.
    lock steering to prograde.
    print "Engine Shutdown".
    if (fairings_deployed = false)
    {
        until (alt:radar > 50000) wait 0.1.
        deploy_fairing().
    }
}

function create_mnv
{
    print "Calculating Circularisation Burn".

    // First calculate orbital velocity for circular orbit at target altitude
    // Get time until apoapsis and time at apoapsis
    // Get predicted velocity at apoapsis
    // Calculate dv difference between required and predicted

    local orbital_vel is sqrt(ship:body:mu / (ship:body:radius + ship:apoapsis)).
    local time_to_ap is eta:apoapsis.
    local time_at_ap is time:seconds + time_to_ap.
    local vel_at_ap is velocityat(ship, time_at_ap):orbit:mag.
    local burn_dv is orbital_vel - vel_at_ap.

    // Calculate stage isp
    // list engines and select engines that have beeen ignited but not flamed out
    // add on engine isp weighted by engine thrust / ship thrust

    local isp is 0.
    list engines in ship_engines.
    for en in ship_engines
    {
        if en:ignition and not en:flameout
        {
            set isp to isp + en:isp * en:maxthrust / ship:maxthrust.
        }
    }

    // calculate fuel flow rate
    // calculate burn time for required dv
    // create mnv based on burn start time and burning in only radial
    // add maneuver to flight plan

    local dfuel is ship:maxthrust / (constant:g0 * isp).
    local burn_time is (ship:mass / dfuel) * (1 - constant:e^(-(burn_dv / (isp*constant:g0)))).
    local mnv is node(timespan(time_to_ap), 0, 0, burn_dv).
    add_maneuver(mnv).
    print "Circularisation Burn:".
    print mnv.
    return burn_time.
}

function execute_mnv
{
    print "Executing Maneuver".

    parameter burn_time.
    local mnv is nextnode.
    print "Warping to maneuver - 60".
    timewarp:warpto(time:seconds + mnv:eta - 60).

    lock steering to mnv:burnvector.
    wait until time:seconds >= mnv:time.
    lock throttle to 1.
    wait until time:seconds >= time:seconds + burn_time.
    lock throttle to 0.
    lock steering to prograde.
}

function add_maneuver 
{
    // adds maneuver to flight plan
    parameter mnv.
    add mnv.
}

function remove_maneuver
{
    // removes maneuver from flight plan
    parameter mnv.
    remove mnv.
}

function check_stage_thrust
{
    // compares previous 
    if not (defined old_thrust) declare global old_thrust to ship:availablethrust.
    if (old_thrust = 0) set old_thrust to ship:availablethrust.
    if (ship:availablethrust < old_thrust - 2)
    {
        print "Flameout".
        set old_thrust to 0.
        return false.
    }
    return true.
}

function autostage
{
    // function to complete interstages
    // stages once for decoupler, then waits 0.5, then stages to ignite next stage
    print "Staging: Decoupler".
    WAIT 1.
    stage.
    if (ship:availablethrust < 0.1)
    {
        print "Staging: Ignition".
        WAIT 2.
        stage.
    }
}

function deploy_fairing
{
    // Function to deploy fairings

    print "Fairing Jettison".
    for p in ship:parts
    {
        if p:hasmodule("moduleproceduralfairing")
        {
            local decoupler is p:getmodule("moduleproceduralfairing").
            if decoupler:hasevent("deploy") decoupler:doevent("deploy").
        }
    }
}

function inst_az
{
	// This function calculates the direction a ship must travel to achieve the target inclination given the current ship's latitude and orbital velocity.
	parameter inc. // target inclination
	
	// find orbital velocity for a circular orbit at the current altitude.
	local V_orb is sqrt( body:mu / ( ship:altitude + body:radius)).
	
	// project desired orbit onto surface heading
	local az_orb is arcsin ( cos(inc) / cos(ship:latitude)).
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
    return az_corr.
}

main().