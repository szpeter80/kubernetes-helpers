#!/bin/bash
 
if [ -z "${VM_OKD_SERVICES__PUBLIC_IP}" ]
then
    echo "Error: remote VM IP is not specified, exiting ..."
    exit 1
fi
 
if [ -z "${SSH_KEY_FN}" ]
then
    echo "Error: SSH access key file missing, exiting ..."
    exit 1
fi

# okd-demokey.pub
# This creates the .ssh directory with the correct permissions
###${VM_OKD_SERVICES__SSH_CMD} "ssh-keygen -N '' -t rsa -b 4096 -f /home/adminuser/.ssh/id_rsa"
###${VM_OKD_SERVICES__SSH_CMD} "rm -f /home/adminuser/.ssh/id_rsa*"

${VM_OKD_SERVICES__SCP_CMD} "${SSH_KEY_FN}" "adminuser@${VM_OKD_SERVICES__PUBLIC_IP}:/home/adminuser/.ssh/id_rsa"
${VM_OKD_SERVICES__SSH_CMD} "ln -s /home/adminuser/.ssh/id_rsa /home/adminuser/.ssh/okd-demokey"

${VM_OKD_SERVICES__SCP_CMD} "${SSH_KEY_FN}.pub" "adminuser@${VM_OKD_SERVICES__PUBLIC_IP}:/home/adminuser/.ssh/id_rsa.pub"
${VM_OKD_SERVICES__SSH_CMD} "ln -s /home/adminuser/.ssh/id_rsa.pub /home/adminuser/.ssh/okd-demokey.pub"

${VM_OKD_SERVICES__SCP_CMD} ./vm--okd-services "adminuser@${VM_OKD_SERVICES__PUBLIC_IP}:/home/adminuser/"
${VM_OKD_SERVICES__SSH_CMD} "cd /home/adminuser/vm--okd-services && ./vm--okd-services--init.sh"

