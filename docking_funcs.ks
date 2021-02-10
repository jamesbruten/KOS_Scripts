function dock_vessels
{
    print "Docking Vessels".

    list engines in ship_engines.
    for en in ship_engines
    {
        en:shutdown.
    }
    RCS on.
    
    local targetport is get_target_port().
    local shipport is ship:dockingports[0].

    // kill_relative_velocity(targetport).

    print "Pointing in line with Target Port".
    lock steering to lookdirup(-1*targetport:portfacing:vector, north:vector).

    leave_keepout(targetport).

    move_to_corner(targetport, shipport).

    approach_port(targetport, shipport, 100, 2, 4, 2).
    approach_port(targetport, shipport, 10, 2, 2, 0.1).
    approach_port(targetport, shipport, 2, 1, 2, 0.1).
    approach_port(targetport, shipport, 1, 0.5, 2, 0.1).
    approach_port(targetport, shipport, 0, 0.25, 1, 0.1).

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

    lock relative_vel to ship:velocity:orbit - targetport:ship:velocity:orbit.
    until relative_vel:mag < 0.1
    {
        translate(-relative_vel).
    }
    translate(V(0,0,0)).
}

function get_target_port
{
    if (target:dockingports:length <> 0)
    {
        for dp in target:dockingports
        {
            if (dp:tag = "target_dp") return dp.
        }
    }
}

function leave_keepout
{
    parameter targetport.
    print "Leaving Keep Out Sphere".
    local target_radius is 200.
    local speed is 2.

    lock dist to ship:position - targetport:ship:position.
    lock move_vector to (dist:normalized * target_radius) - dist.
    lock relative_vel to ship:velocity:orbit - targetport:ship:velocity:orbit.
    lock steering to lookdirup(-1*targetport:portfacing:vector, north:vector).

    until (dist:mag > 200)
    {
        translate(move_vector:normalized * speed - relative_vel).
        wait 0.01. 
    }
    translate(V(0,0,0)).
}

function move_to_corner
{
    parameter targetport, shipport.
    print "Moving to Nearest Approach Corner".

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

    local speed is 2.
    lock dist to ship:position - min_vect.
    lock move_vector to targetport:nodeposition - shipport:nodeposition + min_vect.
    lock relative_vel to ship:velocity:orbit - targetport:ship:velocity:orbit.
    lock steering to lookdirup(-1*targetport:portfacing:vector, north:vector).

    until false
    {
        translate(move_vector:normalized * speed - relative_vel).
        set speed to set_speed(targetport:nodeposition - shipport:nodeposition + min_vect).
        if (move_vector:mag < 1) break.
        wait 0.01.
    }
    translate(V(0,0,0)).
}

function approach_port
{
    parameter targetport, shipport, distance, speed, ang_error, dist_error.

    print "Approaching to Target Port + " + distance + " at Speed: " + speed.

    shipport:controlfrom().

    lock offset to targetport:portfacing:vector * distance.
    lock move_vector to targetport:nodeposition - shipport:nodeposition + offset.
    lock relative_vel to ship:velocity:orbit - targetport:ship:velocity:orbit.
    lock steering to lookdirup(-1*targetport:portfacing:vector, north:vector).

    until shipport:state <> "Ready"
    {
        translate(move_vector:normalized * speed - relative_vel).
        local dist is targetport:nodeposition - shipport:nodeposition.
        if (distance > 50) set speed to set_speed(targetport:nodeposition - shipport:nodeposition + offset).
        if (vang(shipport:portfacing:vector, dist)<ang_error and abs(dist - distance)<dist_error) break.
        wait 0.01.
    }
    translate(V(0,0,0)).
}

function set_speed
{
    parameter vector.
    
    local speed is 2.

    if (vector:mag < 10) set speed to 0.5.
    else if (vector:mag < 20) set speed to 1.
    
    return speed.
}