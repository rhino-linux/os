#!/bin/sh

set -e

# Firmware repos locations
kernelArtifacts=https://archive.raspberrypi.org/debian/pool/main/r/raspberrypi-firmware

# Work around resolver failure in debos' fakemachine
mv /etc/resolv.conf /etc/resolv2.conf
echo "nameserver 1.1.1.1" > /etc/resolv.conf

echo "Create tmp folder..."
mkdir -p /var/tmp && cd /var/tmp

echo "Download the kernel deb package..."
wget -nc -O linux-image.deb $kernelArtifacts/raspberrypi-kernel_1.20230317-1_arm64.deb
wget -nc -O linux-headers.deb $kernelArtifacts/raspberrypi-kernel-headers_1.20230317-1_arm64.deb
wget -nc -O linux-libc-dev.deb $kernelArtifacts/linux-libc-dev_1.20230317-1_arm64.deb
wget -nc -O bootloader.deb $kernelArtifacts/raspberrypi-bootloader_1.20230317-1_arm64.deb

echo "Install kernel and firmware..."
dpkg -i /var/tmp/*.deb && rm /var/tmp/* -r

# Undo changes to work around debos fakemachine resolver
rm /etc/resolv.conf
mv /etc/resolv2.conf /etc/resolv.conf
