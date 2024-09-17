#!/bin/bash

###
### OKD UPI ( "any-platform" ) install helper script
###
### Legal: "Red Hat Core OS", and "OpenShift" is a trademark of Red Hat.
### This tool is not provided by, endorsed by, or supported by Red Hat.
### The trademark is used for identification and reference purposes only.
###
### This script should be invoked when pwd == 'install'


if [ -f ../../../install-okd-custom.env ];
then
    # shellcheck disable=SC1091
    source ../../../install-okd-custom.env
fi

if [ "${DEBUG}" = "1" ];
then
    set -x
fi

#VERSION=4.15.0-0.okd-2024-03-10-010116
VERSION=4.15.0-0.okd-2024-03-10-010116

#CLIENT_ARCH=linux | linux-arm64
CLIENT_ARCH=linux


if [ ! -f ./install-config.yaml.orig ];
then
    echo "No install-config.yaml.orig was found in the current directory, exiting."
    exit 1
fi

if [ ! -d ../bin ];
then
    echo "The ../bin directory was not found, please use the provided template."
    exit 1
fi

if [ ! -f ../bin/openshift-install ]
then
    OKD_INSTALLER_ARCHIVE="../bin/okd-install.tar.gz"

    echo -n "Downloading installer ... "
    curl --location --silent -k https://github.com/okd-project/okd/releases/download/${VERSION}/openshift-install-linux-${VERSION}.tar.gz -o "${OKD_INSTALLER_ARCHIVE}"
    tar -xzf "${OKD_INSTALLER_ARCHIVE}" --directory="$(dirname ${OKD_INSTALLER_ARCHIVE})" && rm -f "${OKD_INSTALLER_ARCHIVE}"
    echo "done"
fi

if [ ! -f ../bin/oc ]
then
    OKD_CLIENT_ARCHIVE="../bin/okd-client.tar.gz"

    echo -n "Downloading client ... "
    curl --location --silent -k https://github.com/okd-project/okd/releases/download/${VERSION}/openshift-client-linux-${VERSION}.tar.gz -o "${OKD_CLIENT_ARCHIVE}"
    tar -xzf "${OKD_CLIENT_ARCHIVE}"  --directory="$(dirname ${OKD_CLIENT_ARCHIVE})" && rm -f "${OKD_CLIENT_ARCHIVE}"
    echo "done"
fi


exit 0


ISO_PREFIX="installer"
OPENSHIFT_INSTALL="$(which openshift-install)"
#OPENSHIFT_INSTALL="./openshift-install"

# Possible values: "singlenode" | anything else. 
# The "singlenode" creates ISO for a single-node Openshift, 
# any other option will create ISO-s for multinode / HA installation
INSTALL_MODE="normal"

ISO_DESTDIR="/usr/share/nginx/html/iso/"
ISO_CHCON_REF="/usr/share/nginx/html/index.html"
ISO_WEBLINK="http://webserver/iso"

#TMP=$( "${OPENSHIFT_INSTALL}" coreos print-stream-json | grep '\.iso[^.]' | grep x86_64)

RHCOS_URL=$( ${OPENSHIFT_INSTALL} coreos print-stream-json | jq --raw-output '.architectures.x86_64.artifacts.metal.formats.iso.disk.location')
RHCOS_FN=$(basename "${RHCOS_URL}")

if [[ "$1" != "--force" ]]; then
    echo -e "\nInstall artifacts will be created is the current directory: $(pwd)"
    echo "ISO prefix: ${ISO_PREFIX}"
    echo "Install mode: ${INSTALL_MODE}"
    echo -e "Openshift installer: \n"
    "${OPENSHIFT_INSTALL}" version

    echo -e "\n\nPlease provide the '--force' option to proceed.\n"
    exit 1
fi


COREOS_INSTALLER='podman run --pull=always --privileged --rm -v /dev:/dev -v /run/udev:/run/udev -v .:/data -w /data quay.io/coreos/coreos-installer:release'



echo "--------------------------- OpenShift install start -----------------------"
cp install-config.yaml.orig install-config.yaml

"${OPENSHIFT_INSTALL}"  create manifests --dir=.
cp -r manifests manifests.orig
cp -r openshift openshift.orig

if [[ "${INSTALL_MODE}" == "singlenode" ]]; then
    "${OPENSHIFT_INSTALL}"  create single-node-ignition-config --dir=.
else
    "${OPENSHIFT_INSTALL}"  create ignition-configs --dir=.
fi



### Create customized ISO for installer
#
# https://coreos.github.io/coreos-installer/getting-started/#run-from-a-container
# https://coreos.github.io/coreos-installer/customizing-install/

# Prerequisites: current directory need to contain original rhcos image and also the .ign files
# Paths outside of current dir wont work due to coreos-installer is run from a container

# Example: add a static ip configuration to the kernel arguments (alternative to set it in the ignition config)
# coreos-installer iso kargs modify -a ip=10.1.5.1::10.0.0.1:255.0.0.0:openshift-okd::none:10.1.1.1 rhcos.iso


if [ ! -f "./${RHCOS_FN}" ]; then
    curl  "${RHCOS_URL}" --output "${RHCOS_FN}"
fi

sudo ${COREOS_INSTALLER}                                   \
    iso  customize                                         \
    --dest-device=/dev/sda                                 \
    --dest-ignition bootstrap.ign                          \
    -o "${ISO_PREFIX}-bootstrap.iso"                       \
    ${RHCOS_FN}

sudo ${COREOS_INSTALLER}                                   \
    iso  customize                                         \
    --dest-device=/dev/sda                                 \
    --dest-ignition master.ign                             \
    -o "${ISO_PREFIX}-master.iso"                          \
    ${RHCOS_FN}

sudo ${COREOS_INSTALLER}                                   \
    iso  customize                                         \
    --dest-device=/dev/sda                                 \
    --dest-ignition worker.ign                             \
    -o "${ISO_PREFIX}-worker.iso"                          \
    ${RHCOS_FN}

mv ./${RHCOS_FN} ..

sudo chmod a+r ./*.iso

sudo mv ./*.iso "${ISO_DESTDIR}/"
sudo chcon --reference "${ISO_CHCON_REF}" "${ISO_DESTDIR}"/*.iso

echo "Access ISO files here: ${ISO_WEBLINK}"

"${OPENSHIFT_INSTALL}"  --dir=. wait-for bootstrap-complete

echo "You might get the message 'error: x509 certificate signed by unknown authority when logging in'"
echo "It means the host running oc / kubectl does not trust a given CA"
echo "You can not solve this by disabling TLS verification, because that is valid only for the original URL, but there is a redirect to the OAuth operator after"
echo "API server issuer CA is included in the kubeconfig but OAuth has a different issuer and that is not included."
echo "You can get the CA which is used by the OAuth server if you check its pods definition in the openshift-authentication namespace"
echo "Don't forget to copy the cluster ingress controller certificate to /etc/pki/ca-trust/source/anchors/ and run 'update-ca-trust' after"
