// functions to create and execute maneuvers

function adjust_apsides
{
    // raise/lower opposite of burn_node
    parameter burn_node.

    create_apside_mnv(burn_node).

    execute_mnv().

    wait 5.
}

function calc_burn_time
{
    // calculate fuel flow rate
    // calculate burn time for required dv
    parameter burn_dv.

    if (burn_dv = 0)
    {
        local mnv is nextnode.
        set burn_dv to mnv:deltav:mag.
    }
    local isp is calc_current_isp().
    local dfuel is ship:availablethrust / (constant:g0 * isp).
    local burn_time is (ship:mass / dfuel) * (1 - constant:e^(-(abs(burn_dv) / (isp*constant:g0)))).

    return burn_time.
}

function create_apside_mnv
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
    }
    else if (burn_node = "np")
    {
        set real_rad to body:radius + ship:altitude.
        set mnv_semi_major to (ship:periapsis + target_ap + 2*body:radius) / 2.
        set time_to_burn to 45.
    }
    else if (burn_node = "na")
    {
        set real_rad to body:radius + ship:altitude.
        set mnv_semi_major to (ship:apoapsis + target_pe + 2*body:radius) / 2.
        set time_to_burn to 45.
    }
    else if (burn_node = "a_match")
    {
        set real_rad to body:radius + ship:apoapsis.
        set mnv_semi_major to (2*ship:apoapsis + 2*body:radius) / 2.
        set time_to_burn to eta:apoapsis.
    }

    local time_at_burn is time:seconds + time_to_burn.
    local vel_at_burn is velocityat(ship, time_at_burn):orbit:mag.
    local wanted_vel is sqrt(ship:body:mu * (2/real_rad - 1/mnv_semi_major)).
    local burn_dv is wanted_vel - vel_at_burn.

    // create mnv based on burn start time and burning in only radial
    // add maneuver to flight plan

    local mnv is node(timespan(time_to_burn), 0, 0, burn_dv).
    add_maneuver(mnv).
    print "Maneuver Burn:".
    print mnv.
}

function execute_mnv
{
    set mnv to nextnode.
    lock np to lookdirup(mnv:deltav, ship:facing:topvector). //points to node, keeping roll the same.
    lock steering to np.

    //print out node's basic parameters - ETA and deltaV
    print "Node in: " + round(mnv:eta) + ", DeltaV: " + round(mnv:deltav:mag).

    //calculate ship's max acceleration
    set max_acc to ship:maxthrust/ship:mass.

    //now we just need to divide deltav:mag by our ship's max acceleration
    set burn_duration to mnv:deltav:mag/max_acc.
    print "Estimated burn duration: " + round(burn_duration) + "s".

    wait 5.
    do_warp(mnv:eta-60-burn_duration/2).
    wait until mnv:eta <= (burn_duration/2 + 45).

    //now we need to wait until the burn vector and ship's facing are aligned
    wait until abs(np:pitch - facing:pitch) < 0.15 and abs(np:yaw - facing:yaw) < 0.15.

    //the ship is facing the right direction, let's wait for our burn time
    wait until mnv:eta <= (burn_duration/2).

    //we only need to lock throttle once to a certain variable in the beginning of the loop, and adjust only the variable itself inside it
    set tset to 0.
    lock throttle to tset.

    //initial deltav
    set dv0 to mnv:deltav.

    set done to False.
    until done
    {
        //recalculate current max_acceleration, as it changes while we burn through fuel
        set max_acc to ship:maxthrust/ship:mass.

        //throttle is 100% until there is less than 1 second of time left to burn
        //when there is less than 1 second - decrease the throttle linearly
        set tset to max(min(mnv:deltav:mag/max_acc, 1), 0).

        //here's the tricky part, we need to cut the throttle as soon as our nd:deltav and initial deltav start facing opposite directions
        //this check is done via checking the dot product of those 2 vectors
        if vdot(dv0, mnv:deltav) < 0
        {
            print "End burn, remain dv " + round(mnv:deltav:mag,1) + "m/s, vdot: " + round(vdot(dv0, mnv:deltav),1).
            lock throttle to 0.
            break.
        }

        //we have very little left to burn, less then 0.1m/s
        if mnv:deltav:mag < 0.1
        {
            print "Finalizing burn, remain dv " + round(mnv:deltav:mag,1) + "m/s, vdot: " + round(vdot(dv0, mnv:deltav),1).
            //we burn slowly until our node vector starts to drift significantly from initial vector
            //this usually means we are on point
            wait until vdot(dv0, mnv:deltav) < 0.5.

            lock throttle to 0.
            print "End burn, remain dv " + round(mnv:deltav:mag,1) + "m/s, vdot: " + round(vdot(dv0, mnv:deltav),1).
            set done to True.
        }
    }
    print "Maneuver: Shutdown".
    lock steering to prograde.
    lock throttle to 0.
    wait 1.

    //we no longer need the maneuver node
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

function converge_on_mnv
{
    // Sends step size and relevant score function to improve function
    // Breaks out of loop once score drops - at best possible score

    parameter data, score_function, aimpoint, min_start.
    for step_size in list(100, 10, 1, 0.1)
    {
        until false
        {
            local old_score is score_function(data, aimpoint, min_start).
            set data to improve(data, step_size, score_function, aimpoint, min_start, old_score).
            if (old_score <= score_function(data, aimpoint, min_start)) break.
        }
    }
    return data.
}

function improve
{
    // Creates list of possible changes to mnv data
    // Passes list to score function
    // Best candidate is one with the lowest score
    // Returns the best candidate

    parameter data, step_size, score_function, aimpoint, min_start, score_to_beat.

    local best_candidate is data.
    local candidates is list().
    local index is 0.
    until index >= data:length
    {
        local incCandidate is data:copy().
        local decCandidate is data:copy().
        set incCandidate[index] to incCandidate[index] + step_size.
        set decCandidate[index] to decCandidate[index] - step_size.
        candidates:add(incCandidate).
        candidates:add(decCandidate).
        set index to index + 1.
    }
    for candidate in candidates
    {
        local candidate_score is score_function(candidate, aimpoint, min_start).
        if candidate_score < score_to_beat
        {
            set score_to_beat to candidate_score.
            set best_candidate to candidate.
        }
    }
    return best_candidate.
}

function score_aph_aparg
{
    // score a maneuver based on apoapsis height
    parameter data, aimpoint, min_start.

    if (aimpoint[0] > ship:apoapsis and data[1] < 0) return 2^50.
    if (aimpoint[0] < ship:apoapsis and data[1] > 0) return 2^50. 
    if (data[0] < min_start) return 2^50.

    local mnv is node(data[0], 0, 0, data[1]).
    add_maneuver(mnv).

    local ap_height is mnv:orbit:apoapsis.
    local score1 is abs(ap_height - aimpoint[0]).

    local arg_ap is mnv:orbit:argumentofperiapsis - mnv:orbit:longitudeofascendingnode + 180.
    if (arg_ap > 180) set arg_ap to arg_ap - 360.
    else if (arg_ap < -180) set arg_ap to arg_ap + 360.
    local score2 to abs(arg_ap - aimpoint[1]).

    local score is score1 + 1000 * score2.   
    remove_maneuver(mnv).
    return score.
}

function execute_mnv_old
{
    parameter burn_time.

    print "Executing Maneuver".
    set steeringmanager:maxstoppingtime to 0.5.

    local mnv is nextnode.
    local burn_start is mnv:time - burn_time/2.
    local burn_end is mnv:time + burn_time/2.

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