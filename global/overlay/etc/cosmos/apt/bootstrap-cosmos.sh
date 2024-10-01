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
for pkg in rsync git git-core wget gpg jq; do
   # script is running with "set -e", use "|| true" to allow packages to not
   # exist without stopping the script
   apt-get -y install $pkg || true
done
cosmos_deb=$(find ./ -maxdepth 1 -name 'cosmos_*.deb' | sort -V | tail -1)
dpkg -i "$cosmos_deb"

if ! test -d /var/cache/cosmos/repo; then
    cosmos clone "$cmd_repo"
fi

# Re-run cosmos at reboot until it succeeds - use bash -l to get working proxy settings.
# It is possible the file does not exist or contains no matching lines,
# both cases are OK
grep -v "^exit 0" /etc/rc.local > /etc/rc.local.new || true
(echo ""
 echo "test -f /etc/run-cosmos-at-boot && (bash -l cosmos -v update; bash -l cosmos -v apply && rm /etc/run-cosmos-at-boot)"
 echo ""
 echo "exit 0"
) >> /etc/rc.local.new
mv -f /etc/rc.local.new /etc/rc.local

touch /etc/run-cosmos-at-boot

# If this cloud-config is set, it will interfere with our changes to /etc/hosts
# The configuration seems to move around between cloud-config versions
for file in /etc/cloud/cloud.cfg /etc/cloud/cloud.cfg.d/01_debian_cloud.cfg; do
    if [ -f ${file} ]; then
        sed -i 's/manage_etc_hosts: true/manage_etc_hosts: false/g' ${file}
    fi
done

# Remove potential $hostname.novalocal, added by cloud-init or Debian default
# from /etc/hosts. We add our own further down.
#
# From # https://www.debian.org/doc/manuals/debian-reference/ch05.en.html#_the_hostname_resolution:
# "For a system with a permanent IP address, that permanent IP address should
# be used here instead of 127.0.1.1."
sed -i.bak -e "/127\.0\.1\.1/d" /etc/hosts

vendor=$(lsb_release -is)
version=$(lsb_release -rs)
min_version=1337
host_ip=127.0.1.1
if [ "${vendor}" = "Ubuntu" ]; then
    min_version=20.04
elif [ "${vendor}" = "Debian" ]; then
    min_version=11
fi

hostname $cmd_hostname
short=`echo ${cmd_hostname} | awk -F. '{print $1}'`
# Only change behavior on modern OS where `ip -j` outputs a json predictuble
# enought to work with.
#
# Use `dpkg` to easier compare ubuntu versions.
if dpkg --compare-versions "${version}" "ge" "${min_version}"; then
    # When hostname pointed to loopback in /etc/hosts containers running on the
    # host tried to connect to the container itself instead of the host.
    host_ip=$(ip -j address show "$(ip -j route show default | jq -r '.[0].dev')"  | jq -r .[0].addr_info[0].local)
fi
echo "${host_ip} ${cmd_hostname} ${short}" >> /etc/hosts

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
