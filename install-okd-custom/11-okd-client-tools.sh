#!/bin/bash

if [ ! -f ../install-okd-custom.env ];
then
    echo "Script configuration not found, exiting"
    exit 1
fi

#shellcheck source=install-okd-custom.env
source ../install-okd-custom.env


if [ "${DEBUG}" = "1" ];
then
    set -x
fi


if [ ! -d ../bin ];
then
    echo "The $(pwd)/../bin directory was not found, please use the provided cluster directory template."
    exit 1
fi

if [ ! -f "${OKD_INSTALLER}" ]
then
    OKD_INSTALLER_ARCHIVE="../bin/okd-install.tar.gz"

    echo -n "Downloading installer ... "
    curl --location --silent -k https://github.com/okd-project/okd/releases/download/${OKD_VERSION}/openshift-install-linux-${OKD_VERSION}.tar.gz -o "${OKD_INSTALLER_ARCHIVE}"
    tar -xzf "${OKD_INSTALLER_ARCHIVE}" --directory="$(dirname ${OKD_INSTALLER_ARCHIVE})" || exit 1
    rm -f "${OKD_INSTALLER_ARCHIVE}"

     
    "${OKD_INSTALLER}" completion bash > "${OKD_INSTALLER_COMPLETION}"
    echo "done"
fi

if [ ! -f "${OKD_CLIENT}" ]
then
    OKD_CLIENT_ARCHIVE="../bin/okd-client.tar.gz"

    echo -n "Downloading client ... "
    curl --location --silent -k https://github.com/okd-project/okd/releases/download/${OKD_VERSION}/openshift-client-linux-${OKD_VERSION}.tar.gz -o "${OKD_CLIENT_ARCHIVE}"
    tar -xzf "${OKD_CLIENT_ARCHIVE}"  --directory="$(dirname ${OKD_CLIENT_ARCHIVE})" || exit 1
    rm -f "${OKD_CLIENT_ARCHIVE}"
     
    "${OKD_CLIENT}" completion bash > "${OKD_CLIENT_COMPLETION}"
    $(dirname "${OKD_CLIENT}")/kubectl completion bash > "$(dirname ${OKD_CLIENT_COMPLETION})/kubectl_completion"
    echo "done"
fi

