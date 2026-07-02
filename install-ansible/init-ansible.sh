#!/bin/bash

DEBUG=0
# This refers to python on the control node
PYTHON_EXECUTABLE_PATH="$(which python)"
VENV_DIR='./.venv'
ANSIBLE_SSH_KEY=./ansible_ssh_key
ANSIBLE_INVENTORY_FILE=./inventory.yml

CUSTOM_ENV_REALPATH="./custom.env"
if [ -f "$CUSTOM_ENV_REALPATH" ];
then
    echo "Sourcing custom environment: ${CUSTOM_ENV_REALPATH}"
    source "$CUSTOM_ENV_REALPATH"
fi

###############################################################################

if [ "${DEBUG}" = "1" ];
then
    set -x
fi

echo -e "\nVirtual environment directory: ${VENV_DIR}\n\n"
if [ ! -d "${VENV_DIR}" ];
then
    echo -e "\nVirtual environment not found, creating ... \n\n"
    ${PYTHON_EXECUTABLE_PATH} -m venv "${VENV_DIR}"
    source "${VENV_DIR}"/bin/activate 

    echo -e "\nUpdating pip ... \n\n"
    # "python" from now on point to the exact python used to set up the venv
    python -m pip install --upgrade pip
    pip install --upgrade ansible ansible-lint

    deactivate
fi

source "${VENV_DIR}"/bin/activate 

if [ ! -f ansible.cfg.example ];
then
    echo -e "\nCreating ansible.cfg.example ... \n\n"
    ansible-config init --disabled -t all > ansible.cfg.example
fi

if [ ! -f ansible.cfg ];
then
echo -e "\nCreating ansible.cfg ... \n\n"
cat <<'EOF' > ansible.cfg
[defaults]

nocows=1
inventory=inventory.yml

roles_path={{ "./roles:" ~ ANSIBLE_HOME ~ "/roles:/usr/share/ansible/roles:/etc/ansible/roles" }}
collections_path={{ "./collections:" ~ ANSIBLE_HOME ~ "/collections:/usr/share/ansible/collections" }}

log_path=ansible-log.txt
EOF
fi

if [ ! -d "./roles" ];
then
    mkdir ./roles
fi

if [ ! -d "./collections" ];
then
    mkdir ./collections
fi

if [ ! -f "${ANSIBLE_SSH_KEY}" ];
then
    echo -e "\nNot found Ansible SSH key file (${ANSIBLE_SSH_KEY}), creating it"
    echo -e "Do not forget to deploy the key to managed hosts !\n\n"
    ssh-keygen -t ed25519 -f "./${ANSIBLE_SSH_KEY}" || exit 1
fi

if [ ! -f "./${ANSIBLE_INVENTORY_FILE}" ];
then
    echo "Not found Ansible inventory file: ${ANSIBLE_INVENTORY_FILE}, creating"
    cp ./inventory.yml.example "${ANSIBLE_INVENTORY_FILE}" || exit 1
fi

ansible-inventory --graph || exit 1
deactivate
echo -e "\n\nAnsible setup has been finished\n"