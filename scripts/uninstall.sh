#!/bin/bash

# Define the FVM directory and binary path
FVM_DIR="/usr/local/bin"
FVM_BIN_PATH="${FVM_DIR}/fvm"

# Check if FVM is installed
if ! command -v fvm &> /dev/null
then
    echo "FVM is not installed. Exiting."
    exit 1
fi

# Remove the FVM binary
echo "Uninstalling FVM..."
rm -r $FVM_BIN_PATH

# Check if uninstallation was successful
if command -v fvm &> /dev/null
then
    echo "Uninstallation failed. Please try again later."
    exit 1
fi

echo "FVM uninstalled successfully."
