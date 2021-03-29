function pid_throttle_gforce
{
    declare global g_pid to kerbin:mu / kerbin:radius^2.
    global accvec is ship:sensors:acc - ship:sensors:grav.
    global gforce is accvec:mag / g_pid. 

    global Kp_gforce is 0.05.
    global Ki_gforce is 0.
    global Kd_gforce is 0.006.

    global pid_gforce is pidloop(Kp_gforce, Ki_gforce, Kd_gforce).
    set pid_gforce:setpoint to 1.4.

    global thrott_pid is 1.
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
    global Kp_vspeed is 0.4.
    global Ki_vspeed is 0.
    global Kd_vspeed is 0.05.

    global pid_vspeed is pidloop(Kp_vspeed, Ki_vspeed, Kd_vspeed, 0.05, 1).
    set pid_vspeed:setpoint to ship:verticalspeed.

    global thrott_pid is 0.
    lock throttle to thrott_pid.
}


function pid_translate_pitch
{
    global Kp_pitch is 0.4.
    global Ki_pitch is 0.05.
    global Kd_pitch is 0.05.

    global pid_pitch is pidloop(Kp_pitch, Ki_pitch, Kd_pitch, -67.5, 67.5).
    set pid_pitch:setpoint to 0.

    global pitch_set is 0.
}