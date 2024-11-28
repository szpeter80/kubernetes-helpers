#!/bin/bash

SELF_REAL_FN="$(readlink -en "$0")"
DEFAULT_ENV_REALPATH="$(cd "$(dirname -- "$SELF_REAL_FN")" || exit 1 >/dev/null; pwd -P)/default.env"

# shellcheck disable=SC1090
. "$DEFAULT_ENV_REALPATH"

ENVFILE="$1"
if [ -f "${ENVFILE}" ];
then
    echo "Sourcing environment file: ${ENVFILE}"
    # shellcheck disable=SC1090
    source "${ENVFILE}"
else
    echo "Environment file (${ENVFILE}) not found, using defaults from $DEFAULT_ENV_REALPATH"
fi

if [ "${DEBUG}" = "1" ];
then
    set -x
fi


###############################################################################


# shellcheck disable=SC1091
. "${VENV_DIR}"/bin/activate

#ansible-config init --disabled -t all >ansible.cfg

cat <<'EOF' > ansible.cfg
[defaults]
  nocows=1
  log_path=ansible-log.txt
  ansible_managed = Ansible managed: {file} modified on %Y-%m-%d %H:%M:%S by {uid} on {host}
EOF

deactivate
