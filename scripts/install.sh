#!/bin/bash

# Detect the OS and architecture
OS="$(uname -s)"
ARCH="$(uname -m)"

# Map the OS and architecture to the names used in the FVM binary files
case "$OS" in
  Linux*)     OS='linux' ;;
  Darwin*)    OS='macos' ;;
  *)          echo "Unsupported operating system"; exit 1 ;;
esac

case "$ARCH" in
  x86_64)     ARCH='x64' ;;
  arm64)      ARCH='arm64' ;;
  armv7l)     ARCH='arm' ;;
  *)          echo "Unsupported architecture"; exit 1 ;;
esac

# Define the FVM version
FVM_VERSION="2.4.1"

# Define the URL of the FVM binary
URL="https://github.com/fluttertools/fvm/releases/download/${FVM_VERSION}/fvm-${FVM_VERSION}-${OS}-${ARCH}.tar.gz"

# Check if curl is installed
if ! command -v curl &> /dev/null
then
    echo "curl could not be found"
    exit 1
fi

# Download the FVM binary
echo "Downloading FVM..."
curl -L $URL -o fvm.tar.gz

# Check if the download was successful
if [ $? -ne 0 ]; then
    echo "Download failed. Please check your internet connection or try again later."
    exit 1
fi

# Create the directory for the binary
FVM_DIR="/usr/local/bin"



# Extract the binary to the subdirectory
echo "Installing FVM..."
tar xzf fvm.tar.gz -C $FVM_DIR

# Check if the extraction was successful
if [ $? -ne 0 ]; then
    echo "Installation failed. Please try again later."
    exit 1
fi

# Check if FVM was installed successfully
if ! command -v fvm &> /dev/null
then
    echo "FVM installation failed. Please try again later."
    exit 1
fi

echo "FVM installed successfully."

# Cleanup
rm -f fvm.tar.gz

# Run fvm command to check version
fvm --version
