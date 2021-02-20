// Scripts for finding best maneuver via a hill climbing algorithm
// Call in these functions in this way from a vessel script

// local params is list(min_start, 0 ...). where list vals are the individual params to use eg. time of burn, prograde etc.
// set params to converge_on_mnv(params, score_func@, list(wanted_v1, wanted_v2), min_start, list(100, 10, 1, 0.1)).

// score_func is the score function being used (below), wanted_v1 etc are the parameters to match, min_start is the earliest burn start time
// last list is the step sizes to use in the hill climbing




function converge_on_mnv
{
    // Sends step size and relevant score function to improve function
    // Breaks out of loop once score drops - at best possible score

    parameter data, score_function, aimpoint, min_start, step_sizes.
    for step_size in step_sizes
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
    // score a maneuver based on apoapsis height and argument of apoapsis
    // takes time of maneuver and prograde velocity as inputs
    // aimpoint is list(wanted+_ap, wanted_ap_arg)

    parameter data, aimpoint, min_start.

    // First 2 ensure burning prograde to raise orbit / retorgrade to lower orbit
    // 3rd ensures burn starts after min_time
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

function score_moon_midcourse_correction
{
    // Scores maneuver based on distance from Mun at closest approach
    // data is normal vel, prograde vel
    // aimpoint is Mun periapsis and Mun inclination
    // assumes mnv will be at min_start

    parameter data, aimpoint, min_start.

    local score is 0.

    local mnv is node(min_start, 0, data[0], data[1]).
    add_maneuver(mnv).

    if (mnv:orbit:hasnextpatch = false or mnv:orbit:nextpatch:body <> target)
    {
        local ap_time is eta:apoapsis.
        local diff_pos is positionat(ship, time:seconds+ap_time) - positionat(target, time:seconds+ap_time).
        remove_maneuver(mnv).
        return diff_pos:mag.
    }

    local mun_pe is mnv:orbit:nextpatch:periapsis.
    local score1 is abs(mun_pe - aimpoint[0]).
    if (mun_pe < 7500) set score1 to 2 * score1.

    local mun_inc is mnv:orbit:nextpatch:inclination.
    local score2 is abs(mun_inc - aimpoint[1]).

    set score to score1 + score2*10000.

    remove_maneuver(mnv).
    return score.
}


function score_planet_midcourse_correction
{
    // Scores maneuver based on distance from Mun at closest approach
    // data is normal vel, prograde vel
    // aimpoint is Mun periapsis and Mun inclination
    // assumes mnv will be at min_start

    parameter data, aimpoint, min_start.

    local score is 0.

    local mnv is node(min_start, data[0], data[1], data[2]).
    add_maneuver(mnv).

    if (mnv:orbit:hasnextpatch = false or mnv:orbit:nextpatch:body <> target)
    {
        local diff_pos is closest_dist_planet().
        remove_maneuver(mnv).
        return diff_pos.
    }

    local mun_pe is mnv:orbit:nextpatch:periapsis.
    local score1 is abs(mun_pe - aimpoint[0]).
    if (mun_pe < max(target:atm:height, 9000)) set score1 to 2 * score1.

    local mun_inc is mnv:orbit:nextpatch:inclination.
    local score2 is abs(mun_inc - aimpoint[1]).

    set score to score1 + score2*30000.

    remove_maneuver(mnv).
    return score.
}

function closest_dist_planet
{
    local eta_ap is eta:apoapsis.
    local left_time is time:seconds + eta_ap/2.
    local right_time is left_time + eta_ap.
    local precision is 60.
    local time_closest is ternary_search(target_distance@, left_time, right_time, precision).
    local mnv is node(time_closest, 10, 0, 0).
    return target_distance(time_closest).
}

function target_distance
{
    parameter t.
    local ans is positionat(ship, t) - positionat(target, t).
    return ans:mag.
}

function ternary_search
{
    parameter f, left, right, absolute_precision.
    until false
    {
        if (abs(right - left) < absolute_precision) return (left + right) / 2.

        local left_third is left + (right - left) / 3.
        local right_third is right - (right - left) / 3.

        if (f(left_third) > f(right_third)) set left to left_third.
        else set right to right_third.
    }
}