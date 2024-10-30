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

# shellcheck disable=SC2034
KUBECONFIG='./k3s.yaml'

kubectl get nodes

# shellcheck disable=SC2181
if [ $? -ne 0 ]; then
    echo -e "\nkubectl invocation failed, check if k3s.yaml really points to the public address or name of control node \n"

    deactivate
    exit 1
fi


ansible -i ./ansible-inventory.yaml -m file -a "state=directory path=~/.kube mode=0755" all -vv
ansible -i ./ansible-inventory.yaml -m copy -a "src=./k3s.yaml dest=~/.kube/config" all -vv

ansible -i ./ansible-inventory.yaml -m shell -a "curl -sfL https://get.k3s.io | K3S_URL=$K3S_URL K3S_TOKEN=$K3S_TOKEN  sh -" g_workers -vv

deactivate


echo -e "\nYour k3s cluster is ready! \n\n"
kubectl version
echo
kubectl get nodes 
echo -e "\n"
