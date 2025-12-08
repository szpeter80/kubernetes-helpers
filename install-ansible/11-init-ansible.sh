#!/bin/bash

# shellcheck source=./00-setup-shell-env.sh
source ./00-setup-shell-env.sh

###############################################################################


echo -e "\nVirtual environment directory: ${VENV_DIR}\n\n"

if [ ! -d "${VENV_DIR}" ];
then
    echo -e "\nVirtual environment not found, creating ... \n\n"
    ${PYTHON_EXECUTABLE_PATH} -m venv "${VENV_DIR}"
    source "${VENV_DIR}"/bin/activate 

    echo -e "\nUpdating pip ... \n\n"
    # "python" from now on point to the exact python used to set up the venv
    python -m pip install --upgrade pip

    if [ -f requirements.txt ];
    then
        echo -e "\nInstalling requirements.txt ... \n\n"
        pip install --upgrade --requirement requirements.txt
    fi

    pip list --outdated

    echo -e "\nUpdate the dependencies by running 'pip freeze --local --requirement requirements.txt >requirements.txt' inside the virtual env\n\n"

    deactivate
fi


source "${VENV_DIR}"/bin/activate 

if [ ! -f ansible.cfg.example ];
then
    echo -e "\nCreating ansible.cfg.example ... \n\n"
    ansible-config init --disabled -t all > ansible.cfg.example
fi

echo -e "\nCreating ansible.cfg ... \n\n"
if [ ! -f ansible.cfg ];
then
cat <<'EOF' > ansible.cfg
[defaults]
  nocows=1
  inventory=inventory.yml
  log_path=ansible-log.txt
EOF
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