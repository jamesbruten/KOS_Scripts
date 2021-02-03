// functions to create and execute maneuvers

function calculate_mnv
{
    // change parameters in used_funcs and targets to create desired maneuver node
    // Will then create maneuver based on those scores
    // Score functions below

    local params is list(time:seconds+30, 0, 0, 0).
    local used_funcs is list(score_apoapsis@, score_arg_ap@).
    local targets is list(wanted_ap, wanted_arg_ap).
    set params to converge_on_mnv(params, used_funcs, targets).
    set mnv to node(params[0], params[1], params[2], params[3]).
    add_maneuver(mnv).
}

function adjust_apsides
{
    // raise/lower opposite of burn_node
    parameter burn_node.

    list engines in ship_engines.
    declare local burn_time is 0.
    until false
    {
        set burn_time to create_apside_mnv(burn_node).
        if (burn_time < 2)
        {
            local mnv is nextnode.
            remove_maneuver(mnv).
            for en in ship_engines
            {
                if (en:thrustlimit = 100) set en:thrustlimit to 5.
                else set en:thrustlimit to en:thrustlimit / 5.
            }
        }
        else break.
    }

    execute_mnv(burn_time).

    for en in ship_engines
    {
        set en:thrustlimit to 100.
    }

    wait 5.
}

function calc_burn_time
{
    // calculate fuel flow rate
    // calculate burn time for required dv

    local mnv is nextnode.
    local burn_dv is mnv:deltav:mag.
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

    local burn_time is calc_burn_time().
    print "Burn Time: " + burn_time.
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

function converge_on_mnv
{
    // Sends step size and relevant score function to improve function
    // Breaks out of loop once score drops - at best possible score

    parameter data, score_function, function_targs.
    for stepSize in list(100, 10, 1, 0.1)
    {
        until false
        {
            local oldScore is score_function(data).
            set data to improve(data, stepSize, score_function, function_targs).
            if oldScore <= score_function(data) break.
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

    parameter data, stepSize, score_function, function_targs.
    local score_to_beat is 0.
    local ind1 is 0.
    until ind1 >= score_function:length
    {
        set sf to score_function[ind1].
        set tf to function_targs[ind1].
        set score_to_beat to score_to_beat + sf(data, tf).
    }
    local best_candidate is data.
    local candidates is list().
    local index is 0.
    until index >= data:length
    {
        local incCandidate is data:copy().
        local decCandidate is data:copy().
        set incCandidate[index] to incCandidate[index] + stepSize.
        set decCandidate[index] to decCandidate[index] - stepSize.
        candidates:add(incCandidate).
        candidates:add(decCandidate).
        set index to index + 1.
    }
    for candidate in candidates
    {
        local candidate_score is 0.
        local ind2 is 0.
        until ind2 >= score_function:length
        {
            set sf to score_function[ind2].
            set tf to function_targs[ind2].
            set candidate_score to candidate_score + sf(data, tf).
        }
        if candidate_score < score_to_beat
        {
            set score_to_beat to candidate_score.
            set best_candidate to candidate.
        }
    }
    return best_candidate.
}

function score_apoapsis
{
    // score a maneuver based on apoapsis height
    parameter data, target_ap.
    local score is 0.
    local mnv is node(data[0], data[1], data[2], data[3]).
    if (data[0] < time:seconds+15) return 2^64. // prevent from selecting value in the past/near future
    add_maneuver(mnv).

    local ap_height is mnv:orbit:apoapsis.
    set score to score + abs(ap_height - target_ap).
    
    remove_maneuver(mnv).
    return score.
}

function score_arg_ap
{
    // score maneuver based on score of argument of apoapsis (arg_pe + 180)
    parameter data, target_ang.
    local score is 0.
    local mnv is node(data[0], data[1], data[2], data[3]).
    if (data[0] < time:seconds+15) return 2^64. // prevent from selecting value in the past/near future
    add_maneuver(mnv).

    local arg_ap is mnv:orbit:argumentofperiapsis - mnv:orbit:longitudeofascendingnode + 180.
    if (arg_ap > 360) set arg_ap to arg_ap - 360.
    if (arg_ap < 0) set arg_ap to arg_ap + 360.
    set score to score + abs(arg_ap - target_ang).
    
    remove_maneuver(mnv).
    return score.
}
