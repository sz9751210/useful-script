#!/bin/bash

# Specify the version of Go you want to install
GO_VERSION="1.21.5"

# Download URL for the Go binary
DOWNLOAD_URL="https://dl.google.com/go/go${GO_VERSION}.linux-amd64.tar.gz"

# Remove any previous installation of Go
sudo rm -rf /usr/local/go

# Download and extract Go binary
wget ${DOWNLOAD_URL}
sudo tar -C /usr/local -xzf go${GO_VERSION}.linux-amd64.tar.gz
rm go${GO_VERSION}.linux-amd64.tar.gz

# Set up Go environment variables
echo "export PATH=\$PATH:/usr/local/go/bin" >> ~/.bash_profile
echo "export GOPATH=\$HOME/go" >> ~/.bash_profile
source ~/.bash_profile

# Check Go version
go version
