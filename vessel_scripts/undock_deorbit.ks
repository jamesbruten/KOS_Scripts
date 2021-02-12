runpath("0:/boot/load_scripts.ks").

SAS off.

for dp in ship:dockingports
{
    if (dp:tag = "undocker")
    {
        print "Undocking".
        dp:undock().
        wait 0.
        break.
    }
}

print "Waiting For Target".
lock inp to terminal:input:getchar().
print "Hit 'e' once target docking port set  -- MUST be a DP".
wait until inp = "e".

RCS on.
leave_keepout(target, 10).
RCS off.

set target to "".
lock steering to retrograde.
lock throttle to 0.

list engines in ship_engines.
for en in ship_engines
{
    en:activate.
    set en:thrustlimit to 100.
}
wait 10.

lock throttle to 1.
wait until ship:periapsis < 0.
lock throttle to 0.

deploy_dp_shield().

for p in ship:parts
{
    if (p:hasmodule("moduledecouple")) p:getmodule("moduledecouple"):doevent("decouple").
}

wait until alt:radar < 60000.
unlock steering.
wait until alt:radar < 6000.
chutes on.