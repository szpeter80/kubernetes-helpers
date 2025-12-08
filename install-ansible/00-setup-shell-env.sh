#!/bin/bash

DEFAULT_ENV_REALPATH="./default.env"

if [ ! -f "$DEFAULT_ENV_REALPATH" ];
then
    echo "ERROR: Default environment file not found: $DEFAULT_ENV_REALPATH"
    exit 1
fi

source "$DEFAULT_ENV_REALPATH"

if [ "${DEBUG}" = "1" ];
then
    set -x
fi
