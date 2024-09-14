#!/bin/bash

###
### OKD / OpenShift UPI ( "any-platform" ) install helper script
###
### Legal: "Red Hat Core OS", and "OpenShift" is a trademark of Red Hat.
### This tool is not provided by, endorsed by, or supported by Red Hat.
### The trademark is used for identification and reference purposes only.

# PLATFORM_TYPE= okd | openshift
PLATFORM_TYPE="okd"

# PLATFORM_VERSION=latest-4.14 | stable-4.14 | 4.14.9
PLATFORM_VERSION=latest-4.15

# ARCH=aarch64 | x86_64
ARCH=x86_64




if [[ "$1" == "--client-download" ]]; then
    echo -e "\n\nDownloading installer and client binaries... \n"
    curl -k https://mirror.openshift.com/pub/openshift-v4/clients/ocp/$PLATFORM_VERSION/openshift-install-linux.tar.gz -o openshift-install-linux.tar.gz
    curl -k https://mirror.openshift.com/pub/openshift-v4/clients/ocp/$PLATFORM_VERSION/openshift-client-linux.tar.gz -o openshift-client-linux.tar.gz
    exit 1

fi

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
# https://docs.openshift.com/container-platform/4.14/installing/installing_sno/install-sno-installing-sno.html#install-sno-installing-sno-manually

# Prerequisites: current directory need to contain original rhcos image and also the .ign files
# Paths outside of current dir wont work due to the way the current directory is mapped to the coreos
# container image in the Podman run

# Example: add a static ip configuration to the kernel arguments (alternative to set it in the ignition config)
# coreos-installer iso kargs modify -a ip=10.1.5.1::10.0.0.1:255.0.0.0:openshift-okd::none:10.1.1.1 rhcos.iso


if [ ! -f "./${RHCOS_FN}" ]; then
    curl  "${RHCOS_URL}" --output "${RHCOS_FN}"
fi

if [[ "${INSTALL_MODE}" == "singlenode" ]]; then

# Single Node Openshift installs differently than multinode
# "iso customize" does not work, probably because it interferes
# with the bootstrap process, as that invokes 'coreos-installer' directly
# from a script deployed from the in-place ignition file, with
# parameters for ignition files to use and also setting explicitly
# the destination device on the command line

    sudo ${COREOS_INSTALLER}                                   \
    iso  ignition embed                                        \
    --force                                                    \
    --ignition-file bootstrap-in-place-for-live-iso.ign        \
    -o "${ISO_PREFIX}-bootstrap-in-place.iso"                  \
    ${RHCOS_FN}

else

    sudo ${COREOS_INSTALLER}                                   \
    iso  customize                                             \
    --dest-device=/dev/sda                                     \
    --dest-ignition bootstrap.ign                              \
    -o "${ISO_PREFIX}-bootstrap.iso"                           \
    ${RHCOS_FN}

    sudo ${COREOS_INSTALLER}                                   \
    iso  customize                                             \
    --dest-device=/dev/sda                                     \
    --dest-ignition master.ign                                 \
    -o "${ISO_PREFIX}-master.iso"                              \
    ${RHCOS_FN}

fi

# Worker iso generated the same for all installations

    sudo ${COREOS_INSTALLER}                                   \
    iso  customize                                             \
    --dest-device=/dev/sda                                     \
    --dest-ignition worker.ign                                 \
    -o "${ISO_PREFIX}-worker.iso"                              \
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
