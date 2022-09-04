function pid_throttle_gforce
{
    global g_pid is kerbin:mu / kerbin:radius^2.
    global accvec is ship:sensors:acc - ship:sensors:grav.
    global gforce is accvec:mag / g_pid. 

    global Kp_gforce is 0.05.
    global Ki_gforce is 0.
    global Kd_gforce is 0.01.

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

    global thrott_pid is 1.
    lock throttle to thrott_pid.
}


function pid_translate_pitch
{
    global Kp_pitch is 0.5.
    global Ki_pitch is 0.05.
    global Kd_pitch is 5000.

    global pid_pitch is pidloop(Kp_pitch, Ki_pitch, Kd_pitch, 0, 90).
    set pid_pitch:setpoint to 0.
}


function pid_reentry_pitch {
    global Kp_rpitch is 0.02.
    global Ki_rpitch is 0..
    global Kd_rpitch is 0.01.

    if (ship:name = "Lark") {
        set Kp_rpitch to 0.01.
        set Ki_rpitch to 0.
        set Kd_rpitch to 0.
    }

    for p in ship:parts {
        if (p:tag = "shuttle") {
            set Kp_rpitch to 0.01.
            set Ki_rpitch to 0.
            set Kd_rpitch to 0.005.
        }
    }

    local minPitch is -5.
    local maxPitch is 60.

    for p in ship:parts {
        if (p:tag = "shuttle") set maxPitch to 35.
    }

    global pid_rpitch is pidloop(Kp_rpitch, Ki_rpitch, Kd_rpitch, minPitch, maxPitch).
    set pid_rpitch:setpoint to 0.
}

function pid_reentry_roll {
    global Kp_rroll is 15.
    global Ki_rroll is 0.
    global Kd_rroll is 0.1.

    global pid_rroll is pidloop(Kp_rroll, Ki_rroll, Kd_rroll, -45, 45).
    set pid_rroll:setpoint to 0.
}