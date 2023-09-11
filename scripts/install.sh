#!/usr/bin/env bash
set -euo pipefail

# Custom Trap for runtime errors and Exit
trap 'catchErrors $? $LINENO' EXIT ERR

catchErrors() {
    local ERR_CODE=$1
    local ERR_LINE=$2
    if [[ "$ERR_CODE" -ne 0 ]]; then
        error "An error occurred on line $ERR_LINE of the script"
    fi
    rm -f fvm.tar.gz > /dev/null 2>&1
}


# Terminal colors setup
Color_Off=''    # Reset
Red=''          # Red
Green=''        # Green
Dim=''          # White
Bold_White=''   # Bold White
Bold_Green=''   # Bold Green

if [[ -t 1 ]]; then
    Color_Off='\033[0m'     # Reset
    Red='\033[0;31m'        # Red
    Green='\033[0;32m'      # Green
    Dim='\033[0;2m'         # White
    Bold_White='\033[1m'    # Bold White
    Bold_Green='\033[1;32m' # Bold Green
fi

# Custom output functions
error() {
    printf "${Red}error${Color_Off}:" "$@" >&2
    exit 1
}

info() {
    echo -e "${Dim}$@ ${Color_Off}"
}

info_bold() {
    echo -e "${Bold_White}$@ ${Color_Off}"
}

success() {
    echo -e "${Green}$@ ${Color_Off}"
}

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
info "Detected OS: $OS"
info "Detected Architecture: $ARCH"

# Check for curl
if ! command -v curl &> /dev/null; then
    error "curl is required but not installed"
fi

github_repo="fluttertools/fvm"

# Define the URL of the FVM binary
if [ -z "${1:-}" ]; then
    FVM_VERSION=$(curl -s https://api.github.com/repos/$github_repo/releases/latest | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
    if [ -z "$FVM_VERSION" ]; then
        error "Failed to fetch the latest FVM version from GitHub"
    fi
else
  FVM_VERSION=$1
fi

# Log version
info "Installing FVM Version: $FVM_VERSION"

# Download FVM
URL="https://github.com/$github_repo/releases/download/$FVM_VERSION/fvm-$FVM_VERSION-$OS-$ARCH.tar.gz"


curl --fail --location --progress-bar --output "fvm.tar.gz" "$URL" ||
    error "Failed to download FVM from \"$URL\""

# Binary directory
FVM_DIR="/usr/local/bin"

# Extract binary
if ! tar xzf fvm.tar.gz -C "$FVM_DIR"; then
    error "Extraction failed"
fi

# Set permission
chmod +x "$FVM_DIR/fvm" || error "Failed setting permissions"

# Cleanup
if ! rm -f fvm.tar.gz; then
    error "Failed to cleanup"
fi



if [[ "$(fvm --version)" != "$FVM_VERSION" ]]; then
    error "FVM version verification failed."
fi

# Verify installation
if command -v fvm &> /dev/null; then
    INSTALLED_FVM_VERSION=$(fvm --version)
    success "FVM $INSTALLED_FVM_VERSION installed successfully."
else
    error "Installation failed. Exiting."
fi