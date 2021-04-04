// local target_lat is 3.225556.
// local target_lng is -155.6575.
// local tbody is Mun.

set target to "Mun Pad 2".
local target_lat is target:latitude.
local target_lng is target:longitude.
local tbody is Mun.

set steeringmanager:maxstoppingtime to 2.
undock_leave().

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

lower_periapsis(target_lat, target_lng).

correct_landing_inc(target_lat, target_lng).

local eta_landing is lspot_closest(target_lat, target_lng).

intercept_landing_site(target_lat, target_lng, eta_landing).

deploy_payload("payload").
wait 2.
if (kuniverse:activevessel <> core:vessel)
{
    kuniverse:forcesetactivevessel(core:vessel).
    unlock steering.
    AG1 on.
    wait 10.
}
activate_engines().

set steeringmanager:maxstoppingtime to 0.75.

initial_landing_burn(target_lat, target_lng).

final_landing_burn(target_lat, target_lng).

wait 3.
deploy_solar_panels().




// Mun Base            3 17 18N  155 35 37W            3.288333  -155.5936
// Landing Pad 1       3 21 07N  155 29 52W            3.351944  -155.4978
// Landing Pad 2       3 14 18N  155 37 06W            3.238333  -155.6183
// Landing Pad 2       3 16 34N  155 33 12W            3.276111  -155.5533