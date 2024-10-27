#!/bin/bash

. ./venv/bin/activate

ansible-config init --disabled -t all >ansible.cfg
echo 'log_path=ansible-log.txt' >>ansible.cfg

deactivate
