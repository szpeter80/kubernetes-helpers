#!/bin/bash

# shellcheck disable=SC1091

# shellcheck source=./provision.env
. ./provision.env

###Check pre-requisites

# Check for az cli if installed
if ! [ -e "$(which az)" ]
then
    echo "Azure cli is not installed, trying to install...."
    sudo apt install azure-cli
fi

# Check for active login session to Azure

if ! az account list;
then
  echo "Please log in to the Azure portal..."
  az login
fi

# Check for terraform command
if ! [ -e "$(which terraform)" ]
then
    echo "Error: terraform is not installed, aborting ..."
    exit 1
fi


# Only RSA SSH keys are supported by Azure
if ! [ -e "okd-demokey" ]
then
    ssh-keygen -N "" -t rsa -b 4096 -f "okd-demokey" || exit 1
fi

# Due to WSL2 we need to have the key at a native FS location
# to be able to set permissions strict enough to satisfy OpenSSH

if [ -e "${SSH_KEY_FN}" ]
then
    chmod 777 "${SSH_KEY_FN}"
    rm -f "${SSH_KEY_FN}"
fi
cp okd-demokey "${SSH_KEY_FN}"
chmod 0400 "${SSH_KEY_FN}"

if [ -e "${SSH_KEY_FN}.pub" ]
then
    rm -f "${SSH_KEY_FN}.pub"
fi
cp okd-demokey.pub "${SSH_KEY_FN}.pub"

### Fedora Core OS Azure image
if ! [ -e "${FCOS_IMG_FN}" ]
then
    curl --output "./${FCOS_IMG_FN}.xz" "${FCOS_IMG_URL}"
    xz --decompress "./${FCOS_IMG_FN}.xz"
fi

### I. Deploy the common resources and the support VM
# the script must be sourced in order to the variables defined in them
# be visible (simply running it makes export visible only to the subprocesses, but not the parent)
cd ./001-resources || exit 1
. ./init.sh || exit 1
cd ..  || exit 1

# Support node access commands
export VM_OKD_SERVICES__SSH_CMD="ssh -oServerAliveInterval=3 -oStrictHostKeyChecking=accept-new -i ${SSH_KEY_FN} adminuser@${VM_OKD_SERVICES__PUBLIC_IP} "
export VM_OKD_SERVICES__SCP_CMD="scp -oServerAliveInterval=3 -oStrictHostKeyChecking=accept-new -i ${SSH_KEY_FN} -r "

### II. Configure the support node
cd ./002-configuration  || exit 1
. ./init.sh  || exit 1
cd ..  || exit 1

### III. Deploy bootstrap node resources
# Bootstrap will automatically start with the Ignition config created and hosted on the support node
cd ./001-resources  || exit 1
terraform apply -auto-approve -target=module.m101-vm--okd-cluster-bootstrap  || exit 1
cd ..  || exit 1

# 
# Check if services are up on the bootsrap node
echo -e -n "\n\nChecking for machine config service on the bootstrap node... "
${VM_OKD_SERVICES__SSH_CMD} "while true; do nc -z bootstrap 22623 && break; sleep 1; echo -n '.'; done"
echo -e -n "\n\nChecking for the kubernetes API service on the bootstrap node... "
${VM_OKD_SERVICES__SSH_CMD} "while true; do nc -z bootstrap 6443 && break; sleep 1; echo -n '.'; done"

### IV. Deploy the master/control nodes
cd ./001-resources  || exit 1
terraform apply -auto-approve   || exit 1
cd ..  || exit 1

# Restart HAProxy - backend names will only be resolvable when the nodes' terraform has been deployed
# TODO: check if systemd restart works as expected !
###${VM_OKD_SERVICES__SSH_CMD} "sudo systemctl restart haproxy.service"

echo -e "\n\nProvision done, you can access the support node with this command:\nssh -o ServerAliveInterval=3 -i /tmp/okd-demokey adminuser@${VM_OKD_SERVICES__PUBLIC_IP}"
