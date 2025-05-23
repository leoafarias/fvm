#!/bin/bash

# Create a temporary directory
DIR=$(mktemp -d)
cd "$DIR"

# Create a minimal pubspec.yaml
echo "name: test_project" > pubspec.yaml

# Create a clean .fvm directory 
mkdir -p .fvm

# Run the FVM use command with no arguments and capture the output and exit code
echo "Running FVM use command with no arguments"
/Users/leofarias/Projects/fvm/bin/main.dart use || echo "Command failed with error code $?"

echo "Test complete"
echo "Temporary directory was $DIR"
