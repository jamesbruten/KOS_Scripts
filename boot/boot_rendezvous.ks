@lazyglobal off.
core:part:getmodule("KOSProcessor"):doevent("Open Terminal").
runpath("0:/boot/load_scripts.ks").

local validTypes is list("station", "ship", "plane", "lander", "rover").

local tlist is list().
list targets in tlist.
local validTargets is list().
for t in tlist {
    if not bodyexists(t:name) {
        local check is false.
        if (t:body = ship:body) set check to true.
        if (t:body:hasbody) {
            if (t:body:body = ship:body) set check to true.
        }
        if check {
            if t:hassuffix("type") {
                local vtype is t:type.
                if (validTypes:find(vtype) >= 0 ) {
                    if (t:status = "orbiting") validTargets:add(t).
                }
            }
        }
    }
}

local gui is gui(200).
set gui:x to -250.
set gui:y to 200.
local label is gui:addlabel("Selet Target Vessel").
set label:style:align to "center".
set label:style:hstretch to true.
local bpressed is false.
local tname is 0.
for t in validTargets {
    local b is gui:addbutton(t:name).
    set b:onclick to {
        set tname to b:text.
        set bpressed to true.
    }.
}
local cButton is gui:addbutton("Use Current Target").
set cButton:onclick to {if hastarget set bpressed to true.}.
gui:show().
wait until bpressed.
clearguis().
local tind is validTargets:find(tname).
set target to tname.

lock inp to terminal:input:getchar().
if hastarget lock inp to "l".
else {
    print "Ensure Target is Set".
    print "Hit 'l' to launch".
}
wait until inp = "l".

runpath("0:/vessel_scripts/ship_rendezvous_dock.ks").