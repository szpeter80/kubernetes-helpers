#!/bin/bash

SELF_REAL_FN="$(readlink -en "$0")"
DEFAULT_ENV_REALPATH="$(cd "$(dirname -- "$SELF_REAL_FN")" || exit 1 >/dev/null; pwd -P)/default.env"

if [ -f "$DEFAULT_ENV_REALPATH" ];
then
    echo "Sourcing default environment file: $DEFAULT_ENV_REALPATH"
    # shellcheck disable=SC1090
    source "$DEFAULT_ENV_REALPATH"
else
    echo "Default environment file not found: $DEFAULT_ENV_REALPATH"
fi


ENVFILE="$1"
if [ -f "${ENVFILE}" ];
then
    echo "Sourcing environment file: ${ENVFILE}"
    # shellcheck disable=SC1090
    source "${ENVFILE}"
else
    echo "Environment file (${ENVFILE}) not found, using defaults from $DEFAULT_ENV_REALPATH"
fi

if [ "${DEBUG}" = "1" ];
then
    set -x
fi
