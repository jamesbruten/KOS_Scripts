runpath("0:/boot/load_scripts.ks").

lock inp to terminal:input:getchar().
print "Hit 'l' to start RCS movement".
wait until inp = "l".

SAS off.
RCS on.
set ship:control:fore to -1.
wait 20.
RCS off.
lock steering to retrograde.
wait 10.

set target to "".
lock throttle to 0.

list engines in ship_engines.
for en in ship_engines
{
    en:activate.
    set en:thrustlimit to 100.
}
wait 20.

lock throttle to 1.
wait until ship:periapsis < 0.
lock throttle to 0.

wait 5.

deploy_dp_shield().
wait 5.

for p in ship:parts
{
    if (p:hasmodule("moduledecouple") and p:getmodule("moduledecouple"):hasevent("decouple")) p:getmodule("moduledecouple"):doevent("decouple").
}

wait until alt:radar < 60000.
unlock steering.
wait until alt:radar < 6000.
chutes on.