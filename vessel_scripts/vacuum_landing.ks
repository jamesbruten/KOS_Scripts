local target_lat is 44.62.
local target_lng is 46.13.
local tbody is Mun.

undock_leave().

lock steering to retrograde.
lock throttle to 0.
list engines in ship_engines.
for en in ship_engines
{
    set en:thrustlimit to 100.
    en:activate.
}

if (ship:body = tbody)
{
    if (ship:apoapsis > 75000)
    {
        print "Lowering Orbit to 50km".
        adjust_apsides("a", 50000).
        wait 5.
        adjust_apsides("p", ship:periapsis).
    }
    else if (ship:orbit:eccentricity > 0.002)
    {
        adjust_apsides("a", ship:apoapsis).
    }
}

wait_for_landing(target_lat,target_lng, ship).

retract_solar_panels().
wait 5.

if (ship:orbit:inclination > 5) local eta_landing is lower_periapsis_lat(target_lat, target_lng).
else local eta_landing is lower_periapsis_lng(target_lng).

local eta_landing is eta:periapsis + time:seconds.

correct_landing_inc(target_lat, target_lng, eta_landing, true).

intercept_landing_site(target_lat, target_lng, eta_landing).

initial_landing_burn(target_lat, target_lng).

final_landing_burn(target_lat, target_lng).

deploy_solar_panels().