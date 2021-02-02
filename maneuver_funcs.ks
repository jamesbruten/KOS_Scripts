// functions to create and execute maneuvers

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
    local burn_dv is mnv:deltav.
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

    local burn_time is calc_burn_time(burn_dv).
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

    parameter data, score_function.
    for stepSize in list(100, 10, 1, 0.1)
    {
        until false
        {
            local oldScore is score_function(data).
            set data to improve(data, stepSize, score_function).
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

    parameter data, stepSize, score_function.
    local scoreToBeat is score_function(data).
    local bestCandidate is data.
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
        local candidateScore is score_function(candidate).
        if candidateScore < scoreToBeat
        {
            set scoreToBeat to candidateScore.
            set bestCandidate to candidate.
        }
    }
    return bestCandidate.
}

function protect_from_past
{
    parameter originalFunction.
    local replacementFunction is
    {
        parameter data.
        if (data[0] < time:seconds + 60) return 2^64.
        else return originalFunction(data).
    }.
    return replacementFunction@.
}