#!/usr/bin/env bash

set -e

platform="${1}"
envir="${2}"
builddir="${3}"
REPO_ROOT="${PWD}"

# fail out if platform, envir, and builddir are not all provided
if ! [[ -n ${platform} && -n ${envir} && -n ${builddir} ]]; then
  echo "Usage: ${0} <platform> <environment> <build-directory>"
  exit 1
fi

# check for root permissions
if [[ "$(id -u)" != 0 ]]; then
  echo "E: Requires root permissions" > /dev/stderr
  exit 1
fi

# normalize platforms
terra_envir="${envir}"
case "${platform}" in
  raspberrypi|raspi|rpi)
    platform="rpi"
  ;;
  pinephone|pp|ppog)
    platform="pinephone"
  ;;
  pinephonepro|ppp)
    platform="pinephonepro"
  ;;
  pinetab|pt|ptog|pt1)
    platform="pinetab"
  ;;
  pinetab2|pt2)
    platform="pinetab2"  
  ;;
  *)
    echo "E: Unknown platform, exiting..." > /dev/stderr
    exit 1
  ;;
esac
terra_platform="${platform}"
export terra_platform terra_envir

# check validity of input
valid_images=(
  {pinephone{,pro},pinetab{,2}}:{unicorn,lomiri}
  rpi:{unicorn,server}
)

if ! [[ "${platform}:${envir}" =~ "${valid_images[@]}" ]]; then
  echo "E: Invalid platform+environment combination, exiting..." > /dev/stderr
  exit 1
fi

# select environment-specific recipe and image names
case "${platform}:${envir}" in
  pinephone:unicorn|pinephonepro:unicorn|pinetab:unicorn|pinetab2:unicorn)
    target="${platform}"
  ;;
  pinephone:lomiri|pinephonepro:lomiri|pinetab:lomiri|pinetab2:lomiri)
    target="${platform}-lomiri"
  ;;
  rpi:unicorn)
    target="rpi-desktop"
  ;;
  rpi:server)
    target="rpi-server"
  ;;
esac

echo "
#----------------------#
# SOURCE BUILD SCRIPTS #
#----------------------#
"
source "build-scripts/overlayer.sh"

echo "
#------------------------#
# CREATE BUILD DIRECTORY #
#------------------------#
"
overlayer "${platform}" "${envir}" "${builddir}"
source "${builddir}/etc/terraform.conf"

# check for root filesystem tarball
tarball="${builddir}/binary/${FNAME}.tar"
if ! [[ -f ${tarball} ]]; then
  echo "E: Root tarball not found, please run build.sh first and ensure output is placed in ${builddir}/binary. Exiting..."  > /dev/stderr
  exit 1
fi

echo "
#--------------------#
# START IMAGE DEPLOY #
#--------------------#
"
case "${target}" in
  rpi-desktop)
    recipe="raspberrypi-desktop.yaml"
  ;;
  rpi-server)
    recipe="raspberrypi-server.yaml"
  ;;
  *)
    recipe="${target}.yaml"
  ;;
esac
image="${FNAME}.img"

cd "${builddir}"

# begin deploy
echo "I: Building ${image} from ${recipe}"
./debos-docker -t "image:${image}" -m 10G "${recipe}"

# move output image to output directory
output_dir="${builddir}/builds"
mkdir -p "${output_dir}"
mv "${image}" "${output_dir}"
mv "${image}.bmap" "${output_dir}"

cd "${REPO_ROOT}"
exit 0
