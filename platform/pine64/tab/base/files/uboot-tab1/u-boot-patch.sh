#!/bin/bash

bootpoint=$(df | grep /boot | tail -n1 | awk '{print $1}')
if [[ ${bootpoint} == "/dev/mmcblk0p1" ]]; then
dd if=/boot/u-boot-sunxi-with-spl.bin of="${bootpoint/p[0-9]/}" bs=128k seek=1 conv=fsync;
elif [[ ${bootpoint} == "/dev/mmcblk1p1" ]]; then
dd if=/boot/u-boot-sunxi-with-spl.bin of="${bootpoint/p[0-9]/}" bs=128k seek=1 conv=fsync;
else
dd if=/boot/u-boot-sunxi-with-spl.bin of="${bootpoint/[0-9]/}" bs=128k seek=1 conv=fsync;
fi
