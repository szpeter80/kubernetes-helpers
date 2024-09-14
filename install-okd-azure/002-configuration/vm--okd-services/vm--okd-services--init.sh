#!/usr/bin/bash

###############################################################
### 
### This script is meant to be run on the support/service node
### which is provisioned next to the cluster nodes
### 
###############################################################

# shellcheck disable=SC1091
# shellcheck source=vm--okd-services.env
. ./vm--okd-services.env

### Enable EPEL + update to latest
sudo dnf --assumeyes install epel-release
sudo dnf --assumeyes update

### Install required packages for ansible (other packages will be installed by ansible)
sudo dnf  --assumeyes install python

### Install Ansible
python -m venv project-venv
# shellcheck disable=SC1091
. ./project-venv/bin/activate
pip install --upgrade pip
pip install ansible
deactivate

### Run Ansible locally
sudo bash -c "cd /home/adminuser/vm--okd-services/ && . ./project-venv/bin/activate && ansible-playbook -i inventory vm--okd-services.yaml && deactivate"

# Reconfigure and restart HAProxy
sudo cp ./haproxy.cfg /etc/haproxy/haproxy.cfg
sudo setsebool -P haproxy_connect_any 1
sudo mkdir -p /etc/systemd/system/haproxy.service.d
sudo cp haproxy_systemd_override.conf /etc/systemd/system/haproxy.service.d/override.conf
sudo systemctl daemon-reload
sudo systemctl reload haproxy.service
sudo systemctl restart haproxy.service

### Get OKD installer and client  
curl --output "${OKD_CLIENT_ARCHIVE}"  --location https://github.com/okd-project/okd/releases/download/4.12.0-0.okd-2023-04-01-051724/openshift-client-linux-4.12.0-0.okd-2023-04-01-051724.tar.gz
tar -zxvf "${OKD_CLIENT_ARCHIVE}"

curl --output "${OKD_INSTALLER_ARCHIVE}" --location https://github.com/okd-project/okd/releases/download/4.12.0-0.okd-2023-04-01-051724/openshift-install-linux-4.12.0-0.okd-2023-04-01-051724.tar.gz
tar -zxvf "${OKD_INSTALLER_ARCHIVE}"

mkdir -p /home/adminuser/.local/bin
mv kubectl oc openshift-install /home/adminuser/.local/bin/

oc version || exit 1
openshift-install version || exit 1 


sed -i "s/###CLUSTER-NAME###/${OKD_CLUSTER_NAME}/g" \
/home/adminuser/vm--okd-services/install-config.yaml.example

if ! [ -e "/home/adminuser/.ssh/okd-demokey.pub" ]
then
    echo "Error: the SSH identity public part is not found, exiting ..."
    exit 1
fi

awk 'BEGIN{getline l < "/home/adminuser/.ssh/okd-demokey.pub"}/###SSH-PUBLIC-KEY###/{gsub("###SSH-PUBLIC-KEY###",l)}1' \
/home/adminuser/vm--okd-services/install-config.yaml.example \
>/home/adminuser/vm--okd-services/install-config.yaml

mkdir -p "${OKD_INSTALL_DIR}"
cp /home/adminuser/vm--okd-services/install-config.yaml "${OKD_INSTALL_DIR}"

openshift-install create manifests           --dir="${OKD_INSTALL_DIR}/"
openshift-install create ignition-configs    --dir="${OKD_INSTALL_DIR}/"

sudo mkdir /var/www/html/okd4/
sudo cp -R "${OKD_INSTALL_DIR}"/*.ign /var/www/html/okd4/
sudo chown -R apache: /var/www/html/
sudo chmod -R 755 /var/www/html/



