runpath("0:/boot/load_scripts.ks").
set steeringmanager:maxstoppingtime to 0.5.

lock inp to terminal:input:getchar().
print "Change DP on tug to 'tug_dp1' and DP on Station to 'tug_dp2'".
print "Press 'l' to continue".
wait until inp = "l".

local shipport is assign_ports("tug_dp1").
local targetport is assign_ports("tug_dp2").

lock inp to 0.
lock inp to terminal:input:getchar().
print "Undock and then press 'l' to begin".
wait until inp = "l".

SAS off.
RCS on.
set ship:control:fore to -1.
wait 5.
// translate(V(0,0,0)).
set ship:control:fore to 0.
wait 5.

shipport:controlfrom().

kill_relative_velocity(targetport).

print "Aligning Steering".
local steering_vector is lookdirup(-1*targetport:portfacing:vector, targetport:portfacing:topvector).
lock steering to steering_vector.

move_to_corner(targetport, shipport, steering_vector).

approach_port(targetport, shipport, 100, 2, 2, steering_vector).
approach_port(targetport, shipport, 20, 2, 0.5, steering_vector).
approach_port(targetport, shipport, 10, 0.5, 0.1, steering_vector).
approach_port(targetport, shipport, 1, 0.4, 0.1, steering_vector).
approach_port(targetport, shipport, 0, 0.25, 0.1, steering_vector).

if (shipport:state <> "Ready") print "Successfully Docked".
RCS off.
unlock steering.
SAS on.