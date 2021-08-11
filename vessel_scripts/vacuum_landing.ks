// Mun Base            3 17 18N  155 35 37W            3.288333  -155.5936
// Mun LC A     3.323333    -155.5653
// Mun LC B     3.269167    -155.5603
// Mun LC C     3.251389    -155.6219
// Mun LC D     3.259722    -155.635


local target_lat is 3.383889.
local target_lng is -155.5744.
local tbody is Mun.

// local pad is "Mun LC B".
// local coords is mun_pads[pad].
// local target_lat is coords[0].
// local target_lng is coords[1].
// local tbody is Mun.

// set steeringmanager:maxstoppingtime to 2.
// undock_leave().

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

for p in ship:parts
{
    if (p:tag = "payload")
    {
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
        break.
    }
}

set steeringmanager:maxstoppingtime to 0.75.

initial_landing_burn(target_lat, target_lng).

final_landing_burn(target_lat, target_lng).

wait 3.
deploy_solar_panels().
