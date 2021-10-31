function throttle_balance
{    
    list engines in engs.

    local total_torque is V(0, 0, 0).

    local torques is list().
    for eng in engs
    {
        torques:add(0).
    }

    local i is 0.
    until i = engs:length
    {
        set thrust to engs[i]:facing:forevector * engs[i]:maxthrust * engs[i]:thrustlimit / 100.
        set torques[i] to VCRS(thrust, engs[i]:position).
        set i to i + 1.
    }

    set i to 0.
    until (i = torques:length)
    {
        set total_torque to total_torque + torques[i].
        set i to i + 1.
    }
        
    // get engine with lowest angle to current torque, and reduce it's throttle
    set lowestAngle to 360.
    set lowestEngine to 0.
    set i to 0.
    until i = engs:length
    {
        set angle to arccos(total_torque * torques[i] / (total_torque:MAG *  torques[i]:MAG)).
        if angle < lowestAngle
        {
            set lowestAngle to angle.
            set lowestEngine to i.
        }
        set i to i+1.
    }

    set factor to 1 - (total_torque:mag / (torques[lowestEngine]:mag * cos(lowestAngle))).
    set engs[lowestEngine]:thrustlimit to engs[lowestEngine]:thrustlimit * factor.

    return.
}