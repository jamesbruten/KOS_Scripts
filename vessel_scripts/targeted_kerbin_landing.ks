@lazyglobal off.
runpath("0:/boot/load_scripts.ks").

print "Select Landing Site:".
print "1 - Kerbin Runway".
print "2 - Island Runway".
print "3 - Desert Runway".

local inp is 0.
until false
{
    terminal:input:clear().
    set inp to terminal:input:getchar().
    set inp to inp:tonumber(-999).
    if (inp=1 or inp=2 or inp=3) break.
}

local landing_lat is 0.
local landing_lng is 0.

if (inp = 1)
{
    set landing_lat to -0.1025.
    set landing_lng to -74.57528.
}
else if (inp = 2)
{
    set landing_lat to -1.540833.
    set landing_lng to -71.90972.
}
else
{
    set landing_lat to -6.599444.
    set landing_lng to -144.0406.
}

wait_for_landing(landing_lat, landing_lng, ship).

undock_leave().

activate_engines().

impact_landing_site_atmosphere(landing_lat, landing_lng).

correct_landing_inc(landing_lat, landing_lng, 0.5*TRAddon:timetillimpact).

set warp to 4.
wait until ship:altitude < 71000.
AG6.
lock steering to prograde.
RCS on.
wait until ship:altitude < 60000.
print "Holding Prograde until 20000". 
print "Hit AG7 to unlock steering and turn on SAS".
when ship:altitude < 30000 then RCS off.
if (ship:altitude < 20000 or AG7)
{
    unlock steering.
    SAS on.
}