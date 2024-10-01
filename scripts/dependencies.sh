#!/bin/bash
# Script intended for new Debian system/vm/container
# Installs common Cosmos SDK dependencies, QOL tools, sets PATH/GOPATH+

# Exit if any command fails
set -e

# Ensure the script is run as root
if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as root. Exiting."
    exit 1
fi

# Prompt the user to enter the Go version to install, or use "latest" if left blank
read -p "Enter the Go version you want to install (e.g., 1.22.4) or press Enter for the latest version: " GO_VERSION

# Determine the latest version if not specified by the user
if [ -z "$GO_VERSION" ]; then
    echo "Fetching the latest Go version..."
    GO_VERSION=$(curl -fsSL https://go.dev/VERSION?m=text | sed 's/go//')
    echo "Latest Go version is ${GO_VERSION}"
fi

# Update and upgrade packages silently
echo "Updating and upgrading system packages..."
apt-get update -qq && apt-get upgrade -y -qq

# Install required packages
echo "Installing required packages..."
apt-get install -y -qq nano make build-essential gcc git jq chrony tar curl lz4 wget

# Check for and remove existing Go installations
GO_INSTALL_DIR="/usr/local/go"
if [ -d "$GO_INSTALL_DIR" ]; then
    echo "Removing existing Go installation..."
    rm -rf "$GO_INSTALL_DIR"
fi

# Download and install the selected Go version
GO_URL="https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz"
INSTALL_DIR="/usr/local"
GO_TAR="go${GO_VERSION}.linux-amd64.tar.gz"
CHECKSUM_URL="https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz.sha256"
CHECKSUM_FILE="go${GO_VERSION}.linux-amd64.tar.gz.sha256"

# Ensure the Go version exists before proceeding
if curl --output /dev/null --silent --head --fail "${GO_URL}"; then
    echo "Installing Go ${GO_VERSION}..."
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
else
    echo "Go version ${GO_VERSION} not found. Exiting."
    exit 1
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

# Notify the user to reload environment variables
echo "Go ${GO_VERSION} installation complete."
echo "Please log out and back in for environment changes to take effect, or run 'source ~/.bashrc'."
