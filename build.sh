#!/bin/bash

set -e

# check for root permissions
if [[ "$(id -u)" != 0 ]]; then
  echo "E: Requires root permissions" > /dev/stderr
  exit 1
fi

# get config
if [ -n "$1" ]; then
  CONFIG_FILE="$1"
else
  CONFIG_FILE="etc/terraform.conf"
fi
BASE_DIR="$PWD"
source "$BASE_DIR"/"$CONFIG_FILE"


#VanillaOS patch to yeet ia32
#sudo sed -i '/Check_package chroot \/usr\/lib\/grub\/i386-efi\/configfile.mod grub-efi-ia32-bin/d' /usr/lib/live/build/binary_grub-efi

echo -e "
#----------------------#
# INSTALL DEPENDENCIES #
#----------------------#
"

apt-get update
apt-get install -y patch gnupg2 binutils zstd ubuntu-keyring apt-utils
ln -sfn /usr/share/debootstrap/scripts/gutsy /usr/share/debootstrap/scripts/devel

build () {
  BUILD_ARCH="$1"

  mkdir -p "$BASE_DIR/tmp/$BUILD_ARCH"
  cd "$BASE_DIR/tmp/$BUILD_ARCH" || exit

  # remove old configs and copy over new
  rm -rf config auto
  cp -r "$BASE_DIR"/etc/* .
  # Make sure conffile specified as arg has correct name
  cp -f "$BASE_DIR"/"$CONFIG_FILE" terraform.conf

  # Symlink chosen package lists to where live-build will find them
  ln -s "package-lists.$PACKAGE_LISTS_SUFFIX" "config/package-lists"

  echo -e "
#------------------#
# LIVE-BUILD CLEAN #
#------------------#
"
  lb clean

  echo -e "
#-------------------#
# LIVE-BUILD CONFIG #
#-------------------#
"
  lb config

  echo -e "
#------------------#
# LIVE-BUILD BUILD #
#------------------#
"
  lb --force build

  echo -e "
#---------------------------#
# MOVE OUTPUT TO BUILDS DIR #
#---------------------------#
"

  OUTPUT_DIR="$BASE_DIR/builds/$BUILD_ARCH"
  mkdir -p "$OUTPUT_DIR"
  FNAME="Rhino-Linux-OS-$VERSION$OUTPUT_SUFFIX-$BUILD_ARCH"
  mv "$BASE_DIR/tmp/$BUILD_ARCH/live-image-$BUILD_ARCH.img" "$OUTPUT_DIR/${FNAME}.img"
  
  mkdir -p /tmp/extfix
  sudo mount -t auto -o loop,rw,sync,offset=1048576 "$OUTPUT_DIR/${FNAME}.img" /tmp/extfix
  sudo chroot /tmp/extfix
  U_BOOT_PARAMETERS="console=ttyS2,115200n8 consoleblank=0 loglevel=7 rw splash plymouth.ignore-serial-consoles vt.global_cursor_default=0" /etc/kernel/postinst.d/zz-u-boot-menu 6.2.0-okpine-pro
  exit
  sudo umount /tmp/extfix
  sudo rm -r /tmp/extfix

  # cd into output to so {FNAME}.sha256.txt only
  # includes the filename and not the path to
  # our file.
  cd $OUTPUT_DIR
  sha512sum "${FNAME}.img" > "${FNAME}.sha512"
  sha256sum "${FNAME}.img" > "${FNAME}.sha256"
  cd $BASE_DIR
}


if [[ "$ARCH" == "all" ]]; then
    build amd64
else
    build "$ARCH"
fi
