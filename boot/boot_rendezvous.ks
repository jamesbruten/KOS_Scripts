@lazyglobal off.
core:part:getmodule("KOSProcessor"):doevent("Open Terminal").
runpath("0:/boot/load_scripts.ks").

lock inp to terminal:input:getchar().
if hastarget lock inp to "l".
else {
    print "Ensure Target is Set".
    print "Hit 'l' to launch".
}
wait until inp = "l".

runpath("0:/vessel_scripts/ship_rendezvous_dock.ks").