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

function deploy_dp_shield
{
    print "Toggling Docking Port Shield".
    for p in ship:parts
    {
        if p:hasmodule("moduleanimategeneric")
        {
            local dp is p:getmodule("moduleanimategeneric").
            if dp:hasevent("open shield") dp:doevent("open shield").
            else if dp:hasevent("close shield") dp:doevent("close shield").
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
}