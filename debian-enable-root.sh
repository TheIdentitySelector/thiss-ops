#!/usr/bin/env bash
#
# This script is called from prepare-iaas-debian after logging in via ssh as
# the default "debian" user
#
set -ex

sudo cp -r /home/debian/.ssh /root/
sudo chown -R root:root /root/.ssh
sudo chmod 700 /root/.ssh
sudo chmod 600 /root/.ssh/authorized_keys
