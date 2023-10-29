#!/bin/bash
# Intended for new debian system/vm/container
# Installs common cosmos SDK dependencies, QOL tools, sets PATH/GOPATH+

set -e

apt-get update > /dev/null && apt-get upgrade -y > /dev/null

apt-get install nano make clang openssl llvm build-essential gcc git jq chrony tar curl lz4 wget -y > /dev/null

# Check if 'go' is installed
if ! command -v go &> /dev/null; then
    wget -q https://go.dev/dl/go1.20.linux-amd64.tar.gz
    tar -C /usr/local -xzf go1.20.linux-amd64.tar.gz
    rm go1.20.linux-amd64.tar.gz
fi

# Check if GOPATH is set
if [ -z "${GOPATH}" ]; then
    echo -e "export GOROOT=/usr/local/go\nexport GOPATH=\$HOME/go\nexport GO111MODULE=on\nexport PATH=\$PATH:/usr/local/go/bin:\$HOME/go/bin" >> ~/.bashrc
fi

# Check if rustc is installed
if [ -z "$(which rustc)" ]; then
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
fi

# Source the bashrc to apply changes
source ~/.bashrc
