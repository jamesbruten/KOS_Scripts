runpath("0:/boot/load_scripts.ks").
clearscreen.

local rad is gilly:periapsis - 1.1*gilly:soiradius.
adjust_apsides("p", rad).
wait 5.
adjust_apsides("a", ship:apoapsis).