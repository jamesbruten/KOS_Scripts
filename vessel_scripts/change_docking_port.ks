@lazyglobal off.
runpath("0:/boot/load_scripts.ks").

local leave_port is "undocker".

undock_leave(3, 5, leave_port).

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

local dlist is list().
local dlist1 is target:dockingports.
for d in target:dockingports {
    local check is true.
    if (d:state <> "ready") set check to false.
    if (d:tag:length = 0) set check to false.
    if check dlist:add(d).
}

local target_port_name is "".
set gui to gui(200).
set gui:x to -250.
set gui:y to 200.
set label to gui:addlabel("Select Target Docking Port").
set label:style:align to "center".
set label:style:hstretch to true.
set bpressed to false.
for d in dlist {
    local b is gui:addbutton(d:tag).
    set b:onclick to {
        print "Setting Target Port to " + b:text.
        set target_port_name to b:text.
        set bpressed to true.
    }.
}
set closeButton to gui:addbutton("Close").
set closeButton:onclick to {clearguis().}.
gui:show().
wait until bpressed.
clearguis().

SAS off.

dock_vessels(target_port_name).