runpath("0:/boot/load_scripts.ks").

local targetport is "x".

for dp in ship:dockingports
{
    if (dp:tag = "target_dp")
    {
        set targetport to dp.
        break.
    }
}

// targetport:undock().

// RCS on.
// leave_keepout(targetport).
// RCS off.

lock steering to retrograde.
lock throttle to 0.

list engines in ship_engines.
for en in ship_engines
{
    en:activate.
    set en:thrustlimit to 100.
}

lock throttle to 1.
wait until ship:periapsis < 15000.
lock throttle to 0.
deploy_dp_shield().
stage.
wait until alt:radar < 10000.
stage.