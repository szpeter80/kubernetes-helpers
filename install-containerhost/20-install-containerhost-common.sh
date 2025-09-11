#!/bin/bash

source ./00-setup-shell-env.sh

###############################################################################


# shellcheck disable=SC1091
. "${VENV_DIR}"/bin/activate

if [ "$1" = "" ];
then
    echo "No --limit given, the current inventory:"
    ansible-inventory -i ansible-inventory.yaml --graph
    deactivate
    exit 1
fi


if [ ! -f "$ANSIBLE_SSH_KEY" ];
then
  echo "Ansible SSH key file ($ANSIBLE_SSH_KEY) not found, did you forget to create ?"
  deactivate
  exit 1
fi

ansible-playbook -i ./ansible-inventory.yaml  20-install-containerhost-common.yaml --limit all --verbose -v

deactivate
