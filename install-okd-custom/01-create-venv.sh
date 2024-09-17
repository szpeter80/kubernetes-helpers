#!/usr/bin/bash

if [ -f ./install-okd-custom.env ];
then
    # shellcheck disable=SC1091
    source ./install-okd-custom.env
fi

if [ "${DEBUG}" = "1" ];
then
    set -x
fi

if [ -d ./.venv ];
then
    echo "Virtual environment already exists, exiting ..."
    exit 0
fi

python -m venv .venv
# shellcheck disable=SC1091
. ./.venv/bin/activate

python -m pip install --upgrade pip
pip install --requirement requirements.txt
pip list --outdated

ansible --version

echo "Update the dependencies by running 'pip freeze --local --requirement requirements.txt >requirements.txt' inside the virtual env"

deactivate
