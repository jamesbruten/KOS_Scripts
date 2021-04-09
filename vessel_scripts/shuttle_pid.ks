global alt_kp is 0.083.
global alt_ki is 0.0.
global alt_kd is 0.015.
global alt_pid is PIDLOOP(alt_kp, alt_ki, alt_kd).

global pit_kp is 0.00110.
global pit_ki is 0.00001.
global pit_kd is 0.00440.
global pitch_pid is PIDLOOP(pit_kp, pit_ki, pit_kd).

global roll_kp is 0.00020.
global roll_ki is 0.0.
global roll_kd is 0.001.
global roll_pid is PIDLOOP(roll_kp, roll_ki, roll_kd).

global spd_kp is 0.0016.
global spd_ki is 0.0.
global spd_kd is 0.0121.
global spd_pid is PIDLOOP(spd_kp, spd_ki, spd_kd).

global vs_kp is 0.031.
global vs_ki is 0.00000.
global vs_kd is 0.081.
global vs_pid to PIDLOOP(vs_kp, vs_ki, vs_kd).

global yaw_kp is 0.0007.
global yaw_ki is 0.0.
global yaw_kd is 0.00680.
global yaw_pid is PIDLOOP(yaw_kp, yaw_ki, yaw_kd).