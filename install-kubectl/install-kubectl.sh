#!/bin/bash

I_KUBECTL_VERSION=$(curl -q -L -s https://dl.k8s.io/release/stable.txt)
I_KUBECTL_DIR='/usr/local/bin/'
I_CPU_ARCH='amd64'

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

if [ -f "${I_KUBECTL_DIR}/kubectl" ];
then
    echo "${I_KUBECTL_DIR}/kubectl already present, exiting ..."
    exit 0
fi

# Ask Curl to follow redirects and use the remote filename as local filename
curl --location --remote-name  \
    "https://dl.k8s.io/release/${I_KUBECTL_VERSION}/bin/linux/${I_CPU_ARCH}/kubectl" \
    --output-dir "${I_KUBECTL_DIR}"

if [ ! -f "${I_KUBECTL_DIR}/kubectl" ];
then
    echo "ERROR: kubectl download failed, exiting ..."
    exit 1
fi

chown root:root "${I_KUBECTL_DIR}/kubectl"
chmod 755 "${DST_DIR}/kubectl"

if [[ ! -d ~/bashrc.d ]];
then
  mkdir ~/bashrc.d
fi

"${I_KUBECTL_DIR}/kubectl" completion bash > ~/bashrc.d/kubectl

