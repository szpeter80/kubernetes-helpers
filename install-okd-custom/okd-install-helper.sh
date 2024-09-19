#!/bin/bash

### This script should be invoked when pwd == 'install'

###
### OKD UPI ( "any-platform" ) install helper script
###
### Legal: "Red Hat Core OS", and "OpenShift" is a trademark of Red Hat.
### This tool is not provided by, endorsed by, or supported by Red Hat.
### The trademark is used for identification and reference purposes only.
###


if [ ! -f ../../../install-okd-custom.env ];
then
    echo "Script configuration not found, exiting"
    exit 1
fi

#shellcheck source=install-okd-custom.env
source ../../../install-okd-custom.env

OKD_INSTALLER="../bin/openshift-install"
OKD_CLIENT="../bin/oc"

if [ "${DEBUG}" = "1" ];
then
    set -x
fi

if [ ! -f ./install-config.yaml.orig ];
then
    echo "No install-config.yaml.orig was found in the current directory, exiting."
    exit 1
fi

if [ ! -d ../bin ];
then
    echo "The ../bin directory was not found, please use the provided cluster directory template."
    exit 1
fi

if [ ! -f "${OKD_INSTALLER}" ]
then
    OKD_INSTALLER_ARCHIVE="../bin/okd-install.tar.gz"

    echo -n "Downloading installer ... "
    curl --location --silent -k https://github.com/okd-project/okd/releases/download/${OKD_VERSION}/openshift-install-linux-${OKD_VERSION}.tar.gz -o "${OKD_INSTALLER_ARCHIVE}"
    tar -xzf "${OKD_INSTALLER_ARCHIVE}" --directory="$(dirname ${OKD_INSTALLER_ARCHIVE})" || exit 1
    rm -f "${OKD_INSTALLER_ARCHIVE}"
    echo "done"
fi

if [ ! -f "${OKD_CLIENT}" ]
then
    OKD_CLIENT_ARCHIVE="../bin/okd-client.tar.gz"

    echo -n "Downloading client ... "
    curl --location --silent -k https://github.com/okd-project/okd/releases/download/${OKD_VERSION}/openshift-client-linux-${OKD_VERSION}.tar.gz -o "${OKD_CLIENT_ARCHIVE}"
    tar -xzf "${OKD_CLIENT_ARCHIVE}"  --directory="$(dirname ${OKD_CLIENT_ARCHIVE})" || exit 1
    rm -f "${OKD_CLIENT_ARCHIVE}"
    echo "done"
fi

COREOS_ISO_URL=$( ${OKD_INSTALLER} coreos print-stream-json | jq --raw-output '.architectures.x86_64.artifacts.metal.formats.iso.disk.location')
COREOS_ISO_FN=$(basename "${COREOS_ISO_URL}")


echo -e "\nInstall artifacts will be created is the current directory: $(pwd)"
echo "ISO prefix: ${ISO_PREFIX}"
echo "Install mode: ${INSTALL_MODE}"
echo -e "OKD installer version: \n" && "${OKD_INSTALLER}" version

echo -e "\nThis is your last chance to stop installation. Press CTRL+C to abort or any key to proceed... \n"
# shellcheck disable=SC2162
# shellcheck disable=SC2034
read dummy

COREOS_INSTALLER="podman run ${COREOS_INSTALLER_ARGS} --privileged --rm -v /dev:/dev -v /run/udev:/run/udev -v .:/data -w /data quay.io/coreos/coreos-installer:release"

echo "--------------------------- Cluster install start -----------------------"

cp install-config.yaml.orig install-config.yaml

"${OKD_INSTALLER}"  create manifests --dir=.

cp -r manifests manifests.orig
cp -r openshift openshift.orig

if [[ "${INSTALL_MODE}" == "singlenode" ]]; then
    "${OKD_INSTALLER}"  create single-node-ignition-config --dir=.
else
    "${OKD_INSTALLER}"  create ignition-configs --dir=.
fi



### Create customized ISO for installer
#
# https://coreos.github.io/coreos-installer/getting-started/#run-from-a-container
# https://coreos.github.io/coreos-installer/customizing-install/

# Prerequisites: current directory need to contain original coreos image and also the .ign files
# Paths outside of current dir wont work due to coreos-installer is run from a container

# Example: add a static ip configuration to the kernel arguments (alternative to set it in the ignition config)
# coreos-installer iso kargs modify -a ip=10.1.5.1::10.0.0.1:255.0.0.0:openshift-okd::none:10.1.1.1 coreos.iso


if [ ! -f "./${COREOS_ISO_FN}" ]; then
    curl --location "${COREOS_ISO_URL}" --output "${COREOS_ISO_FN}"
fi

CURRENT_USER="$(whoami)"

# Due to privileged mounts, we need sudo

# shellcheck disable=SC2086
sudo ${COREOS_INSTALLER}                                   \
    iso  customize                                         \
    --dest-device="${NODE_DISK_PATH_BOOTSTRAP}"            \
    --dest-ignition bootstrap.ign                          \
    -o "${ISO_PREFIX}-bootstrap.iso"                       \
    "${COREOS_ISO_FN}"

# shellcheck disable=SC2086
sudo ${COREOS_INSTALLER}                                   \
    iso  customize                                         \
    --dest-device="${NODE_DISK_PATH_MASTER}"               \
    --dest-ignition master.ign                             \
    -o "${ISO_PREFIX}-master.iso"                          \
    "${COREOS_ISO_FN}"

# shellcheck disable=SC2086
sudo ${COREOS_INSTALLER}                                   \
    iso  customize                                         \
    --dest-device="${NODE_DISK_PATH_WORKER}"               \
    --dest-ignition worker.ign                             \
    -o "${ISO_PREFIX}-worker.iso"                          \
    "${COREOS_ISO_FN}"

sudo chown "${CURRENT_USER}:" ./*.iso
chmod a+r ./*.iso

mv "${COREOS_ISO_FN}" ..

if [ "${ISO_DESTDIR}" != "." ];
then
    mv ./*.iso "${ISO_DESTDIR}/"
fi

if [ -n "${ISO_CHCON_REF}" ];
then
    sudo chcon --reference "${ISO_CHCON_REF}" "${ISO_DESTDIR}"/*.iso
fi

mv ../"${COREOS_ISO_FN}" .

cat <<EOF
You might get the message

'error: x509 certificate signed by unknown authority when logging in'

It means the management host running oc / kubectl does not trust the OAuth's CA
OAuth's CA is not the same as the API server's CA which is bundled in the initial kubeconfig

You can get the OAuth's CA by checking its Pods definition (mounts) in the 'openshift-authentication' namespace

On RHEL systems you can add a CA by copying the certificate to /etc/pki/ca-trust/source/anchors/ 
and running 'update-ca-trust'

EOF

"${OKD_INSTALLER}"  --dir=. wait-for bootstrap-complete