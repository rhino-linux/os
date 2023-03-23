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

# do arch-dep adjustment
if [ $ARCH = arm64 ]; then
echo 'initramfs-tools
grub-efi-arm64
grub-efi-arm64-bin
grub-efi-arm64-signed' | sudo tee -a etc/config/package-lists.calamares/pool.list.binary; 
else
echo 'bcmwl-kernel-source
microcode-initrd
iucode-tool
grub-efi-amd64
grub-efi-amd64-bin
grub-efi-amd64-signed' | sudo tee -a etc/config/package-lists.calamares/pool.list.binary; 
fi

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
  mv "$BASE_DIR/tmp/$BUILD_ARCH/live-image-$BUILD_ARCH.hybrid.img" "$OUTPUT_DIR/${FNAME}.img"

  # cd into output to so {FNAME}.sha256.txt only
  # includes the filename and not the path to
  # our file.
  cd $OUTPUT_DIR
  sha512sum "${FNAME}.img" > "${FNAME}.sha512"
  sha256sum "${FNAME}.img" > "${FNAME}.sha256"
  cd $BASE_DIR
}

cat > etc/config/package-lists.calamares/pool.list.binary << __EOF__
b43-fwcutter
dkms
setserial
user-setup
efibootmgr
secureboot-db
shim
shim-signed
__EOF__

if [[ "$ARCH" == "all" ]]; then
    build amd64
else
    build "$ARCH"
fi
