#!/bin/bash

export BASEDIR=$(pwd)
export DEBIAN_FRONTEND=noninteractive
export PACSTALL_DOWNLOADER=quiet-wget
export GITHUB_ACTIONS=true

# first, set sources list
VERSON_CODENAME="$(lsb_release -sc 2> /dev/null)"
if ! [[ $VERSION_CODENAME == "devel" ]]; then
sudo sed -i 's/$VERSION_CODENAME/.\/devel/g' /etc/apt/sources.list; fi
sudo apt-get update && sudo apt-get dist-upgrade -y

# then, install pacstall
curl -fsSL https://git.io/JsADh > pacstall-install.sh
chmod +x ./pacstall-install.sh
echo N\n | sudo -E ./pacstall-install.sh
rm ./pacstall-install.sh

# now custom packages
if [ $(dpkg --print-architecture) = arm64 ]; then 
FIREFOX="firefox-arm64-deb"; 
else FIREFOX="firefox-bin"; 
fi; 
pacstall -PI rhino-core nala-deb ${FIREFOX} vscodium-deb ulauncher-deb linux-kernel-stable quintom-cursor-theme-git rhino-setup-bin

#Hack: arm64 firefox no snap
if [ $(dpkg --print-architecture) = arm64 ]; then
sudo touch rhino.pref
echo "" >> rhino.pref
echo "Package: firefox" >> rhino.pref
echo "Pin: origin ports.ubuntu.com/ubuntu-ports" >> rhino.pref
echo "Pin: release o=Ubuntu" >> rhino.pref
echo "Pin-Priority: 1" >> rhino.pref
sudo mv rhino.pref /etc/apt/preferences.d/; fi

# put it all together
sudo update-alternatives --install /usr/share/icons/default/index.theme x-cursor-theme /usr/share/icons/Quintom_Snow/cursor.theme 55
sudo update-alternatives --install /usr/share/icons/default/index.theme x-cursor-theme /usr/share/icons/Quintom_Ink/cursor.theme 55
sudo update-alternatives --install /usr/share/plymouth/themes/default.plymouth default.plymouth /usr/share/plymouth/themes/rhino-spinner/rhino-spinner.plymouth 100
sudo update-alternatives --set default.plymouth /usr/share/plymouth/themes/rhino-spinner/rhino-spinner.plymouth
sudo update-alternatives --set x-cursor-theme /usr/share/icons/Quintom_Ink/cursor.theme
echo "export QT_STYLE_OVERRIDE=kvantum" | sudo tee -a /etc/environment > /dev/null
mkdir -p /home/$USER/.config/Kvantum
echo "theme=KvRhinoDark" >> /home/$USER/.config/Kvantum/kvantum.kvconfig
xfconf-query -c xsettings -p /Net/ThemeName --set Yaru-purple-dark
xfconf-query -c xsettings -p /Gtk/CursorThemeName -s Quintom_Ink
gsettings set org.gnome.desktop.interface gtk-theme Yaru-purple
xfconf-query -c xfwm4 -p /general/theme -s Yaru-dark
mkdir -p /home/$USER/.config/ulauncher/
cd /etc/skel/.config/ulauncher/ && git clone --depth=1 https://github.com/oklopfer/rhino-ulauncher/ .
cp -rf /etc/skel/.config/ulauncher/* /home/$USER/.config/ulauncher/
cd $BASEDIR
mkdir /home/$USER/.config/autostart/
cp /usr/share/applications/ulauncher.desktop /home/$USER/.config/autostart/ulauncher.desktop
sudo rm /etc/lightdm/lightdm-gtk-greeter.conf
( cd /etc/lightdm/ && sudo wget https://raw.githubusercontent.com/rhino-linux/lightdm/main/lightdm-gtk-greeter.conf && sudo wget https://github.com/rhino-linux/lightdm/raw/main/rhino-blur.png )
wget https://ThiagoLcioBittencourt.gallery.vsassets.io/_apis/public/gallery/publisher/ThiagoLcioBittencourt/extension/omni-dracula-theme/1.0.7/assetbyname/Microsoft.VisualStudio.Services.VSIXPackage && mv Microsoft.VisualStudio.Services.VSIXPackage /home/$USER/omni-dracula.vsix
sudo chown -cR $USER /home/$USER/omni-dracula.vsix
sudo mkdir /home/$USER/.config/VSCodium/
sudo mkdir /home/$USER/.config/VSCodium/User/
sudo chown -cR $USER /home/$USER/.config/VSCodium/
codium --install-extension /home/$USER/omni-dracula.vsix
rm /home/$USER/omni-dracula.vsix
sudo echo '{
    "workbench.colorTheme": "Omni Dracula Theme"
}' | sudo tee -a /home/$USER/.config/
sudo chown -cR $USER /home/$USER/.config/VSCodium/
rm -rf /home/$USER/.config/xfce4
mkdir -p /home/$USER/.config/xfce4
mkdir -p /home/$USER/.config/Kvantum
cp -r /etc/skel/.config/xfce4/* /home/$USER/.config/xfce4
cp -r /etc/skel/.config/Kvantum/* /home/$USER/.config/Kvantum
ln -s "/home/$USER/.config/xfce4/desktop/icons.screen0-1904x990.rc" "/home/$USER/.config/xfce4/desktop/icons.screen.latest.rc"
chmod -R 777 /home/$USER/.config/xfce4
sudo chown $USER -cR /home/$USER/Desktop
sudo chown $USER -cR /home/$USER/.config
