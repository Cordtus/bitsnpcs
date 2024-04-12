#!/bin/bash
# Script intended for new debian system/vm/container
# Installs common cosmos SDK dependencies, QOL tools, sets PATH/GOPATH+

# Exit if any command fails
set -e

# Ensure the script is run as root
if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as root."
    exit 1
fi

# Update and upgrade packages silently
apt-get update > /dev/null && apt-get upgrade -y > /dev/null

# Install required packages
apt-get install nano make build-essential gcc git jq chrony tar curl lz4 wget -y > /dev/null

# Install Go if it's not installed
if ! command -v go &> /dev/null; then
    wget -q https://go.dev/dl/go1.20.linux-amd64.tar.gz
    tar -C /usr/local -xzf go1.20.linux-amd64.tar.gz
    rm go1.20.linux-amd64.tar.gz
fi

# Configure Go environment variables if they're not already set
if ! grep -q "export GOROOT=" ~/.bashrc; then
    echo "export GOROOT=/usr/local/go" >> ~/.bashrc
fi
if ! grep -q "export GOPATH=" ~/.bashrc; then
    echo "export GOPATH=\$HOME/go" >> ~/.bashrc
fi
if ! grep -q "export GO111MODULE=" ~/.bashrc; then
    echo "export GO111MODULE=on" >> ~/.bashrc
fi
if ! grep -q "/usr/local/go/bin" ~/.bashrc; then
    echo "export PATH=\$PATH:/usr/local/go/bin:\$HOME/go/bin" >> ~/.bashrc
fi

# Note to user
echo "Please log out and back in for environment changes to take effect, or run 'source ~/.bashrc'."
