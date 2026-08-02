#!/usr/bin/env bash

set -e

platform="${1}"
envir="${2}"
builddir="${3}"
REPO_ROOT="${PWD}"

if ! [[ -n ${platform} && -n ${envir} && -n ${builddir} ]]; then
  echo "Usage: ${0} <platform> <environment> <build-directory>"
  exit 1
fi

if [[ "$(id -u)" != 0 ]]; then
  echo "E: Requires root permissions" > /dev/stderr
  exit 1
fi

# select images to deploy 
case "${platform}" in
  pinephone)
    terra_platform="pinephone"
    targets=(pinephone pinephonepro)
  ;;
  pinetab)
    terra_platform="pinetab"
    targets=(pinetab pinetab2)
  ;;
  rpi)
    terra_platform="rpi"
    case "${envir}" in
      unicorn)
        targets=(rpi-desktop)
      ;;
      server)
        targets=(rpi-server)
      ;;
      *)
        echo "Unsupported Raspberry Pi environment: ${envir}"
        exit 1
      ;;
    esac
  ;;
  *)
    echo "Unknown deploy platform, exiting"
    exit 1
  ;;
esac

# select environment-specific recipe and image names
case "${terra_platform}:${envir}" in
  pinephone:unicorn|pinetab:unicorn)
    recipe_suffix=""
    image_suffix=""
  ;;
  pinephone:lomiri|pinetab:lomiri)
    recipe_suffix="-lomiri"
    image_suffix="-lomiri"
  ;;
  rpi:*)
    recipe_suffix=""
    image_suffix=""
  ;;
  *)
    echo "Unsupported deploy environment: ${envir}"
    exit 1
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

# check for root filesystem tarball
shopt -s nullglob
tarballs=("${builddir}"/binary/*.tar)
if [[ ((${#tarballs[@]}!=1)) ]]; then
  echo "Expected one root filesystem tarball in ${builddir}/binary, found ${#tarballs[@]}"
  exit 1
fi

tarball="${tarballs[0]}"

terra_envir="${envir}"
export terra_platform terra_envir
source "${builddir}/etc/terraform.conf"

output_dir="${builddir}/builds/${terra_platform}"
mkdir -p "${output_dir}"

echo "
#--------------------#
# START IMAGE DEPLOY #
#--------------------#
"
cd "${builddir}"
for target in "${targets[@]}"; do
  case "${target}" in
    rpi-desktop)
      recipe="raspberrypi-desktop.yaml"
    ;;
    rpi-server)
      recipe="raspberrypi-server.yaml"
    ;;
    *)
      recipe="${target}${recipe_suffix}.yaml"
    ;;
  esac

  image="Rhino-Linux-${VERSION}${SUBVER}-${target}${image_suffix}.img"
  ./debos-docker -t "image:${image}" -m 10G "${recipe}"
  mv "${image}" "${output_dir}"
  mv "${image}.bmap" "${output_dir}"
  xz -T0 -v "${output_dir}/${image}"
done

exit 0