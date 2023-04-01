#!/bin/bash

mv /etc/resolv.conf /etc/resolv2.conf
echo "nameserver 1.1.1.1" > /etc/resolv.conf

export DEBIAN_FRONTEND=noninteractive
export DEBCONF_NONINTERACTIVE_SEEN=true

apt-get update
apt-get remove -yq gnome-disk-utility dconf-editor firefox codium ulauncher rhino-setup quintom-cursor-theme gparted network-manager-gnome lightdm lightdm-gtk-greeter thunar thunar-volman xfce4-goodies xfce4-appfinder xfce4-notifyd xfce4-panel xfce4-terminal xfce4-session xfce4-settings xfdesktop4 xfwm4 xorg x11-common mousepad qt5-style-kvantum qt5-style-kvantum-themes mugshot mpv xubuntu-default-settings libglib2.0-bin

echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers
HOME=/home/rhino runuser -l rhino -c 'SUDO_USER=rhino PACSTALL_DOWNLOADER=quiet-wget pacstall -PI rhino-pkg-git rhino-neofetch-git'
sed -i 's/%sudo ALL=(ALL) NOPASSWD:ALL//' /etc/sudoers

apt-get autoremove -y

rm /etc/resolv.conf
mv /etc/resolv2.conf /etc/resolv.conf
