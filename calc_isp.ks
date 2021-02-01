// calculate current isp

function calc_current_isp
{
    // Calculate stage isp
    // list engines and select engines that have beeen ignited but not flamed out
    // add on engine isp weighted by engine thrust / ship thrust

    local isp is 0.
    list engines in ship_engines.
    for en in ship_engines
    {
        if en:ignition and not en:flameout
        {
            set isp to isp + en:isp * en:availablethrust / ship:availablethrust. 
        }
    }
    return isp.
}