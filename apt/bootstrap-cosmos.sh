#!/bin/sh

set -e

cmd_hostname="$1"
if test -z "$cmd_hostname"; then
    echo "Usage: $0 HOSTNAME REPO"
    exit 1
fi

cmd_repo="$2"
if test -z "$cmd_repo"; then
   echo "Usage $0 HOSTNAME REPO"
   exit 2
fi

set -x

apt-get -y install rsync git-core
dpkg -i cosmos_1.2-2_all.deb

if ! test -d /var/cache/cosmos/repo; then
    cosmos clone "$cmd_repo"
fi

hostname $cmd_hostname

perl -pi -e "s,#COSMOS_REPO_MODELS=.*,COSMOS_REPO_MODELS=\"\\\$COSMOS_REPO/global/:\\\$COSMOS_REPO/$cmd_hostname/\"," /etc/cosmos/cosmos.conf
perl -pi -e 's,#COSMOS_UPDATE_VERIFY_GIT_TAG_PATTERN=.*,COSMOS_UPDATE_VERIFY_GIT_TAG_PATTERN="eduid-cosmos*",' /etc/cosmos/cosmos.conf

COSMOS_BASE=/var/cache/cosmos COSMOS_KEYS=/var/cache/cosmos/repo/global/overlay/etc/cosmos/keys /var/cache/cosmos/repo/global/post-tasks.d/015cosmos-trust

(date; nohup cosmos -v update && nohup cosmos -v apply; date) > /var/log/cosmos.log 2>&1

exit 0
