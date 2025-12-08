#!/bin/bash

source ./00-setup-shell-env.sh

###############################################################################


# shellcheck disable=SC1091
source "${VENV_DIR}"/bin/activate


if [ ! -f "$ANSIBLE_SSH_KEY" ];
then
  echo "Ansible SSH key file ($ANSIBLE_SSH_KEY) not found, did you forget to create ?"
fi

ansible -m apt -a "update_cache=yes upgrade=yes" --become --verbose all

deactivate
