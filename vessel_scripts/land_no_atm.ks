// Functions to land on body with no atmosphere

function do_landing
{
    runpath("0:/boot/load_scripts.ks").

    SAS off.
    RCS off.

    list engines in ship_engines.
    for en in ship_engines
    {
        if not en:ignition en:activate.
        set en:thrustlimit to 100.
    }

    // Point Retro
    lock steering to retrograde.
    wait 10.
    lock throttle to 0.25.
    wait until ship:periapsis < 100.
    lock throttle to 0.

    lock steering to srfretrograde.
    until false
    {

    }

}


function stopping_distance
{
    local grav is constant:g * body:mass / body:radius^2.
    local max_decel is ship:availablethrust / ship:mass - grav.
    return ship:velocity:surface:mag^2 / (2 * max_decel).
}

function 