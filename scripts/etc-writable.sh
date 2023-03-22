#!/bin/bash
# Systemd and friends are patched to look in /etc/writable for timezone,
# hostname, and machine type information.

set -e

mkdir -p /etc/writable

for f in timezone localtime hostname machine-info; do
    if ! [ -e /etc/writable/$f ]; then
        # Try to prevent circular loop
        if [ -e /etc/$f ] && ! [[ "$(readlink -f /etc/$f)" =~ ^/etc/writable ]]; then
            echo "I: Moving /etc/$f to /etc/writable/"
            mv /etc/$f /etc/writable/$f
        fi
    fi

    echo "I: Linking /etc/$f to /etc/writable/"
    ln -sf writable/$f /etc/$f
done

# Only touch this file like livecd-rootfs did (see [1]). I guess in some cases
# it makes a difference whether a file does not exist or exists but is empty.
# [1] https://git.launchpad.net/livecd-rootfs/commit/?id=4b74aba181b2662e86abe83acafa2ada8d353967
touch /etc/writable/machine-info
