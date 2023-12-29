#!/bin/bash

# Function to install Docker on CentOS
install_docker_centos() {
    # Update the system
    sudo yum update -y

    # Install required packages
    sudo yum install -y yum-utils device-mapper-persistent-data lvm2

    # Add Docker's official YUM repository
    sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo

    # Install Docker
    sudo yum install -y docker-ce docker-ce-cli containerd.io
}

# Function to install Docker on Ubuntu
install_docker_ubuntu() {
    # Update the system
    sudo apt-get update -y

    # Install required packages
    sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common

    # Add Docker's official APT repository
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
    sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"

    # Install Docker
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io
}

# Check for distribution and call the appropriate install function
if [ -f /etc/centos-release ]; then
    install_docker_centos
elif [ -f /etc/lsb-release ]; then
    install_docker_ubuntu
else
    echo "Unsupported distribution"
    exit 1
fi

# Start Docker and enable it to start on boot
sudo systemctl start docker
sudo systemctl enable docker

# Optionally, add the current user to the docker group
sudo usermod -aG docker $(whoami)

# Install Docker Compose
# Note: Check https://github.com/docker/compose/releases for the latest version
sudo curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
sudo ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose

# Output versions to confirm successful installation
docker --version
docker-compose --version
