until false
{
    local test is true.
    for p in ship:parts
    {
        if (p:tag = "main_cpu") set test to false.
    }
    if (test = true) break.
    wait 60.
}

list engines in ship_engines.
for en in ship_engines
{
    if not en:ignition en:activate.
    set en:thrustlimit to 100.
}

lock steering to retrograde.
wait 20.
lock throttle to 0.1.
wait 10.
lock throttle to 1.
wait until ship:periapsis < 0.
lock throttle to 0.
