local target_lat is 4.27.
local target_lng is 147.9.
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
    if (ship:apoapsis > 100000)
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

if (abs(target_lat) > 80) local eta_landing is lower_periapsis_lat(target_lat).
else local eta_landing is lower_periapsis_lng(target_lng).

correct_landing_inc(target_lat, target_lng, eta_landing, true).

intercept_landing_site(target_lat, target_lng).

final_landing(false).

deploy_solar_panels().