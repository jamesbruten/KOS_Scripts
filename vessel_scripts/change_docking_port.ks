runpath("0:/boot/load_scripts.ks").

undock_leave(5, 5).

for p in ship:parts
{
    if (p:tag = "undocker")
    {
        set p:tag to "docker".
        break.
    }
}

print "Select Target Vessel - hit 'l' when done".
lock inp to terminal:input:getchar().
wait until inp = "l".

dock_vessels().