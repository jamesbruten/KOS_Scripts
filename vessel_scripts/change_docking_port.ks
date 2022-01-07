@lazyglobal off.
runpath("0:/boot/load_scripts.ks").

local target_port_name is "star_jnr_upr".
local leave_port is "undocker".

undock_leave(3, 5, leave_port).

local target_list is list().
list targets in target_list.
local ind is target_list:length-1.
until (ind < 0)
{
    local t is target_list[ind].
    local dist is ship:position - t:position.
    if (dist:mag > 1000) target_list:remove(ind).
    set ind to ind - 1.
}

local inp is 10000.
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
        print "Choose Target".
        terminal:input:clear().
        set inp to terminal:input:getchar().
        set inp to inp:tonumber().
        if (inp < target_list:length) break.
    }
}

local gui is gui(200).
set gui:x to -250.
set gui:y to 200.
local label is gui:addlabel("Select " + command).
set label:style:align to "center".
set label:style:hstretch to true.
local bpressed is false.
for t in target_list {
    local b is gui:addbutton(t:name).
    set b:onclick to {
        print "Setting Target Vessel to " + b:text.
        set target to b:text.
        set bpressed to true.
    }.
}
set closeButton to gui:addbutton("Close").
set closeButton:onclick to {clearguis().}.
gui:show().
wait until bpressed.
clearguis().

dock_vessels(target_port_name).