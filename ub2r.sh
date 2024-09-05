#!/bin/bash

declare -gx PS4=$'\E[0;10m\E[1m\033[1;31m\033[1;37m[\033[1;35m${BASH_SOURCE[0]##*/}:\033[1;34m${FUNCNAME[0]:-NOFUNC}():\033[1;33m${LINENO}\033[1;37m] - \033[1;33mDEBUG: \E[0;10m'
shopt -s extglob

# Colors
if [[ -z $NO_COLOR ]]; then
  RED=$'\033[0;31m'
  GREEN=$'\033[0;32m'
  YELLOW=$'\033[0;33m'
  BLUE=$'\033[0;34m'
  PURPLE=$'\033[0;35m'
  CYAN=$'\033[0;36m'
  WHITE=$'\033[0;37m'
  BGreen=$'\033[1;32m'
  BCyan=$'\033[1;36m'
  BYellow=$'\033[1;33m'
  BBlue=$'\033[1;34m'
  BPurple=$'\033[1;35m'
  BRed=$'\033[1;31m'
  BWhite=$'\033[1;37m'
  NC=$'\033[0m'
  BOLD=$'\033[1m'
  UBORANGE=$'\e[38;5;166m'
  RLPURPLE=$'\e[38;5;104m'
  RMPURPLE=$'\e[38;5;98m'
  RDPURPLE=$'\e[38;5;55m'
  BUbOrange=$'\e[1m\e[38;5;166m'
  BRlPurple=$'\e[1m\e[38;5;104m'
  BRmPurple=$'\e[1m\e[38;5;98m'
  BRdPurple=$'\e[1m\e[38;5;55m'
fi

function echo_repo_config() {
  local uri_source="$1" suite="$2" sec="$3" selected_uri_dir="ubuntu" architectures
  case "$uri_source" in
    ports)
      selected_uri_source="ports"
      architectures="amd64 i386"
      selected_uri_dir="ubuntu-ports"
      ;;
    archive)
      selected_uri_source="archive"
      architectures="arm64"
      ;;
    security)
      selected_uri_source="security"
      architectures="arm64"
      ;;
    *)
      return 1
    ;;
  esac
  echo "Types: deb"
  echo "URIs: http://${selected_uri_source}.ubuntu.com/${selected_uri_dir}/"
  if [[ ${sec} == "security" ]]; then
    echo "Suites: ${suite}-security"
  else
    echo "Suites: ${suite} ${suite}-updates ${suite}-backports"
  fi
  echo "Components: main universe restricted multiverse"
  echo "Signed-By: /usr/share/keyrings/ubuntu-archive-keyring.gpg"
  echo "Architectures-Remove: ${architectures}"
  echo ""
}

function generate_sources() {
  if [[ $(dpkg --print-architecture) == "arm64" ]]; then
    echo_repo_config "ports" "./devel" | sudo tee /etc/apt/sources.list.d/ubuntu.sources > /dev/null
    echo_repo_config "ports" "./devel" "security" | sudo tee -a /etc/apt/sources.list.d/ubuntu.sources > /dev/null
  else
    echo_repo_config "archive" "./devel" | sudo tee /etc/apt/sources.list.d/ubuntu.sources > /dev/null
    echo_repo_config "security" "./devel" "security" | sudo tee -a /etc/apt/sources.list.d/ubuntu.sources > /dev/null
  fi
}

function cleanup() {
  local sources_file sources_bak
  if [[ -f "/etc/apt/sources.list.d/ubuntu.sources-rhino.bak" ]]; then
    sources_file="/etc/apt/sources.list.d/ubuntu.sources"
    sources_bak="${sources_file}-rhino.bak"
  elif [[ -f "/etc/apt/sources.list-rhino.bak" ]]; then
    sources_file="/etc/apt/sources.list"
    sources_bak="${sources_file}-rhino.bak"
  else
    unset sources_file sources_bak
  fi
  source /etc/os-release && \
  if [[ ${NAME} != "Rhino Linux" ]]; then
    if [[ -n "${sources_bak}" ]]; then
      echo "[${BCyan}~${NC}] ${BOLD}NOTE${NC}: Returning ${CYAN}${sources_file}${NC} backup..."
      sudo rm -f "${sources_file}"
      sudo mv "${sources_bak}" "${sources_file}"
      if [[ ${sources_file} == "/etc/apt/sources.list" ]]; then
        sudo rm -f /etc/apt/sources.list.d/ubuntu.sources
      fi
    fi
    if [[ -n ${OLD_VERSION_CODENAME} ]]; then
      if [[ ${VERSION_CODENAME} != "${OLD_VERSION_CODENAME}" ]]; then
        echo "[${BYellow}⚠${NC}] ${BOLD}CRITICAL${NC}: ${BCyan}lsb_release${NC} changed during install!"
        echo "  [${BBlue}>${NC}] Updating ${CYAN}${sources_file}${NC} entries to ${BPurple}${VERSION_CODENAME}${NC} to avoid system breakage."
        if [[ ${VERSION_CODENAME} == "devel" ]]; then
          sudo sed -i -E "s|(\s)${OLD_VERSION_CODENAME}|\1./devel|g" ${sources_file}
        else
          sudo sed -i -E "s|(\s)${OLD_VERSION_CODENAME}|\1${VERSION_CODENAME}|g" ${sources_file}
        fi
      fi
    fi
  else
    if [[ -n "${sources_bak}" ]]; then
      echo "[${BYellow}⚠${NC}] ${BOLD}CRITICAL${NC}: script exited, but ${BRmPurple}Rhino Linux${NC} appears to be installed."
      echo "  [${BBlue}>${NC}] Configuration likely incomplete. It is ${BOLD}highly${NC} recommended to re-run this script."
      echo "  [${BBlue}>${NC}] You should select the same options. A fast track will be provided."
      echo "  [${BBlue}>${NC}] Removing ${CYAN}${sources_file}${NC} backup to avoid system breakage."
      sudo rm -f "${sources_bak}"
      if ! grep devel /etc/apt/sources.list.d/ubuntu.sources >> /dev/null; then
        generate_sources
      fi
    fi
  fi
}

function test_compat() {
  local devarch
  if [[ -z $USER ]]; then
    export USER="$(whoami)"
  fi
  if [[ ${USER} == "root" ]]; then
    echo "[${BRed}!${NC}] ${BOLD}ERROR${NC}: ${BRmPurple}ub2r${NC} cannot be run as root!"
    exit 1
  fi
  devarch=${HOSTTYPE}
  if ! [[ ${devarch} == @(aarch64|arm64|x86_64|amd64) ]]; then
    echo "[${BRed}!${NC}] ${BOLD}ERROR${NC}: Rhino Linux only supports ${BCyan}amd64${NC} + ${BCyan}arm64${NC} as base architectures!"
    exit 1
  fi
}

function get_releaseinfo() {
  unset OLD_VERSION_CODENAME OLD_VERSION_ID OLD_NAME
  source /etc/os-release && \
  OLD_VERSION_CODENAME="${VERSION_CODENAME}"
  OLD_VERSION_ID="${VERSION_ID}"
  OLD_NAME="${NAME}"
  if [[ ${ID} != "ubuntu" ]]; then
    echo "[${BRed}!${NC}] ${BOLD}ERROR${NC}: not an ${BUbOrange}Ubuntu${NC}-based system!"
    exit 1
  elif [[ ${OLD_NAME} == "Ubuntu" ]]; then
    echo "[${BGreen}+${NC}] ${BOLD}INFO${NC}: detected an ${BUbOrange}Ubuntu${NC} system."
    echo "  [${BBlue}>${NC}] ${BOLD}VERSION ID${NC}: ${BYellow}${OLD_VERSION_ID}${NC}"
    echo "  [${BBlue}>${NC}] ${BOLD}CODENAME${NC}: ${BPurple}${OLD_VERSION_CODENAME}${NC}"
    echo "  [${BBlue}>${NC}] ${BOLD}USER${NC}: ${BCyan}${USER}${NC}"
  elif [[ ${OLD_NAME} == "Rhino Linux" ]]; then
    echo "[${BGreen}+${NC}] ${BOLD}INFO${NC}: detected a ${BRlPurple}Rhino Linux${NC} system."
    echo "  [${BBlue}>${NC}] ${BOLD}VERSION ID${NC}: ${BYellow}${OLD_VERSION_ID}${NC}"
    echo "  [${BBlue}>${NC}] ${BOLD}USER${NC}: ${BCyan}${USER}${NC}"
  else
    echo "[${BRed}!${NC}] ${BOLD}ERROR${NC}: not a ${BRlPurple}Rhino Linux${NC} compatible system!"
    exit 1
  fi
}

function ask() {
  local prompt default reply

  if [[ ${2-} == 'Y' ]]; then
    prompt="${BGreen}Y${NC}/${BRed}n${NC}"
    default='Y'
  elif [[ ${2-} == 'N' ]]; then
    prompt="${BGreen}y${NC}/${BRed}N${NC}"
    default='N'
  else
    prompt="${BGreen}y${NC}/${BRed}n${NC}"
  fi

  # Ask the question (not using "read -p" as it uses stderr not stdout)
  echo -ne "$1 [$prompt] "

  if [[ ${DISABLE_PROMPTS:-z} == "z" ]]; then
    export DISABLE_PROMPTS="no"
  fi

  if [[ $DISABLE_PROMPTS == "no" ]]; then
    read -r reply <&0
    # Detect if script is running non-interactively
    # Which implies that the input is being piped into the script
    if [[ $NON_INTERACTIVE ]]; then
      if [[ -z $reply ]]; then
        echo -n "$default"
      fi
      echo "$reply"
    fi
  else
    echo "$default"
    reply=$default
  fi

  # Default?
  if [[ -z $reply ]]; then
    reply=$default
  fi

  while :; do
    # Check if the reply is valid
    case "$reply" in
      Y* | y*)
        export answer=1
        return 0 #return code for backwards compatibility
        break
        ;;
      N* | n*)
        export answer=0
        return 1 #return code
        break
        ;;
      *)
        echo -ne "$1 [$prompt] "
        read -r reply < /dev/tty
        ;;
    esac
  done
}

function update_sources() {
  if ((${OLD_VERSION_ID%%.*} >= 24)) && [[ -f /etc/apt/sources.list.d/ubuntu.sources ]]; then
    echo "[${BYellow}*${NC}] ${BOLD}WARNING${NC}: Updating ${CYAN}/etc/apt/sources.list.d/ubuntu.sources${NC} entries to ${BPurple}./devel${NC}."
    echo "  [${BBlue}>${NC}] If you have any PPAs, they may break!"
    echo "  [${BBlue}>${NC}] Other sources contained in this file will be wiped."
    echo "  [${BBlue}>${NC}] A backup will be created while this script runs, and it will be restored if cancelled."
  else
    echo "[${BYellow}*${NC}] ${BOLD}WARNING${NC}: Updating ${CYAN}/etc/apt/sources.list${NC} entries to ${BPurple}./devel${NC}."
    echo "  [${BBlue}>${NC}] If you have any PPAs, they may break!"
    echo "  [${BBlue}>${NC}] Other sources contained in this file will be wiped."
    echo "  [${BBlue}>${NC}] A backup will be created while this script runs, and it will be restored if cancelled."
    echo "  [${BBlue}>${NC}] A new deb-822 source list will be created at ${CYAN}/etc/apt/sources.list.d/ubuntu.sources${NC}."
  fi
  ask "[${BYellow}*${NC}] Continue?" N
  if ((answer == 0)); then
    echo "[${BGreen}+${NC}] ${BOLD}INFO${NC}: No changes made. Exiting..."
    exit 0
  else
    if ((${OLD_VERSION_ID%%.*} >= 24)) && [[ -f /etc/apt/sources.list.d/ubuntu.sources ]]; then
      echo "[${BGreen}+${NC}] ${BOLD}INFO${NC}: Creating backup of ${CYAN}/etc/apt/sources.list.d/ubuntu.sources${NC}..."
      sudo cp /etc/apt/sources.list.d/ubuntu.sources /etc/apt/sources.list.d/ubuntu.sources-rhino.bak
      sudo sed -i -E "s|(\s)${OLD_VERSION_CODENAME}|\1./devel|g" /etc/apt/sources.list.d/ubuntu.sources
    else
      echo "[${BGreen}+${NC}] ${BOLD}INFO${NC}: Creating backup of ${CYAN}/etc/apt/sources.list${NC}..."
      sudo mv /etc/apt/sources.list /etc/apt/sources.list-rhino.bak
      generate_sources
    fi
  fi
  echo ""
}

function install_pacstall() {
  if ! [[ -f "/usr/bin/pacstall" ]]; then
    echo "[${BCyan}~${NC}] ${BOLD}NOTE${NC}: Installing Pacstall..."
    echo -e "Y\nN" | sudo bash -c "$(curl -fsSL https://pacstall.dev/q/install || wget -q https://pacstall.dev/q/install -O -)"
  fi
}

function unicorn_flavor() {
  sudo update-alternatives --install /usr/share/icons/default/index.theme x-cursor-theme /usr/share/icons/Quintom_Snow/cursor.theme 55
  sudo update-alternatives --install /usr/share/icons/default/index.theme x-cursor-theme /usr/share/icons/Quintom_Ink/cursor.theme 55
  sudo update-alternatives --install /usr/share/plymouth/themes/default.plymouth default.plymouth /usr/share/plymouth/themes/rhino-spinner/rhino-spinner.plymouth 100
  sudo update-alternatives --set default.plymouth /usr/share/plymouth/themes/rhino-spinner/rhino-spinner.plymouth
  sudo update-alternatives --set x-cursor-theme /usr/share/icons/Quintom_Ink/cursor.theme
  if ! grep kvantum /etc/environment >> /dev/null; then
    echo "export QT_STYLE_OVERRIDE=kvantum" | sudo tee -a /etc/environment > /dev/null
  fi
  if ! [[ -f /etc/lightdm/rhino-blur.png ]]; then
    sudo rm -f /etc/lightdm/lightdm-gtk-greeter.conf
    (cd /etc/lightdm/ && \
    sudo wget -q https://raw.githubusercontent.com/rhino-linux/lightdm/main/lightdm-gtk-greeter.conf && \
    sudo wget -q https://github.com/rhino-linux/lightdm/raw/main/rhino-blur.png)
  fi
  sudo mkdir -p /home/$USER/.config/Kvantum
  echo "theme=KvRhinoDark" | sudo tee /home/$USER/.config/Kvantum/kvantum.kvconfig > /dev/null
  sudo mkdir -p /home/$USER/.config/xfce4
  sudo mkdir -p /home/$USER/.config/Kvantum
  sudo cp -r /etc/skel/.config/xfce4/* /home/$USER/.config/xfce4
  sudo cp -r /etc/skel/.config/Kvantum/* /home/$USER/.config/Kvantum
  if ! [[ -f "/home/$USER/.config/xfce4/desktop/icons.screen.latest.rc" ]]; then
    sudo ln -s "/home/$USER/.config/xfce4/desktop/icons.screen0-1904x990.rc" "/home/$USER/.config/xfce4/desktop/icons.screen.latest.rc"
  fi
  sudo chmod -R 777 /home/$USER/.config/xfce4
  sudo chown $USER -cR /home/$USER/.config > /dev/null
}

function is_apt_package_installed() {
  if [[ $(dpkg-query -W --showformat='${db:Status-Status}' "${1}" 2> /dev/null) == "installed" ]]; then
    return 0
  else
    return 1
  fi
}

function select_core() {
  echo "[${BCyan}~${NC}] ${BOLD}NOTE${NC}: Rhino Linux has three versions of our app suite. Which would you like to install?"
  echo "  [${BBlue}>${NC}] ${BOLD}1)${NC} ${BPurple}rhino-server-core${NC}: TUI tool suite w/ basic development tools"
  echo "  [${BBlue}>${NC}] ${BOLD}2)${NC} ${BPurple}rhino-ubxi-core${NC}: TUI+GUI app suite w/ GTK applications"
  echo "  [${BBlue}>${NC}] ${BOLD}3)${NC} ${BPurple}rhino-core${NC}: Full suite w/ Unicorn Desktop Environment"
  unset packages core_package
  if ! is_apt_package_installed "nala"; then
    packages+=("nala-deb")
  fi
  while true; do
    read -p "[${BYellow}*${NC}] Enter your choice (${BGreen}1${NC}/${BGreen}2${NC}/${BGreen}3${NC}): " choice
    case $choice in
      1)
        core_package="rhino-server-core"
        packages+=("${core_package}")
        break
        ;;
      2)
        core_package="rhino-ubxi-core"
        packages+=("celeste-bin" "timeshift" "${core_package}")
        break
        ;;
      3)
        core_package="rhino-core"
        packages+=("celeste-bin" "timeshift" "quintom-cursor-theme-git" "${core_package}" "rhino-setup-bin")
        break
        ;;
      *) ;;
    esac
  done
  echo "[${BGreen}+${NC}] ${BOLD}INFO${NC}: Selected to install ${BPurple}${core_package}${NC}."
}

function select_kernel() {
  echo "[${BCyan}~${NC}] ${BOLD}NOTE${NC}: Rhino Linux ships two versions of the Ubuntu mainline kernel:"
  echo "  [${BBlue}>${NC}] ${BOLD}1)${NC} ${BPurple}linux-kernel${NC}: tracks the kernel ${YELLOW}mainline${NC} branch, with versions ${CYAN}X${NC}.${CYAN}X${NC}.${CYAN}0${NC}{${CYAN}-rcX${NC}}"
  echo "  [${BBlue}>${NC}] ${BOLD}2)${NC} ${BPurple}linux-kernel-stable${NC}: tracks the kernel ${YELLOW}stable${NC} branch, with versions ${CYAN}X${NC}.(${CYAN}X-1${NC}).${CYAN}X${NC}"
  echo "  [${BBlue}>${NC}] Would you like to install either of them? You can also say ${BRed}N${NC}/${BRed}n${NC} to remain on your current kernel."
  unset kern_package
  while true; do
    read -p "[${BYellow}*${NC}] Enter your choice (${BGreen}1${NC}/${BGreen}2${NC}/${BRed}N${NC}): " choice
    case $choice in
      1)
        kern_package="linux-kernel"
        break
        ;;
      2)
        kern_package="linux-kernel-stable"
        break
        ;;
      N | n)
        kern_package="none"
        break
        ;;
      *) ;;
    esac
  done
  if [[ ${kern_package} != "none" ]]; then
    echo "[${BGreen}+${NC}] ${BOLD}INFO${NC}: Selected to install ${BPurple}${kern_package}${NC}."
  else
    echo "[${BGreen}+${NC}] ${BOLD}INFO${NC}: Will not install any new kernels."
  fi
  echo ""
}

function is_package_installed() {
    local input="${1}"
    while read -r line; do
        if [[ ${line} == "${input}" ]]; then
            return 0
        fi
    done < <(pacstall -L)
    return 1
}

function install_packages() {
  local pkg
  install_pacstall || exit 1
  echo "[${BCyan}~${NC}] ${BOLD}NOTE${NC}: Upgrading packages, this may take a while..."
  sudo apt-get update --allow-releaseinfo-change && sudo DEBIAN_FRONTEND=noninteractive apt-get -o "Dpkg::Options::=--force-confold" dist-upgrade -y --allow-remove-essential --allow-change-held-packages || exit 1
  if [[ ${kern_package} != "none" ]]; then
    echo "[${BCyan}~${NC}] ${BOLD}NOTE${NC}: Installing ${BPurple}${kern_package}${NC}..."
    pacstall -PI ${kern_package} || exit 1
  else
    echo "[${BCyan}~${NC}] ${BOLD}NOTE${NC}: Not installing any kernels."
  fi
  echo "[${BCyan}~${NC}] ${BOLD}NOTE${NC}: Installing ${BPurple}${core_package}${NC} suite..."
  for pkg in "${packages[@]}"; do
    if [[ ${pkg} == "${core_package}" ]]; then
      pacstall -PI ${pkg} || exit 1
      if [[ ${pkg} == "rhino-core" ]]; then
        sudo apt install lightdm-gtk-greeter -yq || exit 1
        unicorn_flavor || exit 1
      fi
    elif ! is_package_installed "${pkg}"; then
      pacstall -PI ${pkg} || exit 1
    else
      echo "[${BGreen}+${NC}] ${BOLD}INFO${NC}: ${BPurple}${pkg}${NC} is already installed."
    fi
  done
}

test_compat
echo -e "${RDPURPLE}┌─────────────────────────────┐\n│${NC}       Welcome to ${BRlPurple}ub2r${NC}       ${RDPURPLE}│\n│${NC}      A tool to convert      ${RDPURPLE}│\n│${NC}    ${BUbOrange}Ubuntu${NC} to ${BRmPurple}Rhino Linux${NC}    ${RDPURPLE}│\n└─────────────────────────────┘${NC}"
get_releaseinfo
echo "[${BCyan}~${NC}] ${BOLD}NOTE${NC}: You may be asked to enter your password more than once."
sleep 1
echo ""

if [[ ${OLD_NAME} != "Rhino Linux" ]]; then
  trap "cleanup && exit 1" EXIT
  trap "cleanup && exit 1" INT
  update_sources || {
    cleanup
    exit 1
  }
  if grep "Raspberry Pi" /proc/cpuinfo >> /dev/null; then
    kern_package="none"
  else
    select_kernel || {
      cleanup
      exit 1
    }
  fi
  select_core || {
    cleanup
    exit 1
  }
  echo "[${BGreen}+${NC}] ${BOLD}INFO${NC}: All set! We'll do the rest. Starting in 3 seconds..."
  sleep 3
  echo ""
  if install_packages; then
    if ((${OLD_VERSION_ID%%.*} >= 24)) && [[ -f /etc/apt/sources.list.d/ubuntu.sources-rhino.bak ]]; then
      echo "[${BCyan}~${NC}] ${BOLD}NOTE${NC}: Removing ${CYAN}/etc/apt/sources.list.d/ubuntu.sources${NC} backup..."
      sudo rm -f /etc/apt/sources.list.d/ubuntu.sources-rhino.bak
    else
      echo "[${BCyan}~${NC}] ${BOLD}NOTE${NC}: Removing ${CYAN}/etc/apt/sources.list${NC} backup..."
      sudo rm -f /etc/apt/sources.list-rhino.bak
    fi
    neofetch --ascii_distro rhino_small
    echo "[${BGreen}+${NC}] ${BOLD}INFO${NC}: ${BGreen}Finished${NC}! You can now use ${BRmPurple}rhino-pkg${NC}/${BRlPurple}rpk${NC} to manage your packages."
    echo "  [${BBlue}>${NC}] Be sure to reboot when you are done checking it out!"
  else
    cleanup
    exit 1
  fi
else
  echo "[${BGreen}+${NC}] ${BOLD}INFO${NC}: Rhino Linux appears to already be installed."
  ask "[${BYellow}*${NC}] Do you want to change kernels and/or suites?" N
  if ((answer == 0)); then
    echo "[${BCyan}~${NC}] No changes made. Exiting..."
    exit 0
  else
    if grep "Raspberry Pi" /proc/cpuinfo >> /dev/null; then
      kern_package="none"
    else
      select_kernel || exit 1
    fi
    select_core || exit 1
    echo "[${BGreen}+${NC}] ${BOLD}INFO${NC}: All set! Starting in 3 seconds..."
    sleep 3
    echo ""
    if install_packages; then
      neofetch --ascii_distro rhino_small
      echo "[${BGreen}+${NC}] ${BOLD}INFO${NC}: ${BGreen}Finished${NC}! Be sure to reboot if you installed any new kernels."
    else
      exit 1
    fi
  fi
fi
