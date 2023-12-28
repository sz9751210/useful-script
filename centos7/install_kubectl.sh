#!/bin/bash

# Set the Kubernetes version to the latest stable
KUBECTL_VERSION=$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)

# Download the kubectl binary
curl -LO "https://storage.googleapis.com/kubernetes-release/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl"

# Make the kubectl binary executable
chmod +x ./kubectl

# Move the binary to a directory in your PATH
sudo mv ./kubectl /usr/local/bin/kubectl

# Verify the installation
kubectl version --client
