#!/usr/bin/env bash
#
# This script is called from prepare-iaas-$os after logging in via ssh as
# the default user existing in cloud images
#
set -ex

os=$(lsb_release -si | tr '[:upper:]' '[:lower:]')
if [ "$os" != "ubuntu" ] && [ "$os" != "debian" ]; then
    echo "unsupported os: '$os'"
    exit 1
fi

sudo cp -r /home/"$os"/.ssh /root/
sudo chown -R root:root /root/.ssh
sudo chmod 700 /root/.ssh
sudo chmod 600 /root/.ssh/authorized_keys
