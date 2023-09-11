#!/bin/bash

# Detect OS and architecture
OS="$(uname -s)"
ARCH="$(uname -m)"

# Map to FVM naming
case "$OS" in
  Linux*)  OS='linux' ;;
  Darwin*) OS='macos' ;;
  *)       echo "Unsupported OS"; exit 1 ;;
esac

case "$ARCH" in
  x86_64)  ARCH='x64' ;;
  arm64)   ARCH='arm64' ;;
  armv7l)  ARCH='arm' ;;
  *)       echo "Unsupported architecture"; exit 1 ;;
esac

# Log detected OS and architecture
echo "Detected OS: $OS"
echo "Detected Architecture: $ARCH"

# Check for curl
if ! command -v curl &> /dev/null; then
    echo "curl is required but not installed. Exiting."
    exit 1
fi

# Get installed FVM version if exists
INSTALLED_FVM_VERSION=""
if command -v fvm &> /dev/null; then
    INSTALLED_FVM_VERSION=$(fvm --version)
fi

# Define the URL of the FVM binary
if [ -z "$1" ]; then
  FVM_VERSION=$(curl -s https://api.github.com/repos/fluttertools/fvm/releases/latest | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
  if [ -z "$FVM_VERSION" ]; then
      echo "Failed to fetch latest FVM version. Exiting."
      exit 1
  fi
else
  FVM_VERSION=$1
fi

# Compare versions and ask for user input if needed
if [[ "$INSTALLED_FVM_VERSION" == "$FVM_VERSION" ]]; then
     read -p "FVM version $FVM_VERSION is already installed. Would you like to reinstall it? (y/n): " REINSTALL
    if [[ "$REINSTALL" != "y" ]]; then exit 0; fi
elif [[ "$INSTALLED_FVM_VERSION" < "$FVM_VERSION" ]]; then
    read -p "A newer FVM version ($FVM_VERSION) is available. Would you like to upgrade from $INSTALLED_FVM_VERSION? (y/n): " UPGRADE
    if [[ "$UPGRADE" != "y" ]]; then exit 0; fi
fi
# Log version
echo "Installing FVM Version: $FVM_VERSION"

# Download FVM
URL="https://github.com/fluttertools/fvm/releases/download/$FVM_VERSION/fvm-$FVM_VERSION-$OS-$ARCH.tar.gz"
curl -L $URL -o fvm.tar.gz
if [ $? -ne 0 ]; then
    echo "Download failed. Check your internet."
    exit 1
fi

# Binary directory
FVM_DIR="/usr/local/bin"

# Extract binary
tar xzf fvm.tar.gz -C $FVM_DIR
if [ $? -ne 0 ]; then
    echo "Extraction failed. Exiting."
    exit 1
fi

# Cleanup
rm -f fvm.tar.gz

# Verify installation
if ! command -v fvm &> /dev/null; then
    echo "Installation failed. Exiting."
    exit 1
fi

INSTALLED_FVM_VERSION=$(fvm --version)
echo "FVM $INSTALLED_FVM_VERSION installed successfully."
