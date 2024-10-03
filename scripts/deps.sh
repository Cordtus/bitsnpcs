#!/bin/bash

# Temporarily disable exit on error to allow full script execution for debugging
set +e

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
    GO_VERSION=$(curl -fsSL https://go.dev/VERSION?m=text | grep -o 'go[0-9]\+\.[0-9]\+\.[0-9]\+' | head -n 1)

    # Ensure that the response is a valid version
    if ! [[ "$GO_VERSION" =~ ^go[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        echo "Error: Failed to retrieve a valid Go version. Exiting."
        exit 1
    fi

    echo "Latest Go version is ${GO_VERSION}"
fi

# Remove the 'go' prefix for further processing
GO_VERSION="${GO_VERSION#go}"

# Validate the GO_VERSION variable before proceeding
if ! [[ "$GO_VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "Error: Invalid Go version specified. Exiting."
    exit 1
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

# Construct the URLs for the Go tarball and checksum
GO_URL="https://dl.google.com/go/go${GO_VERSION}.linux-amd64.tar.gz"
CHECKSUM_URL="https://dl.google.com/go/go${GO_VERSION}.linux-amd64.tar.gz.sha256"

GO_TAR="go${GO_VERSION}.linux-amd64.tar.gz"
CHECKSUM_FILE="go${GO_VERSION}.linux-amd64.tar.gz.sha256"

# Download the Go tarball and checksum file
echo "Downloading Go tarball..."
curl -fsSL -o "${GO_TAR}" "${GO_URL}"
if [ $? -ne 0 ]; then
    echo "Error: Failed to download Go tarball. Exiting."
    exit 1
fi

echo "Downloading checksum..."
curl -fsSL -o "${CHECKSUM_FILE}" "${CHECKSUM_URL}"
if [ $? -ne 0 ]; then
    echo "Error: Failed to download checksum file. Exiting."
    exit 1
fi

# Extract the checksum value manually
CHECKSUM=$(awk '{print $1}' "${CHECKSUM_FILE}")
FILE_CHECKSUM=$(sha256sum "${GO_TAR}" | awk '{print $1}')

# Compare the checksums
if [ "${CHECKSUM}" == "${FILE_CHECKSUM}" ]; then
    echo "Checksum verification passed."
    tar -C /usr/local -xzf "${GO_TAR}"
    rm "${GO_TAR}" "${CHECKSUM_FILE}"
else
    echo "Checksum verification failed."
    echo "Expected: ${CHECKSUM}"
    echo "Actual: ${FILE_CHECKSUM}"
    exit 1
fi

# Remove any previous incorrect PATH or Go-related exports from .bashrc
sed -i '/export GOROOT/d' ~/.bashrc
sed -i '/export GOPATH/d' ~/.bashrc
sed -i '/export GO111MODULE/d' ~/.bashrc
sed -i '/export PATH=.*go\/bin/d' ~/.bashrc
sed -i '/export PATH=\$PATH:\/usr\/local\/go\/bin:\/\$HOME\/go\/bin/d' ~/.bashrc
sed -i '/source "\$HOME\/.cargo\/env"/d' ~/.bashrc

# Add Go environment variables to .bashrc, ensuring they're added only once
echo "Adding Go environment variables to .bashrc..."

ENV_VARS=(
    "export GOROOT=/usr/local/go"
    "export GOPATH=\$HOME/go"
    "export GO111MODULE=on"
    "export PATH=\$PATH:/usr/local/go/bin:\$HOME/go/bin"
)

# Backup .bashrc before modifying it
cp ~/.bashrc ~/.bashrc.backup

# Ensure the variables are added only once
for var in "${ENV_VARS[@]}"; do
    grep -qxF "${var}" ~/.bashrc || echo "${var}" >> ~/.bashrc
done

# Source the updated .bashrc to apply changes
source ~/.bashrc

# Print message indicating Go installation was successful
echo "Go ${GO_VERSION} installation complete."

# Prompt the user for Rust installation
read -p "Do you want to install the Rust environment (rustup)? (y/n): " INSTALL_RUST

if [ "$INSTALL_RUST" = "y" ]; then
    echo "Installing Rust environment..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    source "$HOME/.cargo/env"
    
    # Add Rust environment variables to .bashrc if not already present
    grep -qxF "source \$HOME/.cargo/env" ~/.bashrc || echo "source \$HOME/.cargo/env" >> ~/.bashrc
    echo "Rust environment installation complete."
else
    echo "Skipping Rust environment installation."
fi

# Notify the user to reload environment variables
echo "Go ${GO_VERSION} installation complete."
if [ "$INSTALL_RUST" = "y" ]; then
    echo "Rust installation complete."
fi
echo "Please log out and back in for environment changes to take effect, or run 'source ~/.bashrc'."
