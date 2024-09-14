#!/bin/bash

if [ -z "${SSH_KEY_FN}" ]
then
    echo "Error: SSH access key file missing, exiting ..."
    exit 1
fi

az vm image terms accept --urn erockyenterprisesoftwarefoundationinc1653071250513:rockylinux-9:rockylinux-9:latest

terraform init

terraform apply -auto-approve \
-target=azurerm_resource_group.rg-main \
-target=module.m001-network \
-target=module.m002-storage \
-target=module.m999-vm--okd-services \
|| exit 1

# terraform apply -auto-approve -target=module.

echo -n "Checking for the service node public IP ... "
VMIP=""

while [ -z "${VMIP}" ]
do
    echo -n "."
    # it is terraform refresh, just spellt out
    terraform apply -refresh-only -auto-approve -target=module.m001-network
    sleep 1;

    VMIP="$(terraform output -raw o_vm-okd-services--public_ip)"
done

echo -e "\nThe public ip:  ${VMIP}"

VM_OKD_SERVICES__PUBLIC_IP="${VMIP}"
export VM_OKD_SERVICES__PUBLIC_IP

