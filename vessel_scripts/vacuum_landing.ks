local target_lat is -4.374.
local target_lng is -6.39.
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

lower_periapsis(target_lat, target_lng).

correct_landing_inc(target_lat, target_lng).

local eta_landing is lspot_closest(target_lat, target_lng).

intercept_landing_site(target_lat, target_lng, eta_landing).

initial_landing_burn(target_lat, target_lng).

final_landing_burn(target_lat, target_lng).

deploy_solar_panels().