@lazyglobal off.
core:part:getmodule("KOSProcessor"):doevent("Open Terminal").
runpath("0:/boot/load_scripts.ks").

copypath("0:/vessel_scripts/vacuum_landing.ks", "1:vacuum_landing.ks").

runpath("1:/vacuum_landing.ks").