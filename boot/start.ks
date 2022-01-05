local closeButton is 0.
local pth is "0:".
cd(pth).

local cont is false.
if (ship:status = "prelaunch") set cont to true.
if not cont {
    lock inp to terminal:input:getchar().
    print "Hit 'l' continue start script".
    wait until inp = "l".
}

list files in fileslist.
local dirs is list().
for f in fileslist {
    if (not f:isfile) {
        if (f:name[0] <> ".") dirs:add(f).
    }
}

local directory is "".
local bpressed1 is false.

local gui1 is gui(200, dirs:length+3).
set gui1:x to -250.
set gui1:y to 200.
local label1 is gui1:addlabel("Select Directory").
set label1:style:align to "center".
set label1:style:hstretch to true.
for d in dirs {
    local b is gui1:addbutton(d:name).
    set b:onclick to {
        set directory to b:text.
        set bpressed1 to true.
    }.
}
set closeButton to gui1:addbutton("Close").
set closeButton:onclick to {clearguis().}.
gui1:show().
wait until bpressed1.
clearguis().

set pth to pth + "/" + directory.
cd(pth).
clearscreen.

list files in fileslist.

local file is "".
local bpressed2 is false.

local gui2 is gui(200, fileslist:length+3).
set gui2:x to -250.
set gui2:y to 200.
local label2 is gui2:addlabel("Select File from " + directory).
set label2:style:align to "center".
set label2:style:hstretch to true.
for f in fileslist {
    local b is gui2:addbutton(f:name).
    set b:onclick to {
        set file to b:text.
        set bpressed2 to true.
    }.
}
set closeButton to gui2:addbutton("Close").
set closeButton:onclick to {clearguis().}.
gui2:show().
wait until bpressed2.
clearguis().


set pth to pth + "/" + file.
core:part:getmodule("kosprocessor"):doevent("open terminal").
clearscreen.
print("Running " + pth).
runpath(pth).