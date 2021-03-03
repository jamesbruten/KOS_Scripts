@lazyglobal off.
core:part:getmodule("KOSProcessor"):doevent("Open Terminal").
runpath("0:/boot/load_scripts.ks").

copypath("0:/vessel_scripts/vacuum_landing.ks", "1:vacuum_landing.ks").
copypath("0:/vessel_scripts/moon_transfer.ks", "1:moon_transfer.ks").

runpath("1:/moon_transfer.ks").
lock inp to terminal:input:getchar().
print "Hit 'l' to start landing".
wait until inp = "l".
runpath("1:/vacuum_landing.ks").