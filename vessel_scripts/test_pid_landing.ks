runpath("0:/boot/load_scripts.ks").

lock steering to heading(0, 90, 0).
stage.
wait 5.

lock throttle to 1.
wait until ship:apoapsis > 12000.
lock throttle to 0.
wait 1.
deploy_fairing().
wait 1.
deploy_payload("payload").
wait 1.
activate_engines().
lock throttle to 1.
wait 2.
lock throttle to 0.

wait until ship:verticalspeed < 0.

gear on.
pid_landing().