#!/usr/bin/env bash

# Function to log messages with date and time
log_message() {
    echo -e "$1"
}

# Detect OS and architecture
OS="$(uname -s)"
ARCH="$(uname -m)"

# Map to FVM naming
case "$OS" in
  Linux*)  OS='linux' ;;
  Darwin*) OS='macos' ;;
  *)       log_message "Unsupported OS"; exit 1 ;;
esac

case "$ARCH" in
  x86_64)  ARCH='x64' ;;
  arm64|aarch64)   ARCH='arm64' ;;
  armv7l)  ARCH='arm' ;;
  *)       log_message "Unsupported architecture"; exit 1 ;;
esac

# Terminal colors setup
Color_Off='\033[0m'       # Reset
Green='\033[0;32m'        # Green
Red='\033[0;31m'          

success() {
    log_message "${Green}$1${Color_Off}"
}

error() {
    log_message "${Red}error: $1${Color_Off}" >&2
    exit 1
}

# Log detected OS and architecture
log_message "Detected OS: $OS"
log_message "Detected Architecture: $ARCH"

# Check for curl
if ! command -v curl &> /dev/null; then
    error "curl is required but not installed."
fi

# Get installed FVM version if exists
INSTALLED_FVM_VERSION=""
if command -v fvm &> /dev/null; then
    INSTALLED_FVM_VERSION=$(fvm --version 2>&1) || error "Failed to fetch installed FVM version."
fi

# Define the URL of the FVM binary
if [ -z "$1" ]; then
  FVM_VERSION=$(curl -s https://api.github.com/repos/leoafarias/fvm/releases/latest | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
  if [ -z "$FVM_VERSION" ]; then
      error "Failed to fetch latest FVM version."
  fi
else
  FVM_VERSION="$1"
fi

log_message "Installing FVM version $FVM_VERSION."

# Setup installation directory and symlink
FVM_DIR="$HOME/.fvm_flutter"
FMV_DIR_BIN="$FVM_DIR/bin"
SYMLINK_TARGET="/usr/local/bin/fvm"


# Create FVM directory if it doesn't exist
mkdir -p "$FVM_DIR" || error "Failed to create FVM directory: $FVM_DIR."

# Check if FVM_DIR exists, and if it does delete it
if [ -d "$FMV_DIR_BIN" ]; then
    log_message "FVM bin directory already exists. Removing it."
    if ! rm -rf "$FMV_DIR_BIN"; then
        error "Failed to remove existing FVM directory: $FMV_DIR_BIN."
    fi
fi

# Download FVM
URL="https://github.com/leoafarias/fvm/releases/download/$FVM_VERSION/fvm-$FVM_VERSION-$OS-$ARCH.tar.gz"
if ! curl -L "$URL" -o fvm.tar.gz; then
    error "Download failed. Check your internet connection and URL: $URL"
fi


# Extract binary to the new location
if ! tar xzf fvm.tar.gz -C "$FVM_DIR" 2>&1; then
    error "Extraction failed. Check permissions and tar.gz file integrity."
fi

# Cleanup
if ! rm -f fvm.tar.gz; then
    error "Failed to cleanup"
fi

# Rename FVM_DIR/fvm to FVM_DIR/bin
if ! mv "$FVM_DIR/fvm" "$FMV_DIR_BIN"; then
    error "Failed to move fvm to bin directory."
fi

# Create a symlink
if ! ln -sf "$FMV_DIR_BIN/fvm" "$SYMLINK_TARGET"; then
    error "Failed to create symlink."
fi

# Verify installation
if ! command -v fvm &> /dev/null; then
    error "Installation verification failed. FVM may not be in PATH or failed to execute."
fi

INSTALLED_FVM_VERSION=$(fvm --version 2>&1) || error "Failed to verify installed FVM version."
success "FVM $INSTALLED_FVM_VERSION installed successfully."
