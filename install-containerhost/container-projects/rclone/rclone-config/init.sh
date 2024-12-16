#!/bin/sh

apk update
apk add coreutils bash bash-completion

# creates completion file on the filesystem
rclone completion bash

