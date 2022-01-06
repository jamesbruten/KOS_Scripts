local closeButton is 0.
local goback is 0.
local level is 0.
local fileslist is list().
local dirs is list().
local pth is "0:".

local cont is false.
if (ship:status = "prelaunch") set cont to true.
if not cont {
    lock inp to terminal:input:getchar().
    print "Hit 'l' continue start script".
    wait until inp = "l".
}

until false {
    cd(pth).
    list files in fileslist.
    local command is "File".
    if (level = 0) {
        for f in fileslist {
            if (not f:isfile and f:name[0] <> ".") dirs:add(f).
        }
        set fileslist to dirs.
        set command to "Directory".
    }

    local val is "".
    local bpressed is false.
    local gui is gui(200, dirs:length+3).
    set gui:x to -250.
    set gui:y to 200.
    local label is gui:addlabel("Select " + command).
    set label:style:align to "center".
    set label:style:hstretch to true.
    for f in fileslist {
        local b is gui:addbutton(f:name).
        set b:onclick to {
            set val to b:text.
            set bpressed to true.
        }.
    }
    set closeButton to gui:addbutton("Close").
    set closeButton:onclick to {clearguis(). break.}.
    if (level = 1) {
        set goback to gui:addbutton("Go Back").
        set goback:onclick to {
            set pth to "0:/".
            set val to "".
            set level to -1.
        }.
    }
    gui:show().
    wait until bpressed.
    clearguis().


    set pth to pth + "/" + val.
    clearscreen.
    set level to level + 1.
    if (level > 1) break.
}


core:part:getmodule("kosprocessor"):doevent("open terminal").
clearscreen.
print("Running " + pth).
runpath(pth).