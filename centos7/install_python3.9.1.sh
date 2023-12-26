#!/bin/bash

# Define the specific version of Python 3 you want to install
PYTHON_VERSION="3.9.1"

# Install development tools and libraries required for building Python
sudo yum groupinstall -y "Development Tools"
sudo yum install -y openssl-devel bzip2-devel libffi-devel

# Download Python source
cd /usr/src
sudo wget https://www.python.org/ftp/python/$PYTHON_VERSION/Python-$PYTHON_VERSION.tgz

# Extract the downloaded package
sudo tar xzf Python-$PYTHON_VERSION.tgz

# Compile Python Source
cd Python-$PYTHON_VERSION
sudo ./configure --enable-optimizations
sudo make altinstall

# Remove the downloaded source archive
sudo rm /usr/src/Python-$PYTHON_VERSION.tgz

# Create a symbolic link to python3.9
sudo ln -sf /usr/local/bin/python3.9 bin/python3

sudo ln -sf /usr/local/bin/pip3.9 bin/pip3

# Optional: Check Python version
python3 --version
