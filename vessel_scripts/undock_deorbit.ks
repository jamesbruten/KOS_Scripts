runpath("0:/boot/load_scripts.ks").

undock_leave().

activate_engines().

if (ship:body = kerbin) kerbin_deorbit().
else moon_return().