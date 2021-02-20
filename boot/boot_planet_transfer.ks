@lazyglobal off.
core:part:getmodule("KOSProcessor"):doevent("Open Terminal").
runpath("0:/boot/load_scripts.ks").

lock inp to terminal:input:getchar().
print "Make sure body target selected.".
print "Hit 'l' to launch".
wait until inp = "l".

runpath("0:/vessel_scripts/interplanetary_transfer.ks").