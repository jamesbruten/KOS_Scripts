runpath("0:/boot/load_scripts.ks").
clearscreen.

local ship_vec is ship:position - ship:body:position.
local kerbin_vec is kerbin:position - ship:body:position.

clearvecdraws().
vecdraw(v(0,0,0), ship_vec, red, "ship", 1.0, True, 0.2, True, True).
vecdraw(v(0,0,0), kerbin_vec, green, "kerbin", 1.0, True, 0.2, True, True).