function pid_throttle_gforce
{
    set g to kerbin:mu / kerbin:radius^2.
    lock accvec to ship:sensors:acc - ship:sensors:grav.
    lock gforce TO accvec:mag / g.

    declare global Kp to 0.01.
    declare global Ki to 0.
    declare global Kd to 0.006.

    declare global pid to pidloop(Kp, Ki, Kd).
    set pid:setpoint to 3.

    declare global thrott_pid to 1.
    lock throttle TO thrott_pid.
}