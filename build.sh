#!/usr/bin/env bash

set -e

platform=${1:?Usage: build.sh <platform> <environment> <build-directory>}
envir=${2:?Usage: build.sh <platform> <environment> <build-directory>}
builddir=${3:?Usage: build.sh <platform> <environment> <build-directory>}

REPO_ROOT="$(cd "$(dirname "$0")" && pwd)"

if [[ "$(id -u)" != 0 ]]; then
  echo "E: Requires root permissions" >&2
  exit 1
fi

echo "# Initializing submodules..."
(cd "$REPO_ROOT" && git submodule update --init --recursive)

echo "# Installing build dependencies..."
apt-get update
apt-get install -y \
  patch gnupg2 binutils zstd ubuntu-keyring \
  libglib2.0-dev libmysqlclient-dev apt-utils \
  debootstrap mtools dosfstools qemu-user-binfmt binfmt-support dpkg-dev

cat > /usr/share/debootstrap/scripts/devel << 'DEVEL'
case $ARCH in
  amd64|i386) default_mirror http://archive.ubuntu.com/ubuntu ;;
  *)          default_mirror http://ports.ubuntu.com/ubuntu-ports ;;
esac
keyring /usr/share/keyrings/ubuntu-archive-keyring.gpg
mirror_style release
download_style apt
finddebs_style from-indices
variants - buildd fakechroot minbase
DEVEL

dpkg -i "$REPO_ROOT/base/base/debs/live-build_20220505_all.deb"

cp "$REPO_ROOT/base/base/binary_grub-efi" /usr/lib/live/build/binary_grub-efi
if [[ -f "$REPO_ROOT/platform/pine64/base/binary_rootfs" ]]; then
  cp "$REPO_ROOT/platform/pine64/base/binary_rootfs" /usr/lib/live/build/binary_rootfs
fi

echo "# Patching debootstrap..."
TMPDIR="$(mktemp -d)"
cp /usr/share/debootstrap/functions "$TMPDIR/functions"
(cd "$TMPDIR" && patch -i "$REPO_ROOT/base/base/0002-remove-WRONGSUITE-error.patch")
cp "$TMPDIR/functions" /usr/share/debootstrap/functions
rm -rf "$TMPDIR"

echo "# Assembling overlays..."
"$REPO_ROOT/build-scripts/overlayer.sh" "$platform" "$envir" "$builddir"

chmod -R +x "$builddir"/etc/auto/config "$builddir"/etc/terraform.conf "$builddir"/etc/

echo "# Starting live-build..."
(cd "$builddir" && exec "$REPO_ROOT/build-scripts/live-build.sh" "$platform" "$envir")
