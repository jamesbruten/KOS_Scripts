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


function do_warp
{
    parameter warp_delta.

    if (warp_delta > 30)
    {
        warpto(time:seconds + warp_delta).
        wait until ship:unpacked.
    }
}