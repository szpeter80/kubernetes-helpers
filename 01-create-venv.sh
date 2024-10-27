#!/usr/bin/bash

ENVFILE="$1"
DEBUG=0
VENV_DIR='./.venv'

if [ -f "${ENVFILE}" ];
then
    echo "Sourcing environment file: ${ENVFILE}"
    # shellcheck disable=SC1090
    source "${ENVFILE}"
else
    echo "Environment file (${ENVFILE}) not found, using defaults"
fi

if [ "${DEBUG}" = "1" ];
then
    set -x
fi

if [ -d "${VENV_DIR}" ];
then
    echo "Virtual environment directory (${VENV_DIR}) already exists, exiting ..."
    exit 0
fi

python -m venv "${VENV_DIR}"
# shellcheck disable=SC1091
. "${VENV_DIR}"/bin/activate

python -m pip install --upgrade pip

if [ -f requirements.txt ];
then
    pip install --requirement requirements.txt
fi

pip list --outdated

echo "Update the dependencies by running 'pip freeze --local --requirement requirements.txt >requirements.txt' inside the virtual env"

deactivate
