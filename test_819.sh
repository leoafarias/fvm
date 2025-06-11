#!/bin/bash
# test_issue_819.sh - Temporary test script for issue #819

echo "🧪 Testing Issue #819 - Git Merge Conflicts"
echo "============================================="

# Check FVM is installed
if ! command -v fvm &> /dev/null; then
    echo "❌ FVM not found. Please install FVM first."
    exit 1
fi

echo "✅ FVM found: $(fvm --version)"

# Check git cache path - get it from FVM API
GIT_CACHE_PATH=$(fvm api context | grep '"gitCachePath"' | sed 's/.*": "\(.*\)",/\1/')
echo "📁 Git cache path: $GIT_CACHE_PATH"

# Ensure git cache exists
if [ ! -d "$GIT_CACHE_PATH" ]; then
    echo "📥 Creating git cache by installing a Flutter version..."
    fvm install 3.24.5
fi

if [ ! -d "$GIT_CACHE_PATH" ]; then
    echo "❌ Failed to create git cache"
    exit 1
fi

echo "✅ Git cache exists"

# Navigate to git cache
cd "$GIT_CACHE_PATH"

# Check git status
echo "📋 Current git status:"
git status --porcelain

# Create the conflict
echo "💥 Creating conflict in engine/src/flutter/bin/et.bat"
mkdir -p engine/src/flutter/bin
echo "conflict content - $(date)" > engine/src/flutter/bin/et.bat

# Verify conflict created
echo "📋 Git status after creating conflict:"
git status --porcelain

# Test the bug
echo "🐛 Testing bug reproduction with Flutter 3.27.4..."
cd - > /dev/null  # Go back to original directory

# Capture output
fvm install 3.27.4 2>&1 | tee /tmp/fvm_install_output.txt

# Check for the specific error
if grep -q "would be overwritten by merge" /tmp/fvm_install_output.txt; then
    echo "✅ BUG REPRODUCED! Found the merge conflict error."
    echo "📄 Error details:"
    grep -A 3 -B 3 "would be overwritten" /tmp/fvm_install_output.txt
else
    echo "❓ Bug not reproduced. Installation may have succeeded or failed differently."
    echo "📄 Full output:"
    cat /tmp/fvm_install_output.txt
fi

# Clean up - ONLY clean the git cache, not the current directory
echo "🧹 Cleaning up git cache..."
if [ -d "$GIT_CACHE_PATH" ]; then
    cd "$GIT_CACHE_PATH"
    git reset --hard HEAD 2>/dev/null || true
    git clean -fd 2>/dev/null || true
fi

echo "✅ Test completed!"
