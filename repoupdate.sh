#!/bin/bash

set -e
set -x

su salt -c " \
pushd /opt/home/salt/l3-salt-prod/; \
git pull; "
restart salt-master
