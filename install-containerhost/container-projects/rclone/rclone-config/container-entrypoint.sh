#!/bin/sh

if [ ! -f /usr/bin/sleep ];
then

    apk update
    apk add coreutils bash bash-completion

    # creates completion file on the filesystem
    rclone completion bash

fi;


while true;
do
    sleep "$RCLONE_SLEEP"
    sleep infinity
done;

# TODO
# - check if RCLONE_env vars are coming through as expected
# - check if rclone env for command is not null or empty
# - check for rclone.conf existence
# - write example sync command 