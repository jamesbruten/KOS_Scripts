function dock_vessels
{
    print "Docking Vessels".

    list engines in ship_engines.
    for en in ship_engines
    {
        en:shutdown.
    }
    RCS on.
    
    local targetport is get_target_port("target_dp").
    local shipport is assign_ports("docker").
    shipport:controlfrom().

    kill_relative_velocity(targetport).
    leave_keepout(targetport, 2).

    print "Aligning Steering".
    local steering_vector is lookdirup(-1*targetport:portfacing:vector, targetport:portfacing:starvector).
    lock steering to steering_vector.

    move_to_corner(targetport, shipport,steering_vector).

    retract_solar_panels().
    approach_port(targetport, shipport, 100, 2, 2, steering_vector).
    approach_port(targetport, shipport, 20, 2, 0.5, steering_vector).
    approach_port(targetport, shipport, 10, 0.5, 0.1, steering_vector).
    approach_port(targetport, shipport, 1, 0.4, 0.1, steering_vector).
    approach_port(targetport, shipport, 0, 0.25, 0.1, steering_vector).

    if (shipport:state <> "Ready") print "Successfully Docked".
    RCS off.
    unlock steering.
    SAS on.
}

function translate
{
    parameter vector.
    if (vector:mag > 1) set vector to vector:normalized.

    set ship:control:fore to vector * ship:facing:forevector.
    set ship:control:starboard to vector * ship:facing:starvector.
    set ship:control:top to vector * ship:facing:topvector.
}

function kill_relative_velocity
{
    parameter targetport.

    print "Killing Relative Velocity".

    set relative_vel to ship:velocity:orbit - targetport:ship:velocity:orbit.
    until relative_vel:mag < 0.1
    {
        set relative_vel to ship:velocity:orbit - targetport:ship:velocity:orbit.
        translate(-relative_vel).
    }
    translate(V(0,0,0)).
}

function get_target_port
{
    parameter port_name.
    if (target:dockingports:length <> 0)
    {
        for dp in target:dockingports
        {
            if (dp:tag = port_name) return dp.
        }
    }
}

function assign_ports
{
    parameter port_name.

    local tp is "x".
    until false
    {
        for dp in ship:dockingports
        {
            if (dp:tag = port_name)
            {
                set tp to dp.
                break.
            }
        }
        if (tp = "x")
        {
            print "Change Ship DP tag to " + port_name.
            print "Hit 'l' when done".
            lock inp to terminal:input:getchar().
            wait until inp = "l".
        }
        else break.
    }
    return tp.
}

function leave_keepout
{
    parameter targetport, speed.


    print "Leaving Keep Out Sphere".
    local target_radius is 200.

    lock steering to north:vector.

    until false
    {
        set dist to ship:position - targetport:ship:position.
        set move_vector to (dist:normalized * target_radius) - dist.
        set relative_vel to ship:velocity:orbit - targetport:ship:velocity:orbit.
        translate(move_vector:normalized * speed - relative_vel).
        if (dist:mag > target_radius) break.
        wait 0.01. 
    }
    translate(V(0,0,0)).
}

function move_to_corner
{
    parameter targetport, shipport, steering_vector.

    local ax_dist is 100.
    
    local min_dist is 10000.
    local min_vect is "x".
    local min_d1 is "x".
    local min_d2 is "x".
    local min_d3 is "x".

    local forevect is targetport:portfacing:vector.
    local starvect is targetport:portfacing * R(90, 0, 0).
    set starvect to starvect:vector.
    local topvect is targetport:portfacing * R(0, 90, 0).
    set topvect to topvect:vector.

    from{local d2 is -1*ax_dist.} until d2 > ax_dist step{set d2 to d2 + 2*ax_dist.} do
    {
        from{local d3 is -1*ax_dist.} until d3 > ax_dist step{set d3 to d3 + 2*ax_dist.} do
        {
            local c_pos is forevect*ax_dist + starvect*d2 + topvect*d3.
            local c_dist is ship:position - c_pos.
            if (c_dist:mag < min_dist)
            {
                set min_dist to c_dist:mag.
                set min_vect to c_pos.
            }
        }
    }

    local init_speed is 2.
    lock steering to steering_vector.

    until false
    {
        set dist to ship:position - min_vect.
        set move_vector to targetport:nodeposition - shipport:nodeposition + min_vect.
        set relative_vel to ship:velocity:orbit - targetport:ship:velocity:orbit.
        local speed is set_speed(move_vector, init_speed).
        translate(move_vector:normalized * speed - relative_vel).
        clearscreen.
        print "Moving to Nearest Approach Corner".
        print round(move_vector:mag, 2).
        if (move_vector:mag < 2) break.
        wait 0.01.
    }
    translate(V(0,0,0)).
}

function approach_port
{
    parameter targetport, shipport, distance, init_speed, dist_error, steering_vector.

    local speed is init_speed.
    lock steering to steering_vector.

    until shipport:state <> "Ready"
    {
        set offset to targetport:portfacing:vector * distance.
        set move_vector to targetport:position - shipport:position + offset.
        set relative_vel to ship:velocity:orbit - targetport:ship:velocity:orbit.
        if (distance > 5) set speed to set_speed(move_vector, init_speed).
        translate(move_vector:normalized * speed - relative_vel).
        local dvect is targetport:position - shipport:position.
        clearscreen.
        print "Approaching Target Port + " + distance + " at Speed: " + init_speed.
        print round(move_vector:mag, 2).
        print round(vang(shipport:portfacing:vector, dvect), 2).
        if (move_vector:mag < dist_error and vang(shipport:portfacing:vector, dvect) < 2) break.
        wait 0.01.
    }
    translate(V(0,0,0)).
}

function set_speed
{
    parameter vector, speed.
    if (speed <= 0.5) return 0.5.
    
    if (vector:mag < 10) set speed to 0.5.
    else if (vector:mag < 20) set speed to 1.
    
    return speed.
}

function kss_tug_move
{
    parameter time_depart, dir_depart.
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
    set ship:control:fore to dir_depart.
    wait time_depart.
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
}

function undock_leave
{
    parameter leave_time is 20, wait_time is 10.

    lock inp1 to terminal:input:getchar().
    print "Hit 'u' to undock or 'c' to continue without undocking".
    wait until inp1 = "c" or inp1 = "u".

    if (inp1 = "c")
    {
        // activate_engines().
        return.
    }

    lock inp to terminal:input:getchar().
    print "Hit 'l' to Undock".
    wait until inp = "l".

    local dp is assign_ports("undocker").

    if (dp:state = "ready") return.

    local targetport is dp:partner().
    dp:undock().
    if (kuniverse:activevessel <> core:vessel)
    {
        kuniverse:forcesetactivevessel(core:vessel).
    }
    wait 1.

    local steering_vector is lookdirup(-1*targetport:portfacing:vector, targetport:portfacing:starvector).
    lock steering to steering_vector.

    print "Leaving via RCS".
    SAS off.
    RCS on.
    set ship:control:fore to -1.
    wait leave_time.
    RCS off.
    wait wait_time.
    activate_engines().
}