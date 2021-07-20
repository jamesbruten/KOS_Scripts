runpath("0:/boot/load_scripts.ks").

local target_port_name is "tug_snr".
local leave_port is "undocker".

// undock_leave(3, 5, leave_port).

list targets in target_list.
local ind is target_list:length-1.
until (ind < 0)
{
    local t is target_list[ind].
    local dist is ship:position - t:position.
    if (dist:mag > 2500) target_list:remove(ind).
    set ind to ind - 1.
}

if (target_list:length = 1) set inp to 0.
else
{
    local inp is 10000.
    until false
    {
        local index is 0.
        for t in target_list
        {
            print index + "   " + t:name.
            set index to index + 1.
        }
        print "Choose Target".
        terminal:input:clear().
        set inp to terminal:input:getchar().
        set inp to inp:tonumber().
        if (inp < target_list:length) break.
    }
}

print "Setting Target Vessel to " + target_list[inp]:name.
set target to target_list[inp].

dock_vessels(target_port_name).