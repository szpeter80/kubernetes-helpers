#!/bin/bash

source ./00-setup-shell-env.sh

###############################################################################


echo "Virtual environment directory: ${VENV_DIR}"

if [ ! -d "${VENV_DIR}" ];
then
    echo "Virtual environment not found, creating ..."
    $PYTHON_EXECUTABLE_PATH -m venv "${VENV_DIR}"

    . "${VENV_DIR}"/bin/activate || exit 1

    $PYTHON_EXECUTABLE_PATH -m pip install --upgrade pip
    if [ -f requirements.txt ];
    then
        pip install --upgrade --requirement requirements.txt
    fi

    pip list --outdated

    echo "Update the dependencies by running 'pip freeze --local --requirement requirements.txt >requirements.txt' inside the virtual env"

    deactivate
fi

# shellcheck disable=SC1091
. "${VENV_DIR}"/bin/activate || exit 1

if [ ! -f ansible.cfg.example ];
then
    ansible-config init --disabled -t all > ansible.cfg.example
fi

if [ ! -f ansible.cfg.example ];
then
cat <<'EOF' > ansible.cfg
[defaults]
  nocows=1
  log_path=ansible-log.txt
EOF
fi


if [ ! -f ${ANSIBLE_SSH_KEY} ];
then
    echo "Not found Ansible SSH key file (${ANSIBLE_SSH_KEY}), creating it - do not forget to deploy to hosts"
    ssh-keygen -t ed25519 -f "./${ANSIBLE_SSH_KEY}" || exit 1
fi

if [ ! -f "./${ANSIBLE_INVENTORY_FILE}" ];
then
    echo "Not found Ansible inventory file (${ANSIBLE_INVENTORY_FILE}), creating"
    cp ./inventory.yml.example ${ANSIBLE_INVENTORY_FILE} || exit 1
fi

# TOOD az ansible configban elvileg már be van állitva az inventory vagy kellene.... 
ansible-inventory -i ${ANSIBLE_INVENTORY_FILE} --graph || exit 1

deactivate

echo "Ansible has been sucessfully initialized"