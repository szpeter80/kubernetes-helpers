#!/usr/bin/bash

set -x

python -m venv project-venv
. ./project-venv/bin/activate

pip install --upgrade pip
pip install --requirement requirements.txt

ansible --version


echo "Update the dependencies by running 'pip freeze --local --requirement requirements.txt' inside the virtual env"
deactivate
