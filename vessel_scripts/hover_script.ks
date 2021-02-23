@lazyglobal off.
core:part:getmodule("KOSProcessor"):doevent("Open Terminal").
runpath("0:/boot/load_scripts.ks").

lock throttle to 0.

list engines in ship_engines.
for en in ship_engines
{
    en:activate.
}

pid_throttle_height(250).

lock inp to terminal:input:getchar().
print "Hit 'l' to launch".
wait until inp = "l".

until false
{
    set thrott_pid to min(1, max(0, thrott_pid + pid_height:update(time:seconds, alt:radar))).
    print "Target: " + pid_height:setpoint.
    print "Error:  " + pid_height:errorsum.
    print "P-Term: " + pid_height:pterm.
    print "I-Term: " + pid_height:iterm.
    print "D-Term: " + pid_height:dterm.
    wait 0.01.
}