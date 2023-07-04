#!/usr/bin/env bash
#
# This script is called from prepare-iaas-$os after logging in over ssh as
# the root user
#
set -x

os=$(lsb_release -si | tr '[:upper:]' '[:lower:]')
if [ "$os" != "ubuntu" ] && [ "$os" != "debian" ]; then
    echo "unsupported os: '$os'"
    exit 1
fi

# Get rid of ugly perl messages when running from macOS:
# ===
# apt-listchanges: Reading changelogs...
# perl: warning: Setting locale failed.
# perl: warning: Please check that your locale settings:
# 	LANGUAGE = (unset),
# 	LC_ALL = (unset),
# 	LC_CTYPE = "UTF-8",
# 	LC_TERMINAL = "iTerm2",
# 	LANG = "C.UTF-8"
#     are supported and installed on your system.
# perl: warning: Falling back to a fallback locale ("C.UTF-8").
# ===
export LC_CTYPE=C.UTF-8

# Remove default user if present
if id "$os"; then
    # Make sure there is no systemd process running as the initial cloud image user
    # after the "enable root" step in prepare-iaas-$os. If there are any
    # proceses still running as the specified user the "userdel" command
    # below will fail.
    #
    # Depending on how long we have waited between running the "enable root"
    # script and this one it is possible the process has timed out on its own,
    # so run this command before doing "set -e" in case there is no process
    # to match.
    pkill -u "$os" -xf "/lib/systemd/systemd --user"

    # Make sure the process has gone away before continuing
    sleep_seconds=1
    attempt=1
    max_attempts=10
    while pgrep -u "$os" -xf "/lib/systemd/systemd --user"; do
        if [ $attempt -gt $max_attempts ]; then
            echo "failed waiting for systemd process to exit, please investigate"
            exit 1
        fi
        echo "systemd process still running as '$os' user, this is attempt $attempt out of $max_attempts, sleeping for $sleep_seconds seconds..."
        sleep $sleep_seconds
        attempt=$((attempt + 1))
    done

    # While the man page for "userdel" recommends using "deluser" we can not
    # run "deluser" with "--remove-home" without installing more than the
    # already included `perl-base` package on debian, so stick with the low
    # level utility.
    if ! userdel --remove "$os"; then
        exit 1
    fi
fi

# From this point we expect all commands to succeed
set -e

rm /etc/sudoers.d/*

# Make sure en_US.UTF-8 is present in the system, expected by at least
# bootstrap-cosmos.sh
locale_gen_file=/etc/locale.gen
if grep -q '^# en_US.UTF-8 UTF-8$' $locale_gen_file; then
    sed -i 's/^# \(en_US.UTF-8 UTF-8\)$/\1/' $locale_gen_file
    locale-gen
fi

if [ "$(lsb_release -is)" == "Debian" ]; then
    interfaces_file='/etc/network/interfaces.d/50-cloud-init'

    if [ -f "${interfaces_file}" ]; then
        interface_string='iface ens3 inet6 dhcp'
        accept_ra_string='    accept_ra 2'

        if ! grep -qPz "${interface_string}\n${accept_ra_string}" ${interfaces_file} ; then

            # By default net.ipv6.conf.ens3.accept_ra is set to 1 which
            # makes the kernel throw a way the IPv6 route when
            # net.ipv6.conf.all.forwarding is set to 1 by our service for
            # Docker.
             echo "Configuring interfaces to always accept Router Advertisements even with IP Forwarding enabled"
            sed -i -r  "s/(${interface_string})/\1\n${accept_ra_string}/" ${interfaces_file}
        else
            echo "WARN: Configuration already applied or no match for \"${interface_string}\" in ${interfaces_file}"
        fi
    else
        echo "WARN: ${interfaces_file} not found. File renamed in this image?"
    fi
fi

DEBIAN_FRONTEND="noninteractive" apt-get -y update
DEBIAN_FRONTEND="noninteractive" apt-get -o Dpkg::Options::="--force-confnew" --fix-broken --assume-yes dist-upgrade
reboot
