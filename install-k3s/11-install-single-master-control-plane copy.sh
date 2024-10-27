#!/bin/bash

. ./venv/bin/activate

ansible -i ./ansible-inventory.yaml -m shell -a 'curl -sfL https://get.k3s.io | sh -' g-control-plane -vv
ansible -i ./ansible-inventory.yaml -m fetch -a "src=/var/lib/rancher/k3s/server/node-token dest=./node-token flat=yes" g-control-plane -vv
ansible -i ./ansible-inventory.yaml -m fetch -a "src=/etc/rancher/k3s/k3s.yaml  dest=./k3s.yaml flat=yes" g-control-plane -vv

deactivate
