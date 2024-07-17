#!/bin/bash
# Script intended for new Debian system/vm/container
# Installs common Cosmos SDK dependencies, QOL tools, sets PATH/GOPATH+

# Exit if any command fails
set -e

# Ensure the script is run as root
if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as root."
    exit 1
fi

# Update and upgrade packages silently
apt-get update -qq && apt-get upgrade -y -qq

# Install required packages
apt-get install -y -qq nano make build-essential gcc git jq chrony tar curl lz4 wget

# Install Go if it's not installed
GO_VERSION="1.22.5"
GO_URL="https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz"
INSTALL_DIR="/usr/local"
GO_TAR="go${GO_VERSION}.linux-amd64.tar.gz"
CHECKSUM_URL="https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz.sha256"
CHECKSUM_FILE="go${GO_VERSION}.linux-amd64.tar.gz.sha256"

if ! command -v go &> /dev/null; then
    curl -fsSL -o ${GO_TAR} ${GO_URL}
    curl -fsSL -o ${CHECKSUM_FILE} ${CHECKSUM_URL}
    sha256sum -c ${CHECKSUM_FILE}
    if [ $? -eq 0 ]; then
        tar -C ${INSTALL_DIR} -xzf ${GO_TAR}
        rm ${GO_TAR} ${CHECKSUM_FILE}
    else
        echo "Checksum verification failed. Exiting."
        exit 1
    fi
fi

# Add Go environment variables to .bashrc if not already present
ENV_VARS=(
    "export GOROOT=${INSTALL_DIR}/go"
    "export GOPATH=\$HOME/go"
    "export GO111MODULE=on"
    "export PATH=\$PATH:${INSTALL_DIR}/go/bin:\$HOME/go/bin"
)
for var in "${ENV_VARS[@]}"; do
    grep -qxF "${var}" ~/.bashrc || echo "${var}" >> ~/.bashrc
done

# Note to user
echo "Please log out and back in for environment changes to take effect, or run 'source ~/.bashrc'."
