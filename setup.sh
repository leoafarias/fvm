#!/bin/bash
set -e

# Update system packages
sudo apt-get update

# Install required dependencies
sudo apt-get install -y apt-transport-https wget gnupg git curl

# Add Dart repository key and repository
wget -qO- https://dl-ssl.google.com/linux/linux_signing_key.pub | sudo gpg --dearmor -o /usr/share/keyrings/dart.gpg
echo "deb [signed-by=/usr/share/keyrings/dart.gpg arch=amd64] https://storage.googleapis.com/download.dartlang.org/linux/debian stable main" | sudo tee /etc/apt/sources.list.d/dart_stable.list

# Update package list and install Dart SDK
sudo apt-get update
sudo apt-get install -y dart

# Add Dart to system PATH
echo 'PATH="$PATH:/usr/lib/dart/bin"' | sudo tee -a /etc/environment

# Set PATH for current session
export PATH="$PATH:/usr/lib/dart/bin"
export PATH="$PATH:$HOME/.pub-cache/bin"

# Add to user profile for future sessions
echo 'export PATH="$PATH:/usr/lib/dart/bin"' >> $HOME/.profile
echo 'export PATH="$PATH:$HOME/.pub-cache/bin"' >> $HOME/.profile

# Verify Dart installation
dart --version

# Navigate to project directory
cd /mnt/persist/workspace

# Install project dependencies
dart pub get

# Install grinder globally for build tasks
dart pub global activate grinder

# Set up Git configuration (required for FVM tests)
git config --global user.name "Test User"
git config --global user.email "test@example.com"
git config --global init.defaultBranch main

# Create necessary test directories
mkdir -p $HOME/fvm-test
mkdir -p $HOME/.fvm
mkdir -p $HOME/fvm_test_cache

# Create the Git cache directory that the tests expect
mkdir -p $HOME/fvm_test_cache/gitcache
cd $HOME/fvm_test_cache/gitcache

# Initialize a bare Git repository for the cache
git init --bare

# Add Flutter repository as remote (this creates a proper Git cache)
git remote add origin https://github.com/flutter/flutter.git

# Go back to project directory
cd /mnt/persist/workspace

# Verify grinder installation
dart pub global run grinder --version