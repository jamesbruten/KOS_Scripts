@lazyglobal off.
runpath("0:/boot/load_scripts.ks").

global target_ap is 30000.
global target_pe is target_ap.
global target_inc is ship:latitude.
global target_ap_km is target_ap/1000.
global target_pe_km is target_pe/1000.


retract_solar_panels().
wait 5.

launch_to_vac(target_ap, target_inc).

adjust_apsides("a", ship:apoapsis).

deploy_solar_panels().
deploy_dp_shield().
deploy_antenna().

moon_return().