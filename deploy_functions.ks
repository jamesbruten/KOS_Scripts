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
    print "Extending Solar Panels".
    for p in ship:parts
    {
        if p:hasmodule("moduledeployablesolarpanel")
        {
            local panel is p:getmodule("moduledeployablesolarpanel").
            if panel:hasevent("extend solar panel") panel:doevent("extend solar panel").
        }
    }
}

function deploy_antenna
{
    print "Extending Antenna".
    for p in ship:parts
    {
        if p:hasmodule("moduledeployableantenna")
        {
            local dish is p:getmodule("moduledeployableantenna").
            if dish:hasevent("extend antenna") dish:doevent("extend antenna").
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
        } 
    }

    lock throttle to 0.
    list engines in ship_engines.
    for en in ship_engines
    {
        en:activate().
    }
}