#!/bin/bash

sudo apt-get update && sudo apt-get install wget ca-certificates curl -y
wget https://download.docker.com/linux/ubuntu/dists/kinetic/pool/stable/arm64/containerd.io_1.6.18-1_arm64.deb
wget https://download.docker.com/linux/ubuntu/dists/kinetic/pool/stable/arm64/docker-buildx-plugin_0.10.2-1~ubuntu.22.10~kinetic_arm64.deb
wget https://download.docker.com/linux/ubuntu/dists/kinetic/pool/stable/arm64/docker-ce-cli_23.0.1-1~ubuntu.22.10~kinetic_arm64.deb
wget https://download.docker.com/linux/ubuntu/dists/kinetic/pool/stable/arm64/docker-ce-rootless-extras_23.0.1-1~ubuntu.22.10~kinetic_arm64.deb
wget https://download.docker.com/linux/ubuntu/dists/kinetic/pool/stable/arm64/docker-ce_23.0.1-1~ubuntu.22.10~kinetic_arm64.deb
wget https://download.docker.com/linux/ubuntu/dists/kinetic/pool/stable/arm64/docker-compose-plugin_2.16.0-1~ubuntu.22.10~kinetic_arm64.deb
sudo dpkg -i docker*.deb containerd*.deb
sudo rm *.deb
sudo service docker start
