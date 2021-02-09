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

    kill_relative_velocity(targetport).

    print "Pointing in line with Target Port".
    lock steering to lookdirup(-1*targetport:portfacing:vector, north:vector).

    print "Docking Complete".
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
        print relative_vel:mag.
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
    
}