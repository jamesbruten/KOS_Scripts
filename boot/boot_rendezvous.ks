@lazyglobal off.
core:part:getmodule("KOSProcessor"):doevent("Open Terminal").
runpath("0:/boot/load_scripts.ks").

lock inp to terminal:input:getchar().
if hastarget lock inp to "l".
else {
    print "Ensure Target is Set".
    print "Hit 'l' to launch".
}
wait until inp = "l".

// local tlist is list().
// list targets in tlist.
// local validTargets is list().
// for t in tlist {
//     local check is false.
//     if (t:body = ship:body) set check to true.
//     if (t:body:hasbody) {
//         if (t:body:body = ship:body) set check to true.
//     }
//     if check {
//         print t:type.
//         local dlist is t:dockingports.
//         // if (dlist:length > 0) {
//         //     if (t:apoapsis > 0 and t:periapsis > 0) validTargets:add(t).
//         // }

//     }
// }
// for t in validTargets {
//     print t:name.
// }
// wait until false.

// local gui is gui().
// set gui:x to -250.
// set gui:y to 200.
// local label is gui:addlabel("Selet Target Vessel").
// set label:style:align to "center".
// set label:style:hstretch to true.
// local bpressed is false.
// for t in validTargets {
//     local b is gui:addbutton(t:name).
//     set b:onclick to {
//         set target to t.
//         set bpressed to true.
//     }.
// }
// local cButton is gui:addbutton("Use Current Target").
// set cButton:onclick to {if hastarget set bpressed to true.}.
// gui:show().
// wait until bpressed.
// clearguis().

runpath("0:/vessel_scripts/ship_rendezvous_dock.ks").