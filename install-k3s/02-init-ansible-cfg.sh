#!/bin/bash

source ./00-setup-shell-env.sh

###############################################################################


# shellcheck disable=SC1091
. "${VENV_DIR}"/bin/activate

#ansible-config init --disabled -t all >ansible.cfg

cat <<'EOF' > ansible.cfg
[defaults]
  nocows=1
  log_path=ansible-log.txt
EOF

deactivate
