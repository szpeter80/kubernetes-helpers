#!/bin/bash

SELF_REAL_FN="$(readlink -en "$0")"
DEFAULT_ENV_REALPATH="$(cd "$(dirname -- "$SELF_REAL_FN")" || exit 1 >/dev/null; pwd -P)/default.env"

# shellcheck disable=SC1090
. "$DEFAULT_ENV_REALPATH"

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


###############################################################################


if [ -d "${VENV_DIR}" ];
then
    echo "Virtual environment directory (${VENV_DIR}) already exists, exiting ..."
    exit 0
fi

$PYTHON_EXECUTABLE_PATH -m venv "${VENV_DIR}"
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
