runpath("0:/boot/load_scripts.ks").

local port_name is "tug_jnr".

undock_leave(2, 0).

local inp is "x".
list targets in target_list.

if (target_list:length = 1) set inp to 0.
else
{
    until false
    {
        local index is 0.
        for t in target_list
        {
            print index + "   " + t:name.
            set index to index + 1.
        }
        lock inp to terminal:input:getchar().
        wait until inp <> "x".
        if (inp < index) break.
    }
}

print "Setting Target Vessel to " + target_list[inp]:name.
set target to target_list[inp].

dock_vessels().