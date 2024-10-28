#!/bin/bash

DEFAULT_ENV_REALPATH="../default.env"

# shellcheck disable=SC1090
. "$DEFAULT_ENV_REALPATH"

ENVFILE="$1"
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


ansible -i ./ansible-inventory.yaml -m shell -a 'curl -sfL https://get.k3s.io | sh -' g-control-plane -vv
ansible -i ./ansible-inventory.yaml -m fetch -a "src=/var/lib/rancher/k3s/server/node-token dest=./node-token flat=yes" g-control-plane -vv
ansible -i ./ansible-inventory.yaml -m fetch -a "src=/etc/rancher/k3s/k3s.yaml  dest=./k3s.yaml flat=yes" g-control-plane -vv

deactivate
