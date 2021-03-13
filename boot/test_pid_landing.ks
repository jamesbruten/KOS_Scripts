runpath("0:/boot/load_scripts.ks").

lock steering to heading(270, 70, 0).
stage.
wait 5.

lock throttle to 1.
wait until ship:apoapsis > 12000.
lock throttle to 0.
wait until ship:verticalspeed < 20.
deploy_fairing().
wait 3.
stage.

wait until ship:verticalspeed < 0.

gear on.
pid_landing().