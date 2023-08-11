#!/bin/bash

#intended for new debian system/vm/container
#installs common cosmos SDK dependencies, QOL tools, sets PATH/GOPATH+

set -e  # Exit immediately if a command exits with a non-zero status

# Update and upgrade the system
apt-get update > /dev/null && apt-get upgrade -y > /dev/null

# Install required packages
apt-get install nano make build-essential gcc git jq chrony tar curl lz4 wget -y > /dev/null

# Check if Go is installed
if ! command -v go &> /dev/null; then
    # Download and install Go
    wget -q https://go.dev/dl/go1.20.linux-amd64.tar.gz
    tar -C /usr/local -xzf go1.20.linux-amd64.tar.gz
    rm go1.20.linux-amd64.tar.gz
    
    # Add environment variables to ~/.bashrc
    echo -e "export GOROOT=/usr/local/go\nexport GOPATH=\$HOME/go\nexport GO111MODULE=on\nexport PATH=\$PATH:/usr/local/go/bin:\$HOME/go/bin" >> ~/.bashrc
    source ~/.bashrc
fi
