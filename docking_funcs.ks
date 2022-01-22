function dock_vessels
{
    parameter target_port_name, ship_port_name is "docker".

    print "Docking Vessels".

    list engines in ship_engines.
    for en in ship_engines
    {
        en:shutdown.
    }
    RCS on.

    lock steering to lookdirup(ship:facing:forevector, ship:facing:topvector).

    set steeringmanager:maxstoppingtime to 0.5.

    // // leave_keepout().
    kill_relative_velocity().
    
    local targetport is assign_ports(target_port_name, target).
    local shipport is assign_ports(ship_port_name, ship).
    set targetport to check_ports_match(targetport, shipport).
    shipport:controlfrom().

    print "Aligning Steering".
    local steering_vector is lookdirup(-1*targetport:portfacing:vector, targetport:portfacing:starvector).
    if (target_port_name = "star_jnr_lwr") set steering_vector to lookdirup(-1*targetport:portfacing:vector, -1*targetport:portfacing:starvector).
    lock steering to steering_vector.

    move_to_radius(targetport, steering_vector).
    set target to targetport.

    retract_solar_panels().
    approach_port(targetport, shipport, 100, 2, 10, 90, steering_vector).
    approach_port(targetport, shipport, 20, 2, 0.5, 5, steering_vector).
    approach_port(targetport, shipport, 10, 0.5, 0.1, 2, steering_vector).
    approach_port(targetport, shipport, 5, 0.4, 0.1, 2, steering_vector).
    approach_port(targetport, shipport, 1, 0.25, 0.1, 2, steering_vector).
    approach_port(targetport, shipport, 0, 0.25, 0.1, 2, steering_vector).

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
    print "Killing Relative Velocity".

    set relative_vel to ship:velocity:orbit - target:velocity:orbit.
    until relative_vel:mag < 0.2
    {
        set relative_vel to ship:velocity:orbit - target:velocity:orbit.
        translate(-relative_vel).
    }
    translate(V(0,0,0)).
}

function assign_ports
{
    parameter port_name, orbitable.

    local tp is "x".
    until false {
        for dp in orbitable:dockingports {
            if (dp:tag = port_name) {
                set tp to dp.
                break.
            }
        }
        if (tp = "x") {
            print "Choose the docking port for " + orbitable:name.
            set port_name to choose_docking_port(orbitable, "docking", orbitable:name).
        }
        else break.
    }
    return tp.
}

function check_ports_match
{
    parameter target_port, ship_port.

    until false {
        if (target_port:nodetype = ship_port:nodetype) return target_port.
        print "Target Port Doesn't Match Ship Docking Port".
        print "Choose A New Port".
        local tp is choose_docking_port(target, "docking", "target").
        set target_port to assign_ports(tp, target).
    }
}

function leave_keepout
{
    parameter speed is 4.

    print "Leaving 200m Keep Out Sphere".
    local target_radius is 200.

    lock steering to lookdirup(ship:facing:forevector, ship:facing:topvector).

    until false
    {
        set dist to ship:position - target:position.
        set move_vector to (dist:normalized * target_radius) - dist.
        set relative_vel to ship:velocity:orbit - target:velocity:orbit.
        translate(move_vector:normalized * speed - relative_vel).
        if (dist:mag > target_radius) break.
        if (dist:mag > 180) set speed to 1.
        wait 0.01. 
    }
    translate(V(0,0,0)).
}

function move_to_radius
{
    parameter targetport, steering_vector.

    local min_dist is 1000000.
    local min_val is list().

    local forevect is targetport:portfacing:vector:normalized.
    local starvect is targetport:portfacing * R(90, 0, 0).
    set starvect to starvect:vector.
    local topvect is targetport:portfacing * R(0, 90, 0).
    set topvect to topvect:vector.
    local star_d is "x".
    local top_d is "x".

    local v1 is 0.
    until (v1 > 1)
    {
        if (v1=0) set star_d to 1.
        else set star_d to -1.

        local v2 is 0.
        until (v2 > 1)
        {
            if (v2=0) set top_d to 1.
            else set top_d to -1.

            local value is 0.
            until (value > 1)
            {
                local circle_pos is 150 * (forevect + (value*top_d*topvect + sqrt(1.0-value*value)*star_d*starvect)).
                
                local circle_dist is target:position + circle_pos - ship:position.
                if (circle_dist:mag < min_dist)
                {
                    set min_dist to circle_dist:mag.
                    min_val:clear().
                    min_val:add(value).
                    min_val:add(top_d).
                    min_val:add(star_d).
                }

                set value to value + 1/20.
            }
            set v2 to v2 + 1.
        }
        set v1 to v1 + 1.
    }   

    local init_speed is 4.
    lock steering to steering_vector.

    until false
    {
        local circle_pos is 150 * (forevect + (min_val[0]*min_val[1]*topvect + sqrt(1.0-min_val[0]*min_val[0])*min_val[2]*starvect)).
        local app_vect is target:position + circle_pos - ship:position.
        set dist to ship:position - app_vect.
        set move_vector to target:position - ship:position + app_vect.
        set relative_vel to ship:velocity:orbit - targetport:ship:velocity:orbit.
        local speed is set_speed(move_vector, init_speed).
        translate(move_vector:normalized * speed - relative_vel).
        clearscreen.
        print "Moving to Nearest Approach Corner".
        print round(move_vector:mag, 2).
        if (move_vector:mag < 20) break.
        wait 0.01.
    }
    translate(V(0,0,0)).
}

function approach_port
{
    parameter targetport, shipport, distance, init_speed, dist_error, ang_error, steering_vector.

    local speed is init_speed.
    lock steering to steering_vector.

    until false
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
        if (move_vector:mag < dist_error and vang(shipport:portfacing:vector, dvect) < ang_error) break.
        if (shipport:state <> "Ready" and shipport:state <> "Preattached") break.
        wait 0.01.
    }
    translate(V(0,0,0)).
}

function set_speed
{
    parameter vector, speed.
    if (speed <= 0.5) return 0.5.
    
    if (vector:mag < 150) set speed to 2.
    if (vector:mag < 10) set speed to 0.5.
    else if (vector:mag < 20) set speed to 1.
    
    return speed.
}


function choose_docking_port {

    parameter orbitable, mode, message.

    local val is "".
    until false {
        local bpressed is false.
        local gui is gui(200).
        set gui:x to -250.
        set gui:y to 200.
        local label is gui:addlabel("Select " + message + " " + mode + " port").
        set label:style:align to "center".
        set label:style:hstretch to true.
        for port in orbitable:dockingports {
            local check is false.
            if (mode = "docking" and port:state = "ready") set check to true.
            if (mode = "undocking" and port:state <> "ready") set check to true.
            if (check and port:tag:length > 0) {
                local b is gui:addbutton(port:tag).
                set b:onclick to {
                    set bpressed to true.
                    set val to b:text.
                }.
            }
        }
        local reset is gui:addbutton("Reset").
        set reset:onclick to {set bpressed to true.}.
        gui:show().
        wait until bpressed.
        clearguis().
        if (val:length > 0) return val.
    }
}

function undock_leave
{
    parameter leave_time is 10, wait_time is 10.

    local bpressed is false.
    local cancelUndock is false.
    local gui is gui(200).
    set gui:x to -250.
    set gui:y to 200.
    local label is gui:addlabel("Choose Option: ").
    set label:style:align to "center".
    set label:style:hstretch to true.
    local b1 is gui:addbutton("Undock").
    set b1:onclick to {set bpressed to true.}.
    local b2 is gui:addbutton("Continue Without Undocking").
    set b2:onclick to {
        set cancelUndock to true.
        set bpressed to true.
        }.
    gui:show().
    wait until bpressed.
    clearguis().
    if cancelUndock return.

    local leave_port is choose_docking_port(ship, "undocking", "ship").

    local dp is assign_ports(leave_port, ship).

    if (dp:state = "ready") return.

    local targetport is dp:partner().
    dp:undock().
    if (kuniverse:activevessel <> core:vessel)
    {
        kuniverse:forcesetactivevessel(core:vessel).
    }
    lock steering to lookdirup(ship:facing:forevector, ship:facing:topvector).
    wait 0.5.

    print "Leaving via RCS".
    SAS off.
    RCS on.
    local rcs_vect is targetport:portfacing:vector.
    local t0 is time:seconds.
    until false
    {
        translate(rcs_vect).
        if (time:seconds > t0 + leave_time) break.
    }
    RCS off.
    wait wait_time.
    activate_engines().
}