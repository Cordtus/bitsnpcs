#!/bin/bash

# Temporarily disable exit on error to allow the script to run completely, even if an error occurs
# Useful for debugging; remove or change to 'set -e' for production
set +e

# Check if the script is being run as root, as root privileges are required for system-wide changes
if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as root. Exiting."
    exit 1
fi

# Prompt the user to specify the Go version to install; defaults to the latest version if left blank
read -p "Enter the Go version you want to install (e.g., 1.22.4) or press Enter for the latest version: " GO_VERSION

# If no version is provided, fetch the latest version from the official Go website
if [ -z "$GO_VERSION" ]; then
    echo "Fetching the latest Go version..."
    GO_VERSION=$(curl -fsSL https://go.dev/VERSION?m=text | grep -o 'go[0-9]\+\.[0-9]\+\.[0-9]\+' | head -n 1)

    # Verify the response is a valid version; exit if invalid
    if ! [[ "$GO_VERSION" =~ ^go[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        echo "Error: Failed to retrieve a valid Go version. Exiting."
        exit 1
    fi

    echo "Latest Go version is ${GO_VERSION}"
fi

# Remove the 'go' prefix for simplicity
GO_VERSION="${GO_VERSION#go}"

# Ensure the specified Go version matches the expected format; exit if invalid
if ! [[ "$GO_VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "Error: Invalid Go version specified. Exiting."
    exit 1
fi

# Update and upgrade system packages to ensure the system is up-to-date
echo "Updating and upgrading system packages..."
apt-get update -qq && apt-get upgrade -y -qq

# Install dependencies required for development and the Cosmos SDK/Tendermint environment
echo "Installing required packages..."
apt-get install -y -qq nano make build-essential gcc git jq chrony tar curl lz4 wget

# Check if a previous Go installation exists and remove it to avoid conflicts
GO_INSTALL_DIR="/usr/local/go"
if [ -d "$GO_INSTALL_DIR" ]; then
    echo "Removing existing Go installation..."
    rm -rf "$GO_INSTALL_DIR"
fi

# Construct URLs for the Go tarball and its checksum
GO_URL="https://dl.google.com/go/go${GO_VERSION}.linux-amd64.tar.gz"
CHECKSUM_URL="https://dl.google.com/go/go${GO_VERSION}.linux-amd64.tar.gz.sha256"

GO_TAR="go${GO_VERSION}.linux-amd64.tar.gz"
CHECKSUM_FILE="go${GO_VERSION}.linux-amd64.tar.gz.sha256"

# Download the Go tarball and verify the download was successful
echo "Downloading Go tarball..."
curl -fsSL -o "${GO_TAR}" "${GO_URL}"
if [ $? -ne 0 ]; then
    echo "Error: Failed to download Go tarball. Exiting."
    exit 1
fi

# Download the checksum file and verify the download was successful
echo "Downloading checksum..."
curl -fsSL -o "${CHECKSUM_FILE}" "${CHECKSUM_URL}"
if [ $? -ne 0 ]; then
    echo "Error: Failed to download checksum file. Exiting."
    exit 1
fi

# Verify the integrity of the downloaded tarball by comparing checksums
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

# Clean up any previous Go environment variable exports in .bashrc to prevent conflicts
sed -i '/export GOROOT/d' ~/.bashrc
sed -i '/export GOPATH/d' ~/.bashrc
sed -i '/export GO111MODULE/d' ~/.bashrc
sed -i '/export PATH=.*go\/bin/d' ~/.bashrc
sed -i '/export PATH=\$PATH:\/usr\/local\/go\/bin:\/\$HOME\/go\/bin/d' ~/.bashrc
sed -i '/source "\$HOME\/.cargo\/env"/d' ~/.bashrc

# Define Go environment variables and ensure they're added to .bashrc only once
echo "Adding Go environment variables to .bashrc..."
ENV_VARS=(
    "export GOROOT=/usr/local/go"
    "export GOPATH=\$HOME/go"
    "export GO111MODULE=on"
    "export PATH=\$PATH:/usr/local/go/bin:\$HOME/go/bin"
)

# Backup .bashrc before modifying it to prevent loss of user configurations
cp ~/.bashrc ~/.bashrc.backup

# Ensure the variables are added only once
for var in "${ENV_VARS[@]}"; do
    grep -qxF "${var}" ~/.bashrc || echo "${var}" >> ~/.bashrc
done

# Apply changes to the current shell session
source ~/.bashrc

# Confirm successful installation of Go
echo "Go ${GO_VERSION} installation complete."

# Prompt the user to optionally install Rust for additional development capabilities
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
