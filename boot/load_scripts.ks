// loads in and runs all scripts so that functions in memory
copypath("0:/launch_to_ap.ks", "1:launch_to_ap.ks").
copypath("0:/maneuver_funcs.ks", "1:maneuver_funcs.ks").
copypath("0:/calc_isp.ks", "1:calc_isp.ks").
copypath("0:/heading_calcs.ks", "1:heading_calcs.ks").
copypath("0:/autostaging.ks", "1:autostaging.ks").
copypath("0:/deploy_functions.ks", "1:deploy_functions.ks").

runpath("1:launch_to_ap.ks").
runpath("1:maneuver_funcs.ks").
runpath("1:calc_isp.ks").
runpath("1:heading_calcs.ks").
runpath("1:autostaging.ks").
runpath("1:deploy_functions.ks").