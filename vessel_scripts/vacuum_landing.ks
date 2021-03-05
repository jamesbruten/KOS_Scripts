local target_lat is 2.8.
local target_lng is 81.5.

lock steering to retrograde.
lock throttle to 0.
list engines in ship_engines.
for en in ship_engines
{
    set en:thrustlimit to 100.
    en:activate.
}

wait_for_landing(target_lat,target_lng, ship).

if (abs(target_lat) > 80) local eta_landing is lower_periapsis_lat(target_lat).
else local eta_landing is lower_periapsis_lng(target_lng).

correct_landing_inc(target_lat, target_lng, eta_landing, true).

intercept_landing_site(target_lat, target_lng).

final_landing(true).