if (auto = false)
{
    lock inp to terminal:input:getchar().
    print "Hit 'l' to launch".
    wait until inp = "l".
}

runpath("0:/vessel_scripts/ship_rendezvous.ks").