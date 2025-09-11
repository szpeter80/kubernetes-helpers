#!/bin/bash

source ./00-setup-shell-env.sh

###############################################################################


# shellcheck disable=SC1091
source "${VENV_DIR}"/bin/activate


if [ ! -f "$ANSIBLE_SSH_KEY" ];
then
  echo "Ansible SSH key file ($ANSIBLE_SSH_KEY) not found, did you forget to create ?"
fi

ansible -i ./ansible-inventory.yaml -m ansible.builtin.dnf -a 'update_cache=true name=* state=latest' --become --verbose -v all

deactivate
