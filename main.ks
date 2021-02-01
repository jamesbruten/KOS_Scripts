function main
{
    

    // Deploy Payload
    print "Deploying Payload".
    wait 10.
    autostage().

    wait 10.
    deploy_antenna().
    wait 3.
    deploy_solar_panels().
    wait 20.


    // Check apoapsis against desired height
    // If difference > 1km perform new burn at periapsis
    if (ship:apoapsis < target_ap-1000 or ship:apoapsis > target_ap+1000)
    {
        print "Performing Burn to adjust apoapsis".
        set burn_time to create_mnv("p").
        execute_mnv(burn_time).
        list engines in ship_engines.
        for en in ship_engines
        {
            set en:thrustlimit to 100.
        }
    }
    else print "No apoapsis adjustment required".

    wait until false.
}