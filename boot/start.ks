local default_height is terminal:height.
local pth is "0:".
cd(pth).
clearscreen.
print(pth).

list files in fileslist.
local dirs is list().
for f in fileslist {
    if (not f:isfile) dirs:add(f).
}

if (terminal:height < dirs:length+3) set terminal:height to dirs:length + 3.

local ind is 0.
print "Select Directory:".
for d in dirs {
    print "Option " + ind + ":   " + d:name.
    set ind to ind + 1.
}

local inp is 0.
until false {
    terminal:input:clear().
    set inp to terminal:input:getchar().
    set inp to inp:tonumber(-999).
    if (inp > 0 and inp < dirs:length) break.
}

set pth to pth + "/" + dirs[inp].
cd(pth).
clearscreen.
print(pth).

list files in fileslist.
if (terminal:height < fileslist:length+3) set terminal:height to fileslist:length + 3.

set ind to 0.
print "Select File to Run:".
for f in fileslist {
    if f:extension = "ks" {
        print "Option " + ind + ":   " + f:name.
        set ind to ind + 1.
    }
}

set inp to 0.
until false {
    terminal:input:clear().
    set inp to terminal:input:getchar().
    set inp to inp:tonumber(-999).
    if (inp > 0 and inp < fileslist:length) break.
}

set terminal:height to default_height.

set pth to pth + "/" + fileslist[inp].
clearscreen.
print("Running " + pth).
runpath(pth).