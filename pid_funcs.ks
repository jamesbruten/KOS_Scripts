function pid_throttle_gforce
{
    declare global g_pid to kerbin:mu / kerbin:radius^2.
    global accvec is ship:sensors:acc - ship:sensors:grav.
    lock accvec to ship:sensors:acc - ship:sensors:grav.
    global gforce is accvec:mag / g_pid. 
    lock gforce to accvec:mag / g_pid.

    declare global Kp_gforce to 0.05.
    declare global Ki_gforce to 0.
    declare global Kd_gforce to 0.006.

    declare global pid_gforce to pidloop(Kp_gforce, Ki_gforce, Kd_gforce).
    set pid_gforce:setpoint to 1.4.

    declare global thrott_pid to 1.
    lock throttle to thrott_pid.
}


function pid_throttle_height
{
    parameter target_height.

    global Kp_height is 0.2.
    global Ki_height is 0.
    global Kd_height is 0.2.

    global pid_height is pidloop(Kp_height, Ki_height, Kd_height, 0, 1).
    set pid_height:setpoint to target_height.

    global thrott_pid is 0.
    lock throttle to thrott_pid.
}


function pid_throttle_vspeed
{
    global Kp_vspeed is 0.2.
    global Ki_vspeed is 0.05.
    global Kd_vspeed is 0.05.

    global pid_vspeed is pidloop(Kp_vspeed, Ki_vspeed, Kd_vspeed, 0, 1).
    set pid_vspeed:setpoint to -7.5.

    global thrott_pid is 0.
    lock throttle to thrott_pid.
}