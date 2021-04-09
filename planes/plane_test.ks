@lazyglobal off.
runpath("0:/planes/plane_pids.ks").
runpath("0:/lib_navball.ks").

global bank_limit is 30.
global yaw_limit is 0.8.
global pitch_max is 25.
global pitch_min is -15.
global vs_max is 75.
global vs_min is -100.

global turn_right_prev is false.

brakes on.
lock inp to terminal:input:getchar().
print "Hit 'l' to continue".
wait until inp = "l".

takeoff().

until false
{
    autopilot(90, 250, 500).
}

function takeoff
{
    print "Takeoff".
    local tgt_hdg is 90.
    local tgt_pitch is 0.
    lock steering to heading(tgt_hdg, tgt_pitch).
    lock throttle to 0.
    wait 2.
    stage.
    wait 1.
    brakes on.
    lock throttle to 1.
    wait 2.
    brakes off.

    local mode is 0.
    when (mode = 2) then gear off.
    until false
    {
        if (ship:airspeed > 100 and mode = 0) set mode to 1.
        if (ship:verticalspeed > 10 and alt:radar > 20) set mode to 2.

        if (mode = 0) set tgt_pitch to 0.
        else if (mode = 1) set tgt_pitch to 35.
        else if (mode = 2) set tgt_pitch to 15.

        if (alt:radar > 300) break.

        clearscreen.
        print "Takeoff".
        print "Mode: " + mode + "   tgt_hdg: " + round(tgt_hdg, 2) + "   tgt_pitch: " + round(tgt_pitch, 2).
    }
    unlock steering.
}

function autopilot
{
    parameter tgt_hdg, tgt_spd, tgt_alt.

    heading_control(tgt_hdg).
    altitude_control(tgt_alt).
    speed_control(tgt_spd).
}


function heading_control
{
    parameter tgt_hdg.

    local curr_hdg is compass_for().
    local hdg_mod is mod(curr_hdg - tgt_hdg + 360, 360).
	local turn_right is hdg_mod > 180.
	local hdg_err is 0.

	if (turn_right)
    {
		if (tgt_hdg < curr_hdg) set hdg_err to -((360 - curr_hdg) + tgt_hdg).
		else set hdg_err to curr_hdg - tgt_hdg.
    }
	else
    {
		if (tgt_hdg > curr_hdg + 180) set hdg_err to 360 - tgt_hdg + curr_hdg.
		else set hdg_err to curr_hdg - tgt_hdg.
	}

    local tgt_bank is -5*hdg_err.
	if (tgt_bank > bank_limit) set tgt_bank to bank_limit.
	else if (tgt_bank < -bank_limit) set tgt_bank to -bank_limit.

    set roll_pid:setpoint to tgt_bank.
	set ship:control:roll to ship:control:roll + roll_pid:update(time:seconds, roll_for()).

    if (turn_right <> turn_right_prev) set ship:control:yaw to 0.

    if (abs(roll_pid:error) <= 10 and abs(tgt_bank) <> bank_limit)
    {
        set yaw_pid:setpoint to 0.
        set ship:control:yaw to ship:control:yaw + yaw_pid:update(time:seconds, hdg_err).
        if (ship:control:yaw > yaw_limit) set ship:control:yaw to yaw_limit.
        else if (ship:control:yaw < -yaw_limit) set ship:control:yaw to -yaw_limit.
	}

	set turn_right_prev to turn_right.
}

function altitude_control
{
    parameter tgt_alt.

    if (ship:airspeed < 300) set vs_max to 50.
    else set vs_max to 75.

    set alt_pid:setpoint to tgt_alt.
    local tgt_vs is alt_pid:update(time:seconds, ship:altitude).

    if (tgt_vs > vs_max) set tgt_vs to vs_max.
    else if (tgt_vs < vs_min) set tgt_vs to vs_min.

    vs_control(tgt_vs).
}

function vs_control
{
    parameter tgt_vs.

    local tgt_pitch is pitch_for().

	set vs_pid:setpoint to tgt_vs.
	set tgt_pitch to tgt_pitch + vs_pid:update(time:seconds, ship:verticalspeed).

    if (ship:airspeed < 200 and tgt_pitch > 22) set tgt_pitch to 20.

	if (tgt_pitch > pitch_max) set tgt_pitch to pitch_max.
	else if (tgt_pitch < pitch_min) set tgt_pitch to pitch_min.

	set pitch_pid:setpoint to tgt_pitch.
	set ship:control:pitch to ship:control:pitch + pitch_pid:update(time:seconds, pitch_for()).

	if (ship:airspeed > 300)
    {
		set pitch_pid:KP to pitch_kp * (2500 - ship:airspeed) / 2500.
		set pitch_pid:KI to pitch_ki * (2500 - ship:airspeed) / 2500.
		set pitch_pid:KD to pitch_kd * (2500 - ship:airspeed) / 2500.
	}
}

function speed_control
{
    parameter tgt_spd.
    
	set spd_pid:setpoint to tgt_spd.
	local dv_thrott is spd_pid:update(time:seconds, ship:airspeed).
	lock throttle to dv_thrott.
}