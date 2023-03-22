#!/bin/sh

set -e

# Firmware repos locations
bootFirmwareRepo=https://raw.githubusercontent.com/raspberrypi/firmware/master
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

echo "Install kernel and firmware..."
dpkg -i /var/tmp/*.deb && rm /var/tmp/* -r

echo "Copy firmware to the correct locations"
mkdir -p /boot/firmware/overlays
cp /usr/lib/linux-image-*/broadcom/* /boot/firmware/
cp /usr/lib/linux-image-*/overlays/* /boot/firmware/overlays/
cp /boot/vmlinuz-* /boot/firmware/vmlinuz

echo "Make directories for the boot firmware location and licence..."
cd /boot/firmware

echo "Download the firmware and licence..."
wget -nc $bootFirmwareRepo/boot/LICENCE.broadcom

echo "Download the bootcode..."
wget -nc $bootFirmwareRepo/boot/bootcode.bin

echo "Download the start files..."
wget -nc $bootFirmwareRepo/boot/start.elf
wget -nc $bootFirmwareRepo/boot/start4.elf
wget -nc $bootFirmwareRepo/boot/start4cd.elf
wget -nc $bootFirmwareRepo/boot/start4db.elf
wget -nc $bootFirmwareRepo/boot/start4x.elf
wget -nc $bootFirmwareRepo/boot/start_cd.elf
wget -nc $bootFirmwareRepo/boot/start_db.elf
wget -nc $bootFirmwareRepo/boot/start_x.elf

echo "Download the link files..."
wget -nc $bootFirmwareRepo/boot/fixup.dat
wget -nc $bootFirmwareRepo/boot/fixup4.dat
wget -nc $bootFirmwareRepo/boot/fixup4cd.dat
wget -nc $bootFirmwareRepo/boot/fixup4db.dat
wget -nc $bootFirmwareRepo/boot/fixup4x.dat
wget -nc $bootFirmwareRepo/boot/fixup_cd.dat
wget -nc $bootFirmwareRepo/boot/fixup_db.dat
wget -nc $bootFirmwareRepo/boot/fixup_x.dat

# Undo changes to work around debos fakemachine resolver
rm /etc/resolv.conf
mv /etc/resolv2.conf /etc/resolv.conf
