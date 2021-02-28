local target_lat is 6.3.
local target_lng is -152.6.

lock steering to retrograde.
lock throttle to 0.
list engines in ship_engines.
for en in ship_engines
{
    set en:thrustlimit to 100.
    en:activate.
}

wait_for_landing(target_lat,target_lng, ship).

local eta_landing is lower_periapsis(target_lng).

correct_landing_inc(target_lat, target_lng, eta_landing).

intercept_landing_site(target_lat, target_lng).

final_landing().