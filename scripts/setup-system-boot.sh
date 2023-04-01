#!/bin/bash
mkdir -p /system-boot
mkdir -p /boot/firmware/

kern=$(dpkg -l | grep -E linux-image-.*-raspi | tail -n2 | awk '{print $2}')
kver=${kern/linux-image-/}

cp -rf /lib/linux-firmware-raspi/* /system-boot
cp -rf /usr/lib/firmware/$kver/device-tree/broadcom/* /system-boot
cp -rf /usr/lib/firmware/$kver/device-tree/overlays/ /system-boot
cp /boot/initrd.img-* /system-boot/initrd.img
cp /boot/vmlinuz-* /system-boot/vmlinuz

for i in /usr/lib/u-boot/*; do
RAWDIR=$(echo $i);
DIR=${RAWDIR/\/usr\/lib\/u-boot\/};
cp ${i}/u-boot.bin /system-boot/u-boot-${DIR}.bin; done

echo "[all]
kernel=vmlinuz
cmdline=cmdline.txt
initramfs initrd.img followkernel

[pi4]
max_framebuffers=2
arm_boost=1

[all]
dtparam=audio=on
dtparam=i2c_arm=on
dtparam=spi=on
disable_overscan=1
#hdmi_drive=2

[cm4]
dtoverlay=dwc2,dr_mode=host

[all]
dtoverlay=vc4-kms-v3d
camera_auto_detect=1
display_auto_detect=1
arm_64bit=1
dtoverlay=dwc2" | tee -a /system-boot/config.txt

echo "zswap.enabled=1 zswap.zpool=z3fold zswap.compressor=zstd dwc_otg.lpm_enable=0 console=tty1 root=LABEL=root rootfstype=ext4 rootwait fixrtc quiet splash" | tee -a /system-boot/cmdline.txt

echo "kernel=uboot.bin
device_tree_address=0x02000000

dtparam=i2c_arm=on
dtparam=spi=on" | tee -a /boot/firmware/config.txt

echo "net.ifnames=0 dwc_otg.lpm_enable=0 console=ttyAMA0,115200 console=tty1 root=/dev/mmcblk0p2 rootfstype=ext4 elevator=deadline rootwait" | tee -a /boot/firmware/cmdline.txt

cat > /system-boot/boot.scr << __EOF__
if test -n "$fdt_addr"; then
  fdt addr ${fdt_addr}
  fdt move ${fdt_addr} ${fdt_addr_r}  # implicitly sets fdt active
else
  fdt addr ${fdt_addr_r}
fi
fdt get value bootargs /chosen bootargs

setenv bootargs " ${bootargs} quiet splash"

setenv kernel_filename vmlinuz
setenv core_state "/uboot/ubuntu/boot.sel"
setenv kernel_bootpart ${distro_bootpart}

if test -z "${fk_image_locations}"; then
  setenv fk_image_locations ${prefix}
fi

for pathprefix in ${fk_image_locations}; do
  if load ${devtype} ${devnum}:${distro_bootpart} ${kernel_addr_r} ${pathprefix}${core_state}; then
    setenv kernel_filename kernel.img
    setenv kernel_vars "snap_kernel snap_try_kernel kernel_status"
    setenv recovery_vars "snapd_recovery_mode snapd_recovery_system snapd_recovery_kernel"
    setenv snapd_recovery_mode "install"
    setenv snapd_standard_params "panic=-1"

    env import -c ${kernel_addr_r} ${filesize} ${recovery_vars}
    setenv bootargs "${bootargs} snapd_recovery_mode=${snapd_recovery_mode} snapd_recovery_system=${snapd_recovery_system} ${snapd_standard_params}"

    if test "${snapd_recovery_mode}" = "run"; then
      setexpr kernel_bootpart ${distro_bootpart} + 1
      load ${devtype} ${devnum}:${kernel_bootpart} ${kernel_addr_r} ${pathprefix}${core_state}
      env import -c ${kernel_addr_r} ${filesize} ${kernel_vars}
      setenv kernel_name "${snap_kernel}"

      if test -n "${kernel_status}"; then
        if test "${kernel_status}" = "try"; then
          if test -n "${snap_try_kernel}"; then
            setenv kernel_status trying
            setenv kernel_name "${snap_try_kernel}"
          fi
        elif test "${kernel_status}" = "trying"; then
          setenv kernel_status ""
        fi
        env export -c ${kernel_addr_r} ${kernel_vars}
        save ${devtype} ${devnum}:${kernel_bootpart} ${kernel_addr_r} ${pathprefix}${core_state} ${filesize}
      fi
      setenv kernel_prefix "${pathprefix}uboot/ubuntu/${kernel_name}/"
    else
      setenv kernel_prefix "${pathprefix}systems/${snapd_recovery_system}/kernel/"
    fi
  else
    # Classic image; the kernel prefix is unchanged, nothing special to do
    setenv kernel_prefix "${pathprefix}"
  fi

  mw.w ${kernel_addr_r} 0x8b1f  # little endian
  if load ${devtype} ${devnum}:${kernel_bootpart} ${ramdisk_addr_r} ${kernel_prefix}${kernel_filename}; then
    kernel_size=${filesize}
    if cmp.w ${kernel_addr_r} ${ramdisk_addr_r} 1; then
      echo "Decompressing kernel..."
      unzip ${ramdisk_addr_r} ${kernel_addr_r}
      setenv kernel_size ${filesize}
      setenv try_boot "booti"
    else
      echo "Copying kernel..."
      cp.b ${ramdisk_addr_r} ${kernel_addr_r} ${kernel_size}
      setenv try_boot "bootz booti"
    fi

    if load ${devtype} ${devnum}:${kernel_bootpart} ${ramdisk_addr_r} ${kernel_prefix}initrd.img; then
      setenv ramdisk_param "${ramdisk_addr_r}:${filesize}"
    else
      setenv ramdisk_param "-"
    fi
    for cmd in ${try_boot}; do
        echo "Booting Ubuntu (with ${cmd}) from ${devtype} ${devnum}:${partition}..."
        ${cmd} ${kernel_addr_r} ${ramdisk_param} ${fdt_addr_r}
    done
  fi
done
__EOF__
