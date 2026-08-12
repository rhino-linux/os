#!/usr/bin/env bash

set -e
# declare verbose debug output
declare -gx PS4=$'\E[0;10m\E[1m\033[1;31m\033[1;37m[\033[1;35m${BASH_SOURCE[0]##*/}:\033[1;34m${FUNCNAME[0]:-NOFUNC}():\033[1;33m${LINENO}\033[1;37m] - \033[1;33mDEBUG: \E[0;10m'

REPO_ROOT="${PWD}"
scriptdir="${REPO_ROOT}/build-scripts"

#init sequences
source "${REPO_ROOT}/build-scripts/stacktrace.sh"
set_colors

# cleanup function to trap EXIT & INT
export cleaned=false
function cleanup() {
  cd "${REPO_ROOT}"
  if ! ${cleaned}; then
    # put any cleanup steps here if/as needed
    export cleaned=true
  fi
}
trap cleanup EXIT INT

{ export ignore_stack=false; set -o pipefail; trap stacktrace ERR RETURN; }

case ${1} in
  build)
    shift 1
	  source "${scriptdir}/build.sh"

		if [[ ${1} == "-h" ]] || [[ ${1} == "--help" ]]; then
		  help_build
		  exit 0
		fi

		platform="${1}"
		envir="${2}"
		builddir="${3}"

		# fail out if platform, envir, and builddir are not all provided
		if ! [[ -n ${platform} && -n ${envir} && -n ${builddir} ]]; then
		  help_build
		  exit 1
		fi

		# set full path
		builddir="$(realpath ${builddir})"

		# cleanup function to trap EXIT & INT
		export cleaned=false
		function cleanup() {
		  cd "${REPO_ROOT}"
		  if ! ${cleaned}; then
		    fancy_message info "Restoring backups"
		    # restore any patched files to their original state
		    for i in "binary_grub-efi" "binary_rootfs"; do
		      if [[ -f "${builddir}/${i}.bak" ]]; then
		        cp "${builddir}/${i}.bak" "/usr/lib/live/build/${i}"
		      fi
		    done
		    if [[ -f "${builddir}/functions.bak" ]]; then
		      cp "${builddir}/functions.bak" /usr/share/debootstrap/functions
		    fi
		    export cleaned=true
		  fi
		}

	  build_steps
	  exit 0
  ;;
  deploy)
    shift 1
    source "${scriptdir}/deploy.sh"

		if [[ ${1} == "-h" ]] || [[ ${1} == "--help" ]]; then
		  help_deploy
		  exit 0
		fi

		platform="${1}"
		envir="${2}"
		builddir="${3}"

		# fail out if platform, envir, and builddir are not all provided
		if ! [[ -n ${platform} && -n ${envir} && -n ${builddir} ]]; then
		  help_deploy
		  exit 1
		fi

		# set full path
		builddir="$(realpath ${builddir})"

		# cleanup function to trap EXIT & INT
		export cleaned=false
		function cleanup() {
		  cd "${REPO_ROOT}"
		  if ! ${cleaned}; then
		    # put any cleanup steps here if/as needed
		    export cleaned=true
		  fi
		}

		deploy_steps
		exit 0
	;;
  pull)
  	shift 1
  	source "${scriptdir}/pull.sh"

		if [[ ${1} == "-h" ]] || [[ ${1} == "--help" ]]; then
		  help_pull
		  exit 0
		fi

		repo="${1}" # rhino-linux/os
		branch="${2}" # main
		outdir="${3}" # $PWD

		# fail out if repo, branch, and outdir are not all provided
		if ! [[ -n ${repo} && -n ${branch} && -n ${outdir} ]]; then
		  help_pull
		  exit 1
		fi
		if ! command -v gh; then
		  fancy_message error "GitHub CLI (gh) is required"
		  exit 1
		fi
		if ! gh auth status; then
		  fancy_message error "Not authenticated with gh, run 'gh auth login' first"
		  exit 1
		fi

		shift 3
		# images to download
		selected=("${@}")
		if [[ -z ${selected[*]} ]]; then
		  selected=("all")
		fi

		# cleanup function to trap EXIT & INT
		export cleaned=false
		function cleanup() {
		  cd "${REPO_ROOT}"
		  if ! ${cleaned}; then
		    # put any cleanup steps here if/as needed
		    export cleaned=true
		  fi
		}

  	pull_steps
  	exit 0
  ;;
  *) 
  	fancy_message error "Unknown function"
  	exit 1
	;;
esac
