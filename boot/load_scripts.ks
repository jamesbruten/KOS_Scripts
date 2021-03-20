// loads in and runs all scripts so that functions in memory
@lazyglobal off.
copypath("0:/launch_to_ap.ks", "1:launch_to_ap.ks").
copypath("0:/maneuver_funcs.ks", "1:maneuver_funcs.ks").
copypath("0:/calc_isp.ks", "1:calc_isp.ks").
copypath("0:/heading_calcs.ks", "1:heading_calcs.ks").
copypath("0:/autostaging.ks", "1:autostaging.ks").
copypath("0:/deploy_functions.ks", "1:deploy_functions.ks").
copypath("0:/pid_funcs.ks", "1:pid_funcs.ks").
copypath("0:/rendezvous_funcs.ks", "1:rendezvous_funcs.ks").
copypath("0:/docking_funcs.ks", "1:docking_funcs.ks").
copypath("0:/hill_climbing.ks", "1:hill_climbing.ks").
copypath("0:/landing_funcs.ks", "1:landing_funcs.ks").
copypath("0:/transfer_funcs.ks", "1:transfer_funcs.ks").
copypath("0:/kerbin_landing.ks", "1:kerbin_landing.ks").
copypath("0:/ground_intercept.ks", "1:ground_intercept.ks").

runpath("1:launch_to_ap.ks").
runpath("1:maneuver_funcs.ks").
runpath("1:calc_isp.ks").
runpath("1:heading_calcs.ks").
runpath("1:autostaging.ks").
runpath("1:deploy_functions.ks").
runpath("1:pid_funcs.ks").
runpath("1:rendezvous_funcs.ks").
runpath("1:docking_funcs.ks").
runpath("1:hill_climbing.ks").
runpath("1:landing_funcs.ks").
runpath("1:transfer_funcs.ks").
runpath("1:kerbin_landing.ks").
runpath("1:ground_intercept.ks").


function do_warp
{
    parameter warp_delta.

    if (warp_delta > 30)
    {
        warpto(time:seconds + warp_delta).
        wait until ship:unpacked.
    }
}

function warp_at_level
{
    parameter diff0, diff2, diff4, diff.

    local warp_level is 0.

    if (diff < diff0)
    {
        set warp to 0.
        set warp_level to 0.
        wait until ship:unpacked.
    }
    else if (diff < diff2)
    {
        set warp to 2.
        set warp_level to 2.
    }
    else if (diff < diff4)
    {
        set warp to 4.
        set warp_level to 4.
    }
    else
    {
        set warp to 5.
        set warp_level to 5.
    }

    return warp_level.
}