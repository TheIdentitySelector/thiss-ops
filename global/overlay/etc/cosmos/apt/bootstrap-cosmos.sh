#!/bin/sh

#set -e 
# not all breakage is un-recoverable...

cmd_hostname="$1"
if test -z "$cmd_hostname"; then
    echo "Usage: $0 HOSTNAME REPO TAGPATTERN"
    exit 1
fi

cmd_repo="$2"
if test -z "$cmd_repo"; then
   echo "Usage $0 HOSTNAME REPO TAGPATTERN"
   exit 2
fi

cmd_tags="$3"
if test -z "$cmd_tags"; then
   echo "Usage $0 HOSTNAME REPO TAGPATTERN"
   exit 3
fi

apt-get -y update
apt-get -y upgrade
for pkg in rsync git git-core wget; do
   apt-get -y install $pkg
done
dpkg -i cosmos_1.5-1_all.deb

if ! test -d /var/cache/cosmos/repo; then
    cosmos clone "$cmd_repo"
fi

hostname $cmd_hostname

perl -pi -e "s,#COSMOS_REPO_MODELS=.*,COSMOS_REPO_MODELS=\"\\\$COSMOS_REPO/global/:\\\$COSMOS_REPO/$cmd_hostname/\"," /etc/cosmos/cosmos.conf
perl -pi -e "s,#COSMOS_UPDATE_VERIFY_GIT_TAG_PATTERN=.*,COSMOS_UPDATE_VERIFY_GIT_TAG_PATTERN=\"${cmd_tags}*\"," /etc/cosmos/cosmos.conf

env COSMOS_BASE=/var/cache/cosmos COSMOS_KEYS=/var/cache/cosmos/repo/global/overlay/etc/cosmos/keys /var/cache/cosmos/repo/global/post-tasks.d/015cosmos-trust

(date; nohup cosmos -v update && nohup cosmos -v apply; date) 2>&1 | tee /var/log/cosmos.log


exit 0
