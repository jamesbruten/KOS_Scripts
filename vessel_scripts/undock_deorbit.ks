runpath("0:/boot/load_scripts.ks").

lock inp to terminal:input:getchar().
print "Hit 'u' to undock or 'c' to deorbit without undocking".
wait until inp = "c" or inp = "u".

if (inp = "u") undock_leave().

if (ship:body = kerbin) kerbin_deorbit().
else moon_return().