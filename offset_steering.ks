function offsetSteering
{
    parameter dirtosteer.              // The direction you want the ship to steer to

    local newdirtosteer is dirtosteer. // Return value. Defaults to original direction.
    local oss is lexicon(). // Used to store all persistent data
    local trueacc is 0. // Used to store ship acceleration vector

    if exists("oss.json")
    { // Looks for saved data
        set oss to readjson("oss.json"). 
        if (oss["Ship_Name"] <> ship:name:tostring) set oss to initoss().
    }
    else set oss to initoss().

    local dt is time:seconds - oss["t0"].
    if (dt > oss["Average_Interval"])
    {
        // This section takes the average of the offset, resets the average counters and resets the timer.
        set oss["t0"] to TIME:SECONDS.
        if (oss["Average_samples"] > 0)
        {
            // Pitch 
            set oss["pitch_angle"] to oss["pitch_sum"] / oss["Average_samples"]. 
            set oss["pitch_sum"] to oss["pitch_angle"].
            // Yaw
            set oss["yaw_angle"] to oss["yaw_sum"] / oss["Average_samples"]. 
            set oss["yaw_sum"] to oss["yaw_angle"].
            // Sample count
            set oss["Average_samples"] to 1.
            // Increases the Average interval to try to keep the adjusts more smooth.
            if (oss["Average_Interval"] < oss["Average_Interval_Max"]) { 
                set oss["Average_Interval"] to max(oss["Average_Interval_Max"], oss["Average_Interval"]+dt) .
            } 
        }
    }
    else
    { 
        // Accumulate the thrust offset error to be averaged by the section above  
        // exclude the left/right vector to leave only forwards and up/down
        local pitch_error_vec is vxcl(facing:starvector, trueacc).
        local pitch_error_ang is vang(facing:vector, pitch_error_vec).
        // exclude the up/down vector to leave only forwards and left/right
        local yaw_error_vec is vxcl(facing:topvector, trueacc).
        local yaw_error_ang is vang(facing:vector, yaw_error_vec).

        set oss["pitch_sum"] to oss["pitch_sum"] + pitch_error_ang.
        set oss["yaw_sum"] to oss["yaw_sum"] + yaw_error_ang.
        set oss["Average_samples"] to oss["Average_samples"] + 1.
    }
    // Set the return value to original direction combined with the thrust offset
    set newdirtosteer to dirtoSTEER * r(0-oss["pitch_angle"],oss["yaw_angle"],0).

  // Saves the persistent values to a file.
  writejson(oss,"oss.json").
  return newdirtosteer.
}

function initoss
{
    // Initialize persistent data.
    local oss is lexicon().
    oss:add("t0", time:seconds).
    oss:add("pitch_angle", 0).
    oss:add("pitch_sum", 0).
    oss:add("yaw_angle", 0).
    oss:add("yaw_sum", 0).
    oss:add("Average_samples", 0).
    oss:add("Average_Interval", 1).
    oss:add("Average_Interval_Max", 10).
    oss:add("Ship_Name",ship:name:tostring).
    
    return oss.
}