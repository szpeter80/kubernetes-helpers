#!/bin/sh
# TODO: debug why (SIG)TERM at podman pod rm is not working, maybe an exit is missing in _term ?


_term() { 
  echo "Caught SIGTERM signal!" 
  killall -TERM sleep 2>/dev/null
  killall -TERM rclone 2>/dev/null
}

trap _term TERM

###############################################################################

if [ ! -f /usr/bin/sleep ];
then

    apk update
    apk add coreutils bash bash-completion

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
    DT="$(date '+%Y-%m-%d_%H%M')"
      
    BDIR=$(dirname "${RCLONE_REPORT_FN}")
    BFN=$(basename "${RCLONE_REPORT_FN}")
    REPORT_FN="${BDIR}/${DT}--${BFN}" 

    echo "$(date '+%Y-%m-%d %H:%M')    executing rclone" | tee -a "${REPORT_FN}"
    echo "$(date '+%Y-%m-%d %H:%M')    RCLONE_CMD= $RCLONE_CMD" | tee -a "${REPORT_FN}"
    echo >> "${REPORT_FN}"
    # combined report truncates the file so we need to use stdout and redirect to append to it
    ${RCLONE_CMD} --combined - >> "${REPORT_FN}" && touch "${RCLONE_HEARTBEAT_FN}"
    echo "$(date '+%Y-%m-%d %H:%M')    execution finished" | tee -a "${REPORT_FN}"
    echo

    # safety sleep, to avoid extreme load generation if RCLONE_SLEEP is missing or malformed
    sleep "${RCLONE_SLEEP}"  ||  sleep 5
done;
