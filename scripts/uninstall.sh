#!/bin/bash

# Define the FVM directory and binary path
FVM_DIR="$HOME/.fvm_flutter"
BIN_LINK="$HOME/.local/bin/fvm"

# Check if FVM is installed
if ! command -v fvm &> /dev/null
then
    echo "FVM is not installed. Exiting."
    exit 1
fi

# Remove the FVM binary
echo "Uninstalling FVM..."
rm -rf "$FVM_DIR" || {
    echo "Failed to remove FVM directory: $FVM_DIR."
    exit 1
}

# Remove the symlink
rm -f "$BIN_LINK" || {
    echo "Failed to remove FVM symlink: $BIN_LINK."
    exit 1
}

# Check if uninstallation was successful
if command -v fvm &> /dev/null
then
    echo "Uninstallation failed. Please try again later."
    exit 1
fi

echo "FVM uninstalled successfully."
