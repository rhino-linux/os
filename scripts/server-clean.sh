#!/bin/bash

mv /etc/resolv.conf /etc/resolv2.conf
echo "nameserver 1.1.1.1" > /etc/resolv.conf

export DEBIAN_FRONTEND=noninteractive
export DEBCONF_NONINTERACTIVE_SEEN=true

apt-get update
echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers
SUDO_USER=rhino pacstall -QPINs rhino-server-core
sed -i 's/%sudo ALL=(ALL) NOPASSWD:ALL//' /etc/sudoers
apt-get remove -yq gnome-disk-utility dconf-editor firefox codium rclone-browser ulauncher rhino-setup quintom-cursor-theme network-manager-gnome lightdm lightdm-gtk-greeter thunar thunar-volman *xfce4* xfdesktop4 xfwm4 xorg x11-common mousepad mugshot mpv xubuntu-default-settings libglib2.0-bin kwayland-integration *kf5* *kf6* *qt5* *qt6* unicorn-desktop rhino-kvantum-theme rhino-plymouth-theme hello-rhino
apt-get autoremove -y
echo "neofetch" >> /home/rhino/.bashrc

rm /etc/resolv.conf
mv /etc/resolv2.conf /etc/resolv.conf
