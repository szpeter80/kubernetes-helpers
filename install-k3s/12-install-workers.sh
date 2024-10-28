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

K3S_TOKEN="$(cat ./node-token)"
K3S_URL="$(grep server <./k3s.yaml | cut -d ':' -f 2- | tr -d '[:blank:]')"

ansible -i ./ansible-inventory.yaml -m file -a "state=directory path=~/.kube mode=0755" all -vv
ansible -i ./ansible-inventory.yaml -m copy -a "src=./k3s.yaml dest=~/.kube/config" all -vv

ansible -i ./ansible-inventory.yaml -m shell -a "curl -sfL https://get.k3s.io | K3S_URL=$K3S_URL K3S_TOKEN=$K3S_TOKEN  sh -" g-workers -vv

deactivate
