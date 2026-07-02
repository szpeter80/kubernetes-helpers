###
### OpenShift UPI / any-platform install helper script
### This script is not endorsed nor supported by Red Hat
###


# OCP_VERSION=latest-4.20 | stable-4.20 | 4.20.2
OCP_VERSION=latest-4.20
# ARCH=aarch64 | x86_64
ARCH=x86_64
ISO_PREFIX="os-example"
OPENSHIFT_INSTALL="$(which openshift-install)"
# Possible values: "singlenode" | anything else.
# The "singlenode" creates ISO for a Single-Node Openshift,
# any other option will create ISO-s for multinode / HA installation
INSTALL_MODE="singlenode"

ISO_DESTDIR="/var/www/html/iso"
ISO_CHCON_REF="/var/www/html/proxy.pac"
ISO_WEBLINK="http://example.com/iso/"

COREOS_INSTALLER='podman run --pull=always --privileged --rm -v /dev:/dev -v /run/udev:/run/udev -v .:/data -w /data quay.io/coreos/coreos-installer:release'


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

if [[ "$1" == "--client-download" ]]; then
    echo -e "\n\nDownloading installer and client binaries... \n"
    curl -k https://mirror.openshift.com/pub/openshift-v4/clients/ocp/$OCP_VERSION/openshift-install-linux.tar.gz -o openshift-install-linux.tar.gz
    curl -k https://mirror.openshift.com/pub/openshift-v4/clients/ocp/$OCP_VERSION/openshift-client-linux.tar.gz -o openshift-client-linux.tar.gz
    exit 1
fi


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

echo "--------------------------- Openshift install start -----------------------"
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
# https://docs.openshift.com/container-platform/latest/installing/installing_sno/install-sno-installing-sno.html#install-sno-installing-sno-manually

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

sudo chmod a+r ./"${ISO_PREFIX}"*.iso

sudo mv ./"${ISO_PREFIX}"*.iso "${ISO_DESTDIR}/"
sudo restorecon -r /var/www/html

echo "Access ISO files here: ${ISO_WEBLINK}"

"${OPENSHIFT_INSTALL}"  --dir=. wait-for bootstrap-complete

echo "If you experience certificate erros, add them to /etc/pki/ca-trust/source/anchors/ and run 'update-ca-trust' after"