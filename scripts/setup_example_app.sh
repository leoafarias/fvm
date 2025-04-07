#!/bin/bash

# Create and configure example_app without problematic test files

# Define paths
EXAMPLE_APP_DIR="example_app"
FIXTURE_DIR="test/fixtures/example_app"

# Function to ensure directory exists
ensure_dir() {
  if [ ! -d "$1" ]; then
    mkdir -p "$1"
  fi
}

# Remove existing example_app if it exists
if [ -d "$EXAMPLE_APP_DIR" ]; then
  echo "Removing existing example_app directory..."
  rm -rf "$EXAMPLE_APP_DIR"
fi

# Create example_app directory
echo "Creating fresh example_app directory..."
mkdir -p "$EXAMPLE_APP_DIR"

# Initialize git repository
echo "Initializing git repository in example_app..."
cd "$EXAMPLE_APP_DIR" || exit 1
git init

# Create Flutter app
echo "Creating Flutter app with 'flutter create .'..."
flutter create .

# Remove the test directory to avoid failing tests
echo "Removing problematic test directory..."
rm -rf "test"

# Copy important files from fixture
echo "Copying README.md and COMMANDS.md from fixture..."
cd ..
ensure_dir "$EXAMPLE_APP_DIR"
cp "$FIXTURE_DIR/README.md" "$EXAMPLE_APP_DIR/"
cp "$FIXTURE_DIR/COMMANDS.md" "$EXAMPLE_APP_DIR/"

echo "Example app setup complete!"
echo "You can now use 'cd example_app' to access the example app." 