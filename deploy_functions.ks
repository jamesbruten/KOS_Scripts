function deploy_fairing
{
    for p in ship:parts
    {
        if p:hasmodule("moduleproceduralfairing")
        {
            print "Fairing Jettison".
            local decoupler is p:getmodule("moduleproceduralfairing").
            if decoupler:hasevent("deploy") decoupler:doevent("deploy").
        }
    }
}

function deploy_solar_panels
{
    for p in ship:parts
    {
        if p:hasmodule("moduledeployablesolarpanel")
        {
            local panel is p:getmodule("moduledeployablesolarpanel").
            if panel:hasevent("extend solar panel")
            {
                print "Extending Solar Panels".
                panel:doevent("extend solar panel").
                wait 5.
            }
        }
    }
}

function deploy_antenna
{
    for p in ship:parts
    {
        if p:hasmodule("moduledeployableantenna")
        {
            local dish is p:getmodule("moduledeployableantenna").
            if dish:hasevent("extend antenna")
            {
                print "Extending Antenna".
                dish:doevent("extend antenna").
                wait 5.
            }
        }
    }
}

function deploy_dp_shield
{
    for p in ship:parts
    {
        if p:hasmodule("moduleanimategeneric")
        {
            print "Toggling Docking Port Shield".
            local dp is p:getmodule("moduleanimategeneric").
            if dp:hasevent("open shield")
            {
                dp:doevent("open shield").
                wait 5.
            }
            else if dp:hasevent("close shield")
            {
                dp:doevent("close shield").
                wait 5.
            }
        }
    }
}

function deploy_payload
{
    // pass name of payload decoupler - need to set this in VAB and adjust script to call
    parameter dname.

    for p in ship:parts
    {
        if (p:tag = dname)
        {
            print "Deploying Payload".
            p:getmodule("moduledecouple"):doevent("decouple").
            wait 5.
        } 
    }
}

function activate_engines
{
    parameter tlimit is 100.

    lock throttle to 0.
    list engines in ship_engines.
    for en in ship_engines
    {
        if not en:ignition en:activate.
        set en:thrustlimit to tlimit.
    }
    wait 5.
}