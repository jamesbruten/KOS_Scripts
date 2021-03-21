local target_lat is 3.288333.
local target_lng is -155.5936.
local tbody is Mun.

set steeringmanager:maxstoppingtime to 2.0.

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

deploy_payload("payload").
activate_engines().
wait 5.

if (kuniverse:activevessel <> core:vessel)
{
    kuniverse:forcesetactivevessel(core:vessel).
    unlock steering.
    set target to tbody.
    AG1 on.
    wait 10.
}
set steeringmanager:maxstoppingtime to 0.5.

initial_landing_burn(target_lat, target_lng).

final_landing_burn(target_lat, target_lng).

deploy_solar_panels().




// Mun Base 3 17 18N  155 35 37W            3.288333  -155.5936