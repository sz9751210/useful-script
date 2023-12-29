#!/bin/bash

# Define the specific version of Python 3 you want to install
PYTHON_VERSION="3.9.1"

# Check the distribution
if [ -f /etc/redhat-release ]; then
    # CentOS
    sudo yum groupinstall -y "Development Tools"
    sudo yum install -y openssl-devel bzip2-devel libffi-devel
elif [ -f /etc/lsb-release ]; then
    # Ubuntu
    sudo apt-get update -y
    sudo apt-get install -y build-essential libssl-dev libbz2-dev libffi-dev
else
    echo "Unsupported distribution. Exiting."
    exit 1
fi

# Download Python source
cd /usr/src
sudo wget https://www.python.org/ftp/python/$PYTHON_VERSION/Python-$PYTHON_VERSION.tgz
if [ $? -ne 0 ]; then
    echo "Download failed. Exiting."
    exit 1
fi

# Extract the downloaded package
sudo tar xzf Python-$PYTHON_VERSION.tgz

# Compile Python Source
cd Python-$PYTHON_VERSION
sudo ./configure --enable-optimizations
sudo make altinstall

# Remove the downloaded source archive
sudo rm /usr/src/Python-$PYTHON_VERSION.tgz

if [ -f "/usr/local/bin/python3" ]; then
    echo "A python3 executable already exists. Exiting."
    exit 1
fi

# Create a symbolic link to python3.9
sudo ln -sf /usr/local/bin/python${PYTHON_VERSION:0:3} /usr/local/bin/python3
sudo ln -sf /usr/local/bin/pip${PYTHON_VERSION:0:3} /usr/local/bin/pip3

# Optional: Check Python version
python3 --version
