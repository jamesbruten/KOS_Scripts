runpath("0:/boot/load_scripts.ks").
local closeButton is 0.
local goback is 0.
local level is 0.
local fileslist is list().
local pth is "0:".

local cont is false.
if (ship:status = "prelaunch") set cont to true.
if not cont {
    lock inp to terminal:input:getchar().
    print "Hit 'l' continue start script".
    wait until inp = "l".
}
set cont to true.

until false {
    cd(pth).
    local fileslist is list().
    list files in flist.
    local command is "File".
    if (level = 0) {
        local dirs is list().
        for f in flist {
            if (not f:isfile and f:name[0] <> ".") dirs:add(f).
        }
        set fileslist to dirs.
        set command to "Directory".
    }
    else
    {
        for f in flist {
            if (f:name:endswith("ks")) fileslist:add(f).
        }
    }


    local val is "".
    local bpressed is false.
    local lgui is gui(200, fileslist:length+3).
    set lgui:x to -250.
    set lgui:y to 200.
    local label is lgui:addlabel("Select " + command).
    set label:style:align to "center".
    set label:style:hstretch to true.
    for f in fileslist {
        local b is lgui:addbutton(f:name).
        set b:onclick to {
            set val to b:text.
            set bpressed to true.
        }.
    }
    if (level = 1) {
        set goback to lgui:addbutton("go back").
        set goback:onclick to {
            set pth to "0:/".
            set val to "".
            set level to -1.
            set bpressed to true.
        }.
    }
    set closeButton to lgui:addbutton("Close").
    set closeButton:onclick to {clearguis(). set cont to false. break.}.
    lgui:show().
    wait until bpressed.
    clearguis().


    set pth to pth + "/" + val.
    clearscreen.
    set level to level + 1.
    if (level > 1) break.
}

if cont {
    core:part:getmodule("kosprocessor"):doevent("open terminal").
    clearscreen.
    print("Running " + pth).
    runpath(pth).
}