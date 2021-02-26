runpath("0:/boot/load_scripts.ks").

lock inp to terminal:input:getchar().
print "Hit 'l' to start RCS movement".
wait until inp = "l".

print "Leaving via RCS".
SAS off.
RCS on.
set ship:control:fore to -1.
wait 20.
RCS off.
print "Waiting 30".
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
print "Deorbit Burn".
lock throttle to 1.
wait until ship:periapsis < 0.
lock throttle to 0.
print "Shutdown".

wait 5.

deploy_dp_shield().
wait 5.

print "Decouple".
AG1 on.

wait until alt:radar < 60000.
print "Steering Off".
unlock steering.
wait until alt:radar < 6000.
print "Deploy Chutes".
chutes on.