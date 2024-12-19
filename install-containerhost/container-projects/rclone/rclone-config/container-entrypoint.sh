#!/bin/sh
# We are PID 1 so lets behave responsibly
# - set up TERM signal handlers and take care of all processes we started
# - run programs in the background because shell does not process signals 
#   if a foreground process is running 
# - check in the main loop if we need to exit


_term() {

  TERM_RECEIVED="Y"
  date
  
  echo "ENTRYPOINT: starting process shutdown" 
  killall -TERM sleep 2>/dev/null
  killall -TERM rclone 2>/dev/null
  
  echo "ENTRYPOINT: signals sent, waiting for subprocesses to exit"
  wait
  
  echo "ENTRYPOINT: all processes have finished"
}

trap _term HUP INT QUIT TERM

###############################################################################

TERM_RECEIVED="N"

echo 
echo "ENTRYPOINT: starting up the container"

if [ ! -f /bin/sleep ];
then

    echo "ENTRYPOINT: starting initial system configuration"

    apk update
    apk add coreutils bash bash-completion nano

    # creates completion file on the filesystem
    rclone completion bash

fi;

if [ ! -f /config/rclone/rclone.conf ];
then

    echo "ERROR: rclone config (/config/rclone/rclone.conf) not found !"
    echo "Please create by executing 'podman exec -ti rclone_rclone_svc_1 /bin/bash -c \"rclone config\"' "
    echo "After saving , update RCLONE_CMD environment variable to suit your need and restart this container"
    echo "Sleeping now for infinity..."

    sleep infinity
    exit 1
fi;


while true;
do


	if [[ "${TERM_RECEIVED}" == "Y" ]]; then
	  echo "ENTRYPOINT: termination request received in main loop, exiting"
	  date
	  exit 0
	fi
	
    DT="$(date '+%Y-%m-%d_%H%M')"
      
    BDIR=$(dirname "${RCLONE_REPORT_FN}")
    BFN=$(basename "${RCLONE_REPORT_FN}")
    REPORT_FN="${BDIR}/${DT}--${BFN}" 

    echo "$(date '+%Y-%m-%d %H:%M')    executing rclone" | tee -a "${REPORT_FN}"
    echo "$(date '+%Y-%m-%d %H:%M')    RCLONE_CMD= $RCLONE_CMD" | tee -a "${REPORT_FN}"
    echo >> "${REPORT_FN}"
    
    # combined report truncates the file so we need to use stdout and redirect to append to it
    { ${RCLONE_CMD} --combined - >> "${REPORT_FN}" && touch "${RCLONE_HEARTBEAT_FN}"; } &
    wait $!
    
    
    echo "$(date '+%Y-%m-%d %H:%M')    execution finished" | tee -a "${REPORT_FN}"
    echo

    # safety sleep, to avoid extreme load generation if RCLONE_SLEEP is missing or malformed
    { sleep "${RCLONE_SLEEP}"  ||  sleep 5 ; } &
    wait $!
done;
