function main
{
    // if using boot_deorbit set main_cpu tag
    // Call final decoupler payload_deploy
    set steeringmanager:maxstoppingtime to 0.1. 
    declare global target_ap_km to 200.
    declare global target_pe_km to 200.
    declare global target_inc to 85.

    if (target_ap_km < target_pe_km)
    {
        local temp is target_ap_km.
        set target_ap_km to target_pe_km.
        set target_pe_km to temp.
    }

    declare global target_ap to target_ap_km * 1000.
    declare global target_pe to target_pe_km * 1000.

    print "Target Apoapsis:    " + target_ap_km.
    print "Target Periapsis:   " + target_pe_km.
    print "Target Inclination: " + target_inc.

    lock char to terminal:input:getchar().
    print "Hit 'l' to launch".
    wait until char = "l".

    // Do Countdown
    countdown().

    // Do Launch to 1500 - steering up, thrust max
    initial_launch().

    // fly on defined pitch heading to 10km
    to_ten_km().

    // fly prograde until apoapsis height reached.
    prograde_climb().
    if (alt:radar >= 70000) wait 10.
    else wait until alt:radar >= 70000.

    // Create and Execute Maneuver to raise periapsis
    local burn_time is create_mnv("a").
    execute_mnv(burn_time).

    local final_stage_check is true.
    for en in ship:engines
    {
        if not en:ignition set final_stage_check to false.
    }

    if (final_stage_check = false)
    {
        // Deploy Payload
        wait 10.
        deploy_payload().
    }

    wait 10.
    deploy_antenna().
    wait 3.
    deploy_solar_panels().
    wait 20.

    // Check apoapsis against desired height
    // If difference > 1km perform new burn at periapsis
    if (ship:apoapsis < target_ap-1000 or ship:apoapsis > target_ap+1000)
    {
        print "Performing Burn to adjust apoapsis".
        set burn_time to create_mnv("p").
        execute_mnv(burn_time).
        for en in ship:engines set en:thrustlimit to 100.
    }
    else print "No apoapsis adjustment required".

    wait 10.
    deploy_payload().

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
    clearscreen.
    print "Target Apoapsis:    " + target_ap_km.
    print "Target Periapsis:   " + target_pe_km.
    print "Target Inclination: " + target_inc.
    print "".
    print "Initiating Launch Program".
    print "t-minus: " + 0.
    print "Engine Ignition".
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
    declare local lock_inclination to false.
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
        if (fairings_deployed = false and alt:radar > 65000)
        {
            set fairings_deployed to true.
            deploy_fairing().
        }
        if (lock_inclination = false and ship:velocity:orbit:mag > 2000)
        {
            set lock_inclination to true.
            lock steering to ship:prograde.
        }
        wait 0.01.
    }
    if (alt:radar < 60000) wait 0.4.            // these two lines boost apoapsis slightly to negate for atmospheric drag
    else if (alt:radar < 65000) wait 0.2.
    lock throttle to 0.
    lock steering to prograde.
    print "Engine Shutdown".
    if (fairings_deployed = false)
    {
        until (alt:radar > 65000) wait 0.1.
        deploy_fairing().
    }
}

function create_mnv
{
    // burn_mode is the node where burn is taking place
    // For maneuver calc need radius at burn and final orbit semimajor
    // The semimajor should be calculated based on the actual orbit, not target
    // ie. if at apoapsis, semimajor = (real_ap + target_pe) / 2
    parameter burn_node.

    print "Calculating Maneuver Burn".

    local real_rad is 0.
    local mnv_semi_major is 0.
    local time_to_burn is 0.
    if (burn_node = "a")
    {
        set real_rad to body:radius + ship:apoapsis.
        set mnv_semi_major to (ship:apoapsis + target_pe + 2*body:radius) / 2.
        set time_to_burn to eta:apoapsis.
    }
    else if (burn_node = "p")
    {
        set real_rad to body:radius + ship:periapsis.
        set mnv_semi_major to (ship:periapsis + target_ap + 2*body:radius) / 2.
        set time_to_burn to eta:periapsis.
        for en in ship:engines set en:thrustlimit to 2.
    }

    local time_at_burn is time:seconds + time_to_burn.
    local vel_at_burn is velocityat(ship, time_at_burn):orbit:mag.
    local wanted_vel is sqrt(ship:body:mu * (2/real_rad - 1/mnv_semi_major)).
    local burn_dv is wanted_vel - vel_at_burn.

    local isp is calc_current_isp().

    // calculate fuel flow rate
    // calculate burn time for required dv
    // create mnv based on burn start time and burning in only radial
    // add maneuver to flight plan

    local dfuel is ship:availablethrust / (constant:g0 * isp).
    local burn_time is (ship:mass / dfuel) * (1 - constant:e^(-(burn_dv / (isp*constant:g0)))).
    local mnv is node(timespan(time_to_burn), 0, 0, burn_dv).
    add_maneuver(mnv).
    print "Circularisation Burn:".
    print mnv.
    return burn_time.
}

function execute_mnv
{
    parameter burn_time.

    print "Executing Maneuver".
    set steeringmanager:maxstoppingtime to 0.5.

    local mnv is nextnode.
    local burn_start is mnv:time - burn_time/2.
    local burn_end is mnv:time + burn_time/2.

    print "Warping to maneuver_start - 30".
    kuniverse:timewarp:warpto(burn_start - 30).

    print "Maneuver: Steering".
    lock steering to mnv:burnvector.
    
    wait until time:seconds >= burn_start.
    print "Maneuver: Ignition".
    lock throttle to 1.
    wait until time:seconds >= burn_end.
    lock throttle to 0.
    lock steering to prograde.
    print "Maneuver: Shutdown".
    remove_maneuver(mnv).
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
    // compares old max thrust to current max thrust
    // stages if current less than old
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

function deploy_solar_panels
{
    print "Extending Solar Panels".
    for p in ship:parts
    {
        if p:hasmodule("moduledeployablesolarpanel") p:getmodule("moduledeployablesolarpanel"):doevent("extend solar panel").
    }
}

function deploy_antenna
{
    print "Extending Antenna".
    for p in ship:parts
    {
        if (p:hasmodule("moduledeployableantenna") = true) p:getmodule("moduledeployableantenna"):doevent("extend antenna").
    }
}

function deploy_payload
{
    for p in ship:parts
    {
        if (p:tag = "payload_deploy")
        {
            print "Deploying Payload".
            p:getmodule("moduledecouple"):doevent("decouple").
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

    return az_corr.
}

function calc_current_isp
{
    // Calculate stage isp
    // list engines and select engines that have beeen ignited but not flamed out
    // add on engine isp weighted by engine thrust / ship thrust

    local isp is 0.
    list engines in ship_engines.
    for en in ship_engines
    {
        if en:ignition and not en:flameout
        {
            set isp to isp + en:isp * en:availablethrust / ship:availablethrust. 
        }
    }
    return isp.
}

main().