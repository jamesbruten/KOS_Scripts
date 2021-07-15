runpath("0:/boot/load_scripts.ks").

undock_leave(5, 5).

print "Select Target Vessel     Change DP name".
print "Hit 'l' when done".
lock inp to terminal:input:getchar().
wait until inp = "l".

dock_vessels().