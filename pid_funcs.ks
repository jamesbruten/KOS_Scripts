function pid_throttle_gforce
{
    declare global g to kerbin:mu / kerbin:radius^2.
    global accvec is ship:sensors:acc - ship:sensors:grav.
    lock accvec to ship:sensors:acc - ship:sensors:grav.
    global gforce is accvec:mag / g. 
    lock gforce to accvec:mag / g.

    declare global Kp to 0.15.
    declare global Ki to 0.
    declare global Kd to 0.01.

    declare global pid to pidloop(Kp, Ki, Kd, 0, 1).
    set pid:setpoint to pid_setpoint_gforce().

    declare global thrott_pid to 1.
    lock throttle to thrott_pid.
}

function pid_throttle_speed
{
    declare global Kp to 0.15.
    declare global Ki to 0.
    declare global Kd to 0.01.

    declare global pid to pidloop(Kp, Ki, Kd).
    set pid:setpoint to pid_setpoint_speed().
}

function pid_setpoint_gforce
{
    return pid_setpoint_gforce.
}