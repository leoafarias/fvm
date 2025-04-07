#!/bin/bash

# create_new_app.sh
# Script to create a fresh Flutter app at the root of the project

# Define the app directory name
APP_DIR="example_app"

# Display start message
echo "Creating a new Flutter app at the root directory..."

# Remove existing app directory if it exists
if [ -d "$APP_DIR" ]; then
  echo "Removing existing $APP_DIR directory..."
  rm -rf "$APP_DIR"
fi

# Create app directory
echo "Creating fresh $APP_DIR directory..."
mkdir -p "$APP_DIR"

# Initialize git repository
echo "Initializing git repository in $APP_DIR..."
cd "$APP_DIR" || exit 1
git init

# Create Flutter app
echo "Creating Flutter app with 'flutter create .'..."
flutter create .

# Run pub get
echo "Running flutter pub get..."
flutter pub get

# Create INSTRUCTIONS.md file
echo "Creating INSTRUCTIONS.md with reference documentation..."
cat > INSTRUCTIONS.md << 'EOF'
# FVM Test Instructions

This example app exists to provide a testing environment for the Flutter Version Manager (FVM) tool. It allows developers to test FVM commands and features against a real Flutter project.

## ⚠️ IMPORTANT: ALWAYS CHECK AVAILABLE COMMANDS FIRST ⚠️

**BEFORE RUNNING ANY FVM COMMAND, always check the available commands for your specific FVM version!**

```bash
# THE MOST IMPORTANT COMMAND TO RUN FIRST:
dart run ../bin/main.dart --help

# View detailed help for a specific command
dart run ../bin/main.dart help <command>
```

Commands and features vary between versions. The help output shows exactly what commands are available in your current FVM version. This should be your first step every time you work with FVM.

## Before Getting Started

```bash
# Check your FVM version
dart run ../bin/main.dart --version

# View all available commands (ALWAYS DO THIS FIRST)
dart run ../bin/main.dart --help

# Get detailed help for a specific command
dart run ../bin/main.dart help <command>
```

## IMPORTANT: Always Run Commands in the example_app Directory

**All commands in this document should be run from the `example_app` directory at the project root, not from subdirectories.** 

Make sure you're in the correct directory before running any commands:
```bash
# Navigate to the example_app directory first
cd /path/to/fvm/example_app

# Then run commands
dart run ../bin/main.dart use stable
```

## Purpose

The main purposes of this app are:
1. Testing FVM command behavior in a controlled environment
2. Verifying FVM integration with Flutter projects
3. Testing version switching and management
4. Validating configuration changes

## Test Commands

Use these commands inside this example app directory to test FVM functionality:

```bash
# FIRST: Check available commands
dart run ../bin/main.dart --help

# Run version command
dart run ../bin/main.dart --version

# List available versions
dart run ../bin/main.dart releases

# Install a version
dart run ../bin/main.dart install 3.19.0

# List installed versions
dart run ../bin/main.dart list

# Use a version in the example app
dart run ../bin/main.dart use 3.19.0

# Run Flutter via FVM
dart run ../bin/main.dart flutter run -d chrome
```

## FVM Configuration Commands

```bash
# Create .fvmrc with specific version
echo '{"flutter": "3.19.0"}' > .fvmrc

# Set environment version
dart run ../bin/main.dart use --env 3.19.0

# Pin project version
dart run ../bin/main.dart use 3.19.0

# Use global Flutter version
dart run ../bin/main.dart use global
```

## Testing FVM Features

```bash
# Test project detection
dart run ../bin/main.dart doctor

# Test Flutter proxy commands
dart run ../bin/main.dart flutter --version

# Test version switching
dart run ../bin/main.dart use 3.19.0
dart run ../bin/main.dart use 3.16.0

# Test flavor configurations
echo '{"flutter": "3.19.0", "flavors": {"dev": "3.16.0"}}' > .fvmrc
dart run ../bin/main.dart use --flavor dev
```

## Testing Fork Configurations

Handling forks depends on your FVM version. ALWAYS check available commands first:

```bash
# ALWAYS check if your FVM version supports the fork command first
dart run ../bin/main.dart --help | grep fork

# If supported, use official commands to configure forks
dart run ../bin/main.dart fork add leo https://github.com/leoafarias/flutter/
dart run ../bin/main.dart fork list
dart run ../bin/main.dart install leo/stable
dart run ../bin/main.dart use leo/stable

# If the fork command is not available in your version:
# You may need to configure forks through other means - refer to documentation
# for your specific FVM version
```

## Validating FVM State and Directory Structure

```bash
# Check FVM directory structure
ls -la .fvm/

# View FVM configuration file
cat .fvm/fvm_config.json

# Check current version
cat .fvm/version
cat .fvm/release

# Examine symlinks
file .fvm/flutter_sdk
readlink -f .fvm/flutter_sdk
ls -la .fvm/flutter_sdk

# Verify Flutter SDK path
ls -la .fvm/flutter_sdk/bin/flutter
```

## Testing Flutter and Dart Command Proxying

```bash
# Test Flutter command proxying
dart run ../bin/main.dart flutter --version
dart run ../bin/main.dart flutter doctor

# Test Dart command proxying
dart run ../bin/main.dart dart --version
dart run ../bin/main.dart dart --help

# Check which Flutter/Dart versions are being used
dart run ../bin/main.dart which flutter
dart run ../bin/main.dart which dart

# Verify Flutter SDK is correctly configured
dart run ../bin/main.dart env
```

## Comparing Version Changes

```bash
# Record current Flutter version
flutter --version > before_switch.txt

# Switch to another version
dart run ../bin/main.dart use 3.16.0

# Record new Flutter version
dart run ../bin/main.dart flutter --version > after_switch.txt

# See the differences
diff before_switch.txt after_switch.txt
```

## Validating IDE Integration

```bash
# Check VS Code settings
cat .vscode/settings.json
grep -r "flutterSdkPath" .vscode/settings.json

# Verify .gitignore settings
cat .gitignore | grep -A 5 ".fvm"

# Check for correct symlinks for IDE integration
ls -la .fvm/versions
```

## Complete FVM Environment Check

```bash
# Get full environment information
dart run ../bin/main.dart env

# Check all installed versions
dart run ../bin/main.dart list

# Verify project is using the correct version
dart run ../bin/main.dart doctor

# Test command forwarding
dart run ../bin/main.dart flutter --version
dart run ../bin/main.dart dart --version
```

## IMPORTANT: Never Manually Edit Configuration Files

⚠️ **WARNING: Never directly edit `.fvmrc` or any FVM configuration files by hand!** ⚠️

Always use FVM commands to manage your configuration:

```bash
# Set Flutter version
dart run ../bin/main.dart use stable

# Use a specific version
dart run ../bin/main.dart use 3.19.0

# Use a forked version (after configuring via API)
dart run ../bin/main.dart use fork_name/version
```

FVM manages internal file formats that may change between versions. Manual edits can cause unexpected behavior or corrupt your configuration.

If you need to configure forks or advanced settings, use the API interfaces provided by FVM rather than directly manipulating configuration files.

## Command Reference Summary

ALWAYS start with:

```bash
dart run ../bin/main.dart --help
```

Common tasks:
```bash
# Installation
dart run ../bin/main.dart install <version>

# Switching versions
dart run ../bin/main.dart use <version>

# Checking configuration
dart run ../bin/main.dart doctor

# Using proxied Flutter commands
dart run ../bin/main.dart flutter <command>
```
EOF

# Create validation script
echo "Creating validation script..."
cat > validate_fvm.sh << 'EOF'
#!/bin/bash

# validate_fvm.sh
# Script to validate FVM state and configuration in the example app

# Color definitions
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}=== FVM State Validation ===${NC}"

# Check if FVM is configured
if [ -d ".fvm" ]; then
  echo -e "${GREEN}✓ .fvm directory exists${NC}"
else
  echo -e "${RED}✗ .fvm directory not found${NC}"
  exit 1
fi

# Check for config file
if [ -f ".fvm/fvm_config.json" ]; then
  echo -e "${GREEN}✓ fvm_config.json exists${NC}"
  echo "Configuration:"
  cat .fvm/fvm_config.json
else
  echo -e "${RED}✗ fvm_config.json not found${NC}"
  exit 1
fi

# Check for symlinks
if [ -L ".fvm/flutter_sdk" ]; then
  echo -e "${GREEN}✓ flutter_sdk symlink exists${NC}"
  echo "Points to: $(readlink -f .fvm/flutter_sdk)"
else
  echo -e "${RED}✗ flutter_sdk symlink not found${NC}"
  exit 1
fi

# Check VS Code settings
if [ -f ".vscode/settings.json" ]; then
  echo -e "${GREEN}✓ VS Code settings exist${NC}"
  echo "Flutter SDK Path setting:"
  grep -r "flutterSdkPath" .vscode/settings.json || echo "flutterSdkPath not found in settings"
else
  echo -e "${YELLOW}! .vscode/settings.json not found${NC}"
fi

# Check version file
if [ -f ".fvm/version" ]; then
  echo -e "${GREEN}✓ Version file exists${NC}"
  echo "Current version: $(cat .fvm/version)"
else
  echo -e "${RED}✗ Version file not found${NC}"
fi

# Verify FVM proxy works
echo -e "\n${YELLOW}=== Testing FVM Proxy ===${NC}"
echo "Running: dart run ../bin/main.dart flutter --version"
dart run ../bin/main.dart flutter --version

echo -e "\n${YELLOW}=== Testing Dart Proxy ===${NC}"
echo "Running: dart run ../bin/main.dart dart --version"
dart run ../bin/main.dart dart --version

echo -e "\n${YELLOW}=== FVM Environment Info ===${NC}"
echo "Running: dart run ../bin/main.dart env"
dart run ../bin/main.dart env

echo -e "\n${GREEN}Validation complete!${NC}"
EOF

# Make the validation script executable
chmod +x validate_fvm.sh

# Return to original directory
cd ..

echo "New app creation complete!"
echo "You can now use 'cd example_app' to access the app."
echo "Use './validate_fvm.sh' inside the app directory to validate FVM state after making changes."
echo "IMPORTANT: Check available commands by running 'dart run ../bin/main.dart --help' first before proceeding with any other commands."
echo "Refer to INSTRUCTIONS.md for detailed usage instructions." 