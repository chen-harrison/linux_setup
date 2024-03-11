#!/usr/bin/env bash

sudo apt update

# Necessary packages for installation
sudo apt install -y curl gpg

# Foxglove Studio
foxglove_deb=$(curl -s "https://api.github.com/repos/foxglove/studio/releases/latest" | grep '"browser_download_url":.*linux-amd64.deb' | sed -E 's/.*"([^"]+)".*/\1/')
echo $foxglove_deb
wget -O foxglove-studio.deb "$foxglove_deb"
sudo dpkg -i foxglove-studio.deb
rm foxglove-studio.deb

# (Optional) uninstall Docker
read -r -p "Do you want to uninstall an existing version of Docker [y/N]? "
if [[ "$REPLY" =~ ^[yY]$ ]] ; then
    echo "Attempting to uninstall Docker"
    sudo apt-get purge -y \
    docker-ce \
    docker-ce-cli \
    containerd.io \
    docker-buildx-plugin \
    docker-compose-plugin \
    docker-ce-rootless-extras

    sudo rm -rf /var/lib/docker
    sudo rm -rf /var/lib/containerd
fi

# Install Docker
for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do sudo apt-get remove $pkg; done

sudo apt-get update
sudo apt-get install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
    $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
    sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update

sudo apt-get install -y \
    docker-ce \
    docker-ce-cli \
    containerd.io \
    docker-buildx-plugin \
    docker-compose-plugin

(sudo groupadd docker && sudo usermod -aG docker $USER && newgrp docker) || true

# Nvidia Container Toolkit (?)
curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg \
    && curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \
        sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
        sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list

sudo apt-get update
sudo apt-get install -y nvidia-container-toolkit

sudo nvidia-ctk runtime configure --runtime=docker
sudo systemctl restart docker

docker run --rm --runtime=nvidia --gpus all ubuntu nvidia-smi