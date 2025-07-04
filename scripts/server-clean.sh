#!/bin/bash

mv /etc/resolv.conf /etc/resolv2.conf
echo "nameserver 1.1.1.1" > /etc/resolv.conf

export DEBIAN_FRONTEND=noninteractive
export DEBCONF_NONINTERACTIVE_SEEN=true

apt-get update
echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers
SUDO_USER=rhino pacstall -QPINs rhino-server-core
sed -i 's/%sudo ALL=(ALL) NOPASSWD:ALL//' /etc/sudoers
apt-get remove -yq gnome-disk-utility dconf-editor firefox codium rclone-browser ulauncher rhino-setup quintom-cursor-theme network-manager-gnome lightdm lightdm-gtk-greeter thunar thunar-volman xfce4-goodies xfce4-appfinder xfce4-notifyd xfce4-panel xfce4-terminal xfce4-session xfce4-settings xfdesktop4 xfwm4 xorg x11-common mousepad qt5-style-kvantum qt5-style-kvantum-themes mugshot mpv xubuntu-default-settings libglib2.0-bin kwayland-integration libkf5waylandclient5 libkf5windowsystem5 libqt5waylandclient5 libqt5widgets5 libqt5widgets5t64 libqt5svg5 libqt5x11extras5 libqt5waylandcompositor5 libqt5quick5-gles qt5-gtk-platformtheme unicorn-desktop rhino-kvantum-theme rhino-plymouth-theme hello-rhino
apt-get autoremove -y
echo "neofetch" >> /home/rhino/.bashrc

rm /etc/resolv.conf
mv /etc/resolv2.conf /etc/resolv.conf
