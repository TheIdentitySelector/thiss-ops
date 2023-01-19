#!/bin/bash
#
# This script runs in a Docker container (started with the 'make test_in_docker' command)
# and installs multiverse as it is in your source directory.
#

set -e

apt -y update
apt -y install git rsync gpg

cosmos_deb=$(find /multiverse/apt/ -maxdepth 1 -name 'cosmos_*.deb' | sort -V | tail -1)
dpkg -i "$cosmos_deb"

test -d /var/cache/cosmos/repo || mkdir -p /var/cache/cosmos/repo
test -d /var/cache/cosmos/model || mkdir -p /var/cache/cosmos/model

# Make every "cosmos update" copy the contents from /multiverse
# without requiring the changes in there to be checked into git.
cat >/etc/cosmos/update.d/50update-while-testing << EOF
#!/bin/sh

rsync -a --delete --exclude .git /multiverse/ /var/cache/cosmos/repo
EOF
chmod 755 /etc/cosmos/update.d/50update-while-testing

sed -i -e 's!^#COSMOS_REPO_MODELS=.*!COSMOS_REPO_MODELS="\$COSMOS_REPO/global/"!' /etc/cosmos/cosmos.conf

export DEBIAN_FRONTEND=noninteractive

echo ""
echo "***"
echo ""
echo "$0: Configured docker container for testing of files in /multiverse."
echo ""
echo "You should now be able to do"
echo ""
echo "  cosmos -v update"
echo "  cosmos -v apply"
echo ""

exec bash -l
