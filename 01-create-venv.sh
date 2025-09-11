#!/bin/bash

source ./00-setup-shell-env.sh

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
