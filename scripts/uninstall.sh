#!/bin/bash

# Detect OS
OS="$(uname -s)"

# Map to FVM naming
case "$OS" in
Linux*) OS='linux' ;;
Darwin*) OS='macos' ;;
*)
    log_message "Unsupported OS"
    exit 1
    ;;
esac

# Define the FVM directory and binary path
FVM_DIR="$HOME/.fvm_flutter"
FVM_DIR_BIN="$FVM_DIR/bin"

# Remove the FVM binary
echo "Uninstalling FVM..."
rm -rf "$FVM_DIR" || {
    echo "Failed to remove FVM directory: $FVM_DIR."
    exit 1
}

echo "You can remove \"export PATH=$FVM_DIR_BIN:\$PATH\" from your ~/.bashrc, ~/.zshrc (or similar)"

# Check if uninstallation was successful
if command -v fvm &>/dev/null; then
    echo "Uninstallation failed. Please try again later."
    exit 1
fi

echo "FVM uninstalled successfully."
