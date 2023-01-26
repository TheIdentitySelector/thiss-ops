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

DEBIAN_FRONTEND="noninteractive" apt-get -y update
DEBIAN_FRONTEND="noninteractive" apt-get -o Dpkg::Options::="--force-confnew" --fix-broken --assume-yes dist-upgrade
reboot
