#!/usr/bin/bash

set -x

python -m venv .venv
. ./.venv/bin/activate

python -m pip install --upgrade pip
pip install --requirement requirements.txt
pip list --outdated

ansible --version

echo "Update the dependencies by running 'pip freeze --local --requirement requirements.txt >requirements.txt' inside the virtual env"

deactivate
