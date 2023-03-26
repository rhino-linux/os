#!/bin/sh

set -e

# Firmware repos locations
kernelArtifacts=https://archive.raspberrypi.org/debian/pool/main/r/raspberrypi-firmware

# Work around resolver failure in debos' fakemachine
mv /etc/resolv.conf /etc/resolv2.conf
echo "nameserver 1.1.1.1" > /etc/resolv.conf

sudo mv ../../tmp/$BUILD_ARCH/chroot/usr/lib/firmware/6.2.0-1003-raspi/device-tree/broadcom/* tempmount/
sudo mv ../../tmp/$BUILD_ARCH/chroot/usr/lib/firmware/6.2.0-1003-raspi/device-tree/overlays tempmount/
sudo mv ../../tmp/$BUILD_ARCH/chroot/usr/lib/linux-firmware-raspi/* tempmount/
sudo echo 'console=serial0,115200 console=tty1 boot=live components config toram hostname=rhino username=rhino rootfstype=ext4' | sudo tee -a tempmount/cmdline.txt

# Undo changes to work around debos fakemachine resolver
rm /etc/resolv.conf
mv /etc/resolv2.conf /etc/resolv.conf
