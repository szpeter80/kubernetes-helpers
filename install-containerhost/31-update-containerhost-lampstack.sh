#!/bin/bash

source ./00-setup-shell-env.sh

###############################################################################


# shellcheck disable=SC1091
. "${VENV_DIR}"/bin/activate


if [ ! -f "$ANSIBLE_SSH_KEY" ];
then
  echo "Ansible SSH key file ($ANSIBLE_SSH_KEY) not found, did you forget to create ?"
  exit 1
fi

ansible-playbook -i ./ansible-inventory.yaml  30-install-containerhost-lampstack.yaml --tags update --verbose -v 

deactivate
