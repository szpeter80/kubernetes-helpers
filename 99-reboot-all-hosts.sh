#!/bin/bash

source ./00-setup-shell-env.sh

###############################################################################


# shellcheck disable=SC1091
. "${VENV_DIR}"/bin/activate


ansible -i ./ansible-inventory.yaml -m reboot --become --verbose -v all

deactivate
