#!/bin/bash

# Colors
if [[ -z $NO_COLOR ]]; then
  export RED=$'\033[0;31m'
  export GREEN=$'\033[0;32m'
  export YELLOW=$'\033[0;33m'
  export BLUE=$'\033[0;34m'
  export PURPLE=$'\033[0;35m'
  export CYAN=$'\033[0;36m'
  export WHITE=$'\033[0;37m'
  export BGreen=$'\033[1;32m'
  export BCyan=$'\033[1;36m'
  export BYellow=$'\033[1;33m'
  export BPurple=$'\033[1;35m'
  export BRed=$'\033[1;31m'
  export BWhite=$'\033[1;37m'
  export NC=$'\033[0m'
fi

function cleanup() {
  if [[ -f "/etc/apt/sources.list-rhino.bak" ]]; then
    echo "[${BCyan}~${NC}] ${BCyan}NOTE${NC}: Returning ${CYAN}/etc/apt/sources.list${NC} backup"
    sudo rm -f /etc/apt/sources.list
    sudo mv /etc/apt/sources.list-rhino.bak /etc/apt/sources.list
  fi
}

function get_releaseinfo() {
  source /etc/os-release
  if [[ ${ID} != "ubuntu" ]]; then
    echo "[${BRed}x${NC}] ${BRed}Error${NC}: not an Ubuntu system!"
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
  echo "[${BYellow}*${NC}] ${BYellow}WARNING${NC}: Updating ${CYAN}/etc/apt/sources.list${NC} entries to ${BPurple}./devel${NC}. If you have any PPAs, they may break!"
  ask "[${BYellow}*${NC}] Continue?" N
  if ((answer == 0)); then
    echo "[${BCyan}~${NC}] ${BCyan}NOTE${NC}: No changes made. Exiting..."
    exit 0
  else
    echo "[${BCyan}~${NC}] ${BCyan}NOTE${NC}: Creating backup of ${CYAN}/etc/apt/sources.list${NC} at ${CYAN}/etc/apt/sources.list-rhino.bak${NC}"
    sudo cp /etc/apt/sources.list /etc/apt/sources.list-rhino.bak
    source_codename=$(grep 'deb.*http.*ubuntu' /etc/apt/sources.list | head -n1 | awk '{print $3}')
    sudo sed -i -E "s|(\s)${VERSION_CODENAME}|\1./devel|g" /etc/apt/sources.list
    sudo sed -i -E "s|(\s)${source_codename}|\1./devel|g" /etc/apt/sources.list
  fi
  sudo apt-get update \
    && if [[ ${VERSION_CODENAME} != "devel" ]]; then
      echo "[${BYellow}*${NC}] ${BYellow}WARNING${NC}: Updating ${BPurple}base-files${NC} to latest version. This can't be undone!"
      ask "[${BYellow}*${NC}] Continue?" N
        if ((answer == 0)); then
          echo "[${BCyan}~${NC}] ${BCyan}NOTE${NC}: Not installing. Exiting..."
          exit 0
        else
          sudo apt-get install base-files -yq
        fi
    fi
}

function install_pacstall() {
  if ! [[ -f "/usr/bin/pacstall" ]]; then
    echo "[${BCyan}~${NC}] ${BCyan}NOTE${NC}: Installing Pacstall..."
    sudo bash -c "$(curl -fsSL https://pacstall.dev/q/install || wget -q https://pacstall.dev/q/install -O -)"
  fi
}

function unicorn_flavor() {
  sudo update-alternatives --install /usr/share/icons/default/index.theme x-cursor-theme /usr/share/icons/Quintom_Snow/cursor.theme 55
  sudo update-alternatives --install /usr/share/icons/default/index.theme x-cursor-theme /usr/share/icons/Quintom_Ink/cursor.theme 55
  sudo update-alternatives --install /usr/share/plymouth/themes/default.plymouth default.plymouth /usr/share/plymouth/themes/rhino-spinner/rhino-spinner.plymouth 100
  sudo update-alternatives --set default.plymouth /usr/share/plymouth/themes/rhino-spinner/rhino-spinner.plymouth
  sudo update-alternatives --set x-cursor-theme /usr/share/icons/Quintom_Ink/cursor.theme
  echo "export QT_STYLE_OVERRIDE=kvantum" | sudo tee -a /etc/environment > /dev/null
  mkdir -p /home/$USER/.config/Kvantum
  echo "theme=KvRhinoDark" >> /home/$USER/.config/Kvantum/kvantum.kvconfig
  sudo rm /etc/lightdm/lightdm-gtk-greeter.conf
  (cd /etc/lightdm/ && sudo wget https://raw.githubusercontent.com/rhino-linux/lightdm/main/lightdm-gtk-greeter.conf && sudo wget https://github.com/rhino-linux/lightdm/raw/main/rhino-blur.png)
  rm -rf /home/$USER/.config/xfce4
  mkdir -p /home/$USER/.config/xfce4
  mkdir -p /home/$USER/.config/Kvantum
  cp -r /etc/skel/.config/xfce4/* /home/$USER/.config/xfce4
  cp -r /etc/skel/.config/Kvantum/* /home/$USER/.config/Kvantum
  ln -s "/home/$USER/.config/xfce4/desktop/icons.screen0-1904x990.rc" "/home/$USER/.config/xfce4/desktop/icons.screen.latest.rc"
  chmod -R 777 /home/$USER/.config/xfce4
  sudo chown $USER -cR /home/$USER/.config
}

function install_core() {
  echo "[${BCyan}~${NC}] ${BCyan}NOTE${NC}: Rhino Linux has three versions of our app suite. Which would you like to install?"
  echo "[${BCyan}~${NC}] ${BWhite}1)${NC} ${BPurple}rhino-server-core${NC}: TUI tool suite w/ basic development tools"
  echo "[${BCyan}~${NC}] ${BWhite}2)${NC} ${BPurple}rhino-ubxi-core${NC}: TUI+GUI app suite w/ GTK applications"
  echo "[${BCyan}~${NC}] ${BWhite}3)${NC} ${BPurple}rhino-core${NC}: Full suite w/ Unicorn Desktop Environment"
  while true; do
    read -p "[${BYellow}*${NC}] Enter your choice (${BGreen}1${NC}/${BGreen}2${NC}/${BGreen}3${NC}): " choice
    case $choice in
      1)
        packages=("rhino-server-core" "nala-deb")
        break
        ;;
      2)
        packages=("rhino-ubxi-core" "nala-deb")
        break
        ;;
      3)
        packages=("rhino-core" "quintom-cursor-theme-git" "rhino-setup-bin" "nala-deb")
        break
        ;;
      *) ;;
    esac
  done
  echo "Installing ${BPurple}${packages[0]}${NC} suite..."
  pacstall -I ${packages[*]} || exit 1
  if [[ ${packages[0]} == "rhino-core" ]]; then
    unicorn_flavor
  fi
}

function install_kernel() {
  echo "[${BCyan}~${NC}] ${BCyan}NOTE${NC}: Rhino Linux ships two versions of the Ubuntu mainline kernel:"
  echo "[${BCyan}~${NC}] ${BWhite}1)${NC} ${BPurple}linux-kernel${NC}: tracks the kernel ${YELLOW}mainline${NC} branch, with versions ${CYAN}X${NC}.${CYAN}X${NC}.${CYAN}0${NC}{${CYAN}-rcX${NC}}"
  echo "[${BCyan}~${NC}] ${BWhite}2)${NC} ${BPurple}linux-kernel-stable${NC}: tracks the kernel ${YELLOW}stable${NC} branch, with versions ${CYAN}X${NC}.(${CYAN}X-1${NC}).${CYAN}X${NC}"
  echo "[${BCyan}~${NC}] Would you like to install either of them? You can also say ${BRed}N${NC}/${BRed}n${NC} to remain on your current kernel."
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
    echo "Installing ${BPurple}${kern_package}${NC}..."
    pacstall -I ${kern_package} || exit 1
  else
    echo "[${BCyan}~${NC}] Not installing any kernels."
  fi
}

get_releaseinfo
install_pacstall || exit 1

if [[ ${NAME} != "Rhino Linux" ]]; then
  trap "cleanup && exit 1" EXIT
  trap "cleanup && exit 1" INT
  update_sources || {
    cleanup
    exit 1
  }
  install_kernel || {
    cleanup
    exit 1
  }
  if install_core; then
    echo "[${BYellow}*${NC}] ${BYellow}WARNING${NC}: Removing ${CYAN}/etc/apt/sources.list${NC} backup"
    sudo rm -f /etc/apt/sources.list-rhino.bak
    echo "[${BCyan}~${NC}] ${BCyan}NOTE${NC}: You can now run ${BPurple}rpk update${NC} to update the rest of your packages."
    echo "[${BCyan}~${NC}] Be sure to reboot when you are done!"
  else
    cleanup
    exit 1
  fi
else
  echo "[${BYellow}*${NC}] ${BYellow}WARNING${NC}: Rhino Linux appears to already be installed."
  ask "[${BYellow}*${NC}] Do you want to change suites?" N
  if ((answer == 0)); then
    echo "[${BCyan}~${NC}] No changes made. Exiting..."
    exit 0
  else
    install_core || exit 1
  fi
fi
