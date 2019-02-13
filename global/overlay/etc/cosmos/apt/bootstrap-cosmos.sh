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

set -x


# cloud-init runs with LANG='US-ASCII' which is likely to fail because of non-US-ASCII chars in the manifest
export LANG='en_US.UTF-8'

export DEBIAN_FRONTEND='noninteractive'

apt-get -y update
apt-get -y upgrade
for pkg in rsync git git-core wget; do
   apt-get -y install $pkg
done
dpkg -i cosmos_1.5-1_all.deb

if ! test -d /var/cache/cosmos/repo; then
    cosmos clone "$cmd_repo"
fi

# re-run cosmos at reboot until it succeeds - use bash -l to get working proxy settings
grep -v "^exit 0" /etc/rc.local > /etc/rc.local.new
(echo ""
 echo "test -f /etc/run-cosmos-at-boot && (bash -l cosmos -v update; bash -l cosmos -v apply && rm /etc/run-cosmos-at-boot)"
 echo ""
 echo "exit 0"
) >> /etc/rc.local.new
mv -f /etc/rc.local.new /etc/rc.local

touch /etc/run-cosmos-at-boot

# If this cloud-config is set, it will interfere with our changes to /etc/hosts
grep -q 'manage_etc_hosts: true' /etc/cloud/cloud.cfg
if [ ${?} -eq 0 ]; then
    sed -i 's/manage_etc_hosts: true/manage_etc_hosts: false/g' /etc/cloud/cloud.cfg
fi

hostname $cmd_hostname
short=`echo ${cmd_hostname} | awk -F. '{print $1}'`
echo "127.0.1.1 ${cmd_hostname} ${short}" >> /etc/hosts

# Set up cosmos models. They are in the order of most significant first, so we want
# <host> <group (if it exists)> <global>
_host_type=`echo $cmd_hostname | cut -d - -f 1`
models=$(
    echo -n '\\$COSMOS_REPO/'"$cmd_hostname/:"
    test -d /var/cache/cosmos/repo/${_host_type}-common && echo -n '\\$COSMOS_REPO/'"${_host_type}-common/:"
    echo -n '\\$COSMOS_REPO/global/'
)
echo "Configuring cosmos with the following models:"
echo "${models}"

perl -pi -e "s,#COSMOS_REPO_MODELS=.*,COSMOS_REPO_MODELS=\"${models}\"," /etc/cosmos/cosmos.conf
perl -pi -e "s,#COSMOS_UPDATE_VERIFY_GIT_TAG_PATTERN=.*,COSMOS_UPDATE_VERIFY_GIT_TAG_PATTERN=\"${cmd_tags}*\"," /etc/cosmos/cosmos.conf

env COSMOS_BASE=/var/cache/cosmos COSMOS_KEYS=/var/cache/cosmos/repo/global/overlay/etc/cosmos/keys /var/cache/cosmos/repo/global/post-tasks.d/015cosmos-trust

mkdir -p /var/cache/scriptherder

(date; nohup cosmos -v update && nohup cosmos -v apply && rm /etc/run-cosmos-at-boot; date) 2>&1 | tee /var/log/cosmos.log


exit 0
