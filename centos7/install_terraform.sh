#!/bin/bash

# Specify the desired version of Terraform
TERRAFORM_VERSION="1.6.6"  # Update this to the version you want

# Downloading the specified version of Terraform
wget "https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip"

# Unzipping the Terraform package
sudo unzip "terraform_${TERRAFORM_VERSION}_linux_amd64.zip" -d /usr/local/bin/

# Removing the downloaded zip file
rm -f "terraform_${TERRAFORM_VERSION}_linux_amd64.zip"

# Verifying the installation
terraform -v

echo "Terraform version ${TERRAFORM_VERSION} installed successfully."
