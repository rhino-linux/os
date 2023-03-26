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
  mv "$BASE_DIR/tmp/$BUILD_ARCH/"*.img "$OUTPUT_DIR/${FNAME}.img"

  # cd into output to so {FNAME}.sha256.txt only
  # includes the filename and not the path to
  # our file.
  cd $OUTPUT_DIR
  # after the build, let's determine the name of our image file ...
  IMAGEFILE="${FNAME}.img"

  # ... and change the partition type to reflect the file
  # system actually in use for partition 1 ("b" is FAT32)
  sfdisk --part-type $IMAGEFILE 1 b

  # next, we need to patch two things inside the image, so
  # we need to set up a loop device for it.
  FREELOOP=$(losetup -f)
  # note that this could become a TOCTOU issue if more than
  # 1 process tries to use loop devices

  # as the image is a full disk image containing a partition, we
  # need to jump to the position where the first partition starts
  losetup -o 1048576 $FREELOOP $IMAGEFILE

  # now let's mount it
  mkdir -p tempmount
  sudo mount $FREELOOP tempmount

  sudo mv ../../tmp/$BUILD_ARCH/chroot/usr/lib/firmware/6.2.0-1003-raspi/* tempmount/
  sudo mv ../../tmp/$BUILD_ARCH/chroot/usr/lib/linux-firmware-raspi/* tempmount/

  # here comes the cleanup part
  sync
  sudo umount $FREELOOP
  losetup -d $FREELOOP
  
  sha512sum "${FNAME}.img" > "${FNAME}.sha512"
  sha256sum "${FNAME}.img" > "${FNAME}.sha256"
  cd $BASE_DIR
}

if [[ "$ARCH" == "all" ]]; then
    build amd64
else
    build "$ARCH"
fi
