#!/usr/bin/env bash

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

# Terminal colors setup
Color_Off='\033[0m'       # Reset
Green='\033[0;32m'        # Green
Red='\033[0;31m'          

success() {
    echo -e "${Green}$1${Color_Off}"
}

error() {
    echo -e "${Red}error: $1${Color_Off}" >&2
    exit 1
}

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
  FVM_VERSION=$(curl -s https://api.github.com/repos/leoafarias/fvm/releases/latest | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
  if [ -z "$FVM_VERSION" ]; then
      error "Failed to fetch latest FVM version. Exiting."
  fi
else
  FVM_VERSION="$1"
fi

# Compare versions and inform the user
if [[ "$INSTALLED_FVM_VERSION" == "$FVM_VERSION" ]]; then
     echo "Reinstalling FVM version $FVM_VERSION."
elif [[ "$INSTALLED_FVM_VERSION" < "$FVM_VERSION" ]]; then
    echo "Upgrading FVM from version $INSTALLED_FVM_VERSION to $FVM_VERSION."
else
    echo "Installing FVM version $FVM_VERSION."
fi

# Download FVM
URL="https://github.com/leoafarias/fvm/releases/download/$FVM_VERSION/fvm-$FVM_VERSION-$OS-$ARCH.tar.gz"
if ! curl -L "$URL" -o fvm.tar.gz; then
    error "Download failed. Check your internet."
fi

# Binary directory
FVM_DIR="/usr/local/bin"

# Extract binary
if ! tar xzf fvm.tar.gz -C "$FVM_DIR"; then
    error "Extraction failed. Exiting."
fi

# Cleanup
rm -f fvm.tar.gz

# Verify installation
if ! command -v fvm &> /dev/null; then
    error "Installation failed. Exiting."
fi

INSTALLED_FVM_VERSION=$(fvm --version)
success "FVM $INSTALLED_FVM_VERSION installed successfully."
