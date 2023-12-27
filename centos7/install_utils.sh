#!/bin/bash

# Update the package repository
sudo yum update -y

# Install curl
sudo yum install curl -y

# Install wget
sudo yum install wget -y

# Install telnet
sudo yum install telnet -y

# Check the installations
echo "Installed versions:"
curl --version | head -1
wget --version | head -1
yum list installed | grep telnet
