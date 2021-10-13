@lazyglobal off.
runpath("0:/boot/load_scripts.ks").

local inp is 0.
print "Enter Apoapsis Height in km: ".
until false
{
    terminal:input:clear().
    set inp to terminal:input:getchar().
    set inp to inp:tonumber(-9999).
    if (inp <> -9999) break.
}
adjust_apsides("a", inp*1000).

print "Enter Periapsis Height in km: ".
until false
{
    terminal:input:clear().
    set inp to terminal:input:getchar().
    set inp to inp:tonumber(-9999).
    if (inp <> -9999) break.
}
adjust_apsides("p", inp*1000).