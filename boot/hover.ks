@lazyglobal off.
core:part:getmodule("KOSProcessor"):doevent("Open Terminal").
runpath("0:/boot/load_scripts.ks").

lock throttle to 0.
lock steering to heading(0, 90).
stage.

pid_throttle_height(100).

lock inp to terminal:input:getchar().
print "Hit 'l' to launch".
wait until inp = "l".

local t0 is time:seconds.

when (time:seconds > t0 + 90) then set pid_height:setpoint to 150.


until false
{
    
    set thrott_pid to pid_height:update(time:seconds, alt:radar).
    clearscreen.
    print "Target: " + pid_height:setpoint.
    print "Height: " + alt:radar.
    print "Error : " + pid_height:error.
    print "P-Term: " + pid_height:pterm.
    print "I-Term: " + pid_height:iterm.
    print "D-Term: " + pid_height:dterm.
    wait 0.01.
}