#!/bin/bash

# Update the system
sudo apt-get update -y

# Install packages needed for adding a new repository over HTTPS
sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common

# Add Docker's official GPG key
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

# Add the Docker repository
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"

# Update the package database with Docker packages from the newly added repo
sudo apt-get update -y

# Install Docker
sudo apt-get install -y docker-ce docker-ce-cli containerd.io

# Start Docker and set it to automatically start on boot
sudo systemctl start docker
sudo systemctl enable docker

# Add the current user to the docker group (optional)
sudo usermod -aG docker $(whoami)

# Install Docker Compose
# Note: Check https://github.com/docker/compose/releases for the latest version
sudo curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
sudo ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose

# Output the version to confirm installation
docker --version
docker-compose --version
