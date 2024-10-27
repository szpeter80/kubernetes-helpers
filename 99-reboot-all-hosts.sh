#!/bin/bash

. ./venv/bin/activate

ansible -i ./ansible-inventory.yaml -m reboot --verbose -v all

deactivate
