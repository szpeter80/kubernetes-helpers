#!/bin/bash

. ./venv/bin/activate

ansible -i ./ansible-inventory.yaml -m apt -a "update_cache=yes upgrade=yes" --verbose -v all

deactivate
