until false
{
    local staged_check is true.
    for p in ship:parts
    {
        if (p:tag = "main_cpu") set staged_check to false.
    }
    print staged_check.
    if (staged_check = true) break.
    else wait 60.
}
if (ship:periapsis > 25000)
{
    lock steering to retrograde.
    wait 20.
    lock throttle to 0.3.
    wait 10.
    lock throttle to 1.
    wait until ship:periapsis < 15000.
    lock throttle to 0.
    unlock steering.
}