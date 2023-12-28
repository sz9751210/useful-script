#!/bin/bash

# Update the system
sudo yum update -y

# Download the AWS CLI bundle
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"

# Unzip the downloaded package
unzip awscliv2.zip

# Run the install script
sudo ./aws/install

# Verify the installation
aws --version
