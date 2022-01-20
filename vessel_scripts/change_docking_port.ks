@lazyglobal off.
runpath("0:/boot/load_scripts.ks").

local leave_port is "undocker".

undock_leave(3, 5).

local target_list is list().
list targets in target_list.
local ind is target_list:length-1.
until (ind < 0)
{
    local t is target_list[ind].
    local dist is ship:position - t:position.
    if (dist:mag > 2000) target_list:remove(ind).
    set ind to ind - 1.
}

local gui is gui(200).
set gui:x to -250.
set gui:y to 200.
local label is gui:addlabel("Select Target Vessel").
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
local closeButton is gui:addbutton("Close").
set closeButton:onclick to {clearguis().}.
gui:show().
wait until bpressed.
clearguis().

local ship_port_name is choose_docking_port(ship, "docking", "ship").
local target_port_name is choose_docking_port(target, "docking", "target").

SAS off.

dock_vessels(target_port_name, ship_port_name).