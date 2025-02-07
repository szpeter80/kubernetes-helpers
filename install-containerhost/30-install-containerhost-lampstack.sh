#!/bin/bash
DEFAULT_ENV_REALPATH="../default.env"

# shellcheck disable=SC1090
. "$DEFAULT_ENV_REALPATH"

ENVFILE="./custom.env"
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


# shellcheck disable=SC1091
. "${VENV_DIR}"/bin/activate


if [ ! -f "$ANSIBLE_SSH_KEY" ];
then
  echo "Ansible SSH key file ($ANSIBLE_SSH_KEY) not found, did you forget to create ?"
  exit 1
fi

ansible-playbook -i ./ansible-inventory.yaml  30-install-containerhost-lampstack.yaml  --verbose -v 

deactivate
