#!/bin/bash

I_KUBECTL_VERSION=$(curl -q -L -s https://dl.k8s.io/release/stable.txt)
I_KUBECTL_DIR='/usr/local/bin/kubectl.d'
I_CPU_ARCH='amd64'


if [ -f "./install-kubectl.env" ];
then
    echo "Applying variables override"
    . "./install-kubectl.env"
fi


DST_DIR="${I_KUBECTL_DIR}/${I_KUBECTL_VERSION}"

if [ -d "${DST_DIR}" ];
then
    echo "Version ${I_KUBECTL_VERSION} seems to be installed, exiting ..."
    exit 0
fi

echo "Creating destination directory: ${DST_DIR}"
mkdir -p ${DST_DIR}

# Ask Curl to follow redirects and use the remote filename as local filename
curl --location --remote-name  \
    "https://dl.k8s.io/release/${I_KUBECTL_VERSION}/bin/linux/${I_CPU_ARCH}/kubectl" \
    --output-dir "${DST_DIR}"

if [ ! -f "${DST_DIR}/kubectl" ];
then
    echo "ERROR: kubectl download failed, exiting ..."
    exit 1
fi

chown root:root "${DST_DIR}/kubectl"
chmod 755 "${DST_DIR}/kubectl"

if [[ ! -f "${I_KUBECTL_DIR}/../kubectl" || -L "${I_KUBECTL_DIR}/../kubectl" ]];
then
    echo "Updating symlink for kubectl:  ${I_KUBECTL_DIR}/../kubectl --> ${DST_DIR}/kubectl"
    rm -f "${I_KUBECTL_DIR}/../kubectl"
    ln -s  "${DST_DIR}/kubectl"  "${I_KUBECTL_DIR}/../kubectl"
fi


