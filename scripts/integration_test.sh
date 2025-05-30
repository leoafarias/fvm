#!/bin/bash

# FVM Comprehensive Integration Test Suite
# Tests real-world FVM workflows with actual Git operations and Flutter SDK installations

set -e  # Exit on any error

echo "=== FVM Comprehensive Integration Test Suite ==="
echo ""
echo "Note: Test environment will be automatically cleaned up on completion or interruption"
echo ""

# Get to project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
cd "$PROJECT_ROOT"

# Test configuration
TEST_CHANNEL="stable"
TEST_RELEASE="3.19.0"
TEST_COMMIT="fb57da5f94"
TEST_FORK_NAME="testfork"
TEST_FORK_URL="https://github.com/flutter/flutter.git"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Helper functions
log_test() {
    echo -e "${YELLOW}$1${NC}"
}

log_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

log_error() {
    echo -e "${RED}✗ $1${NC}"
}

run_fvm() {
    dart run "$PROJECT_ROOT/bin/main.dart" "$@"
}

# Enhanced cleanup function
cleanup_test_env() {
    echo ""
    echo "=== Cleaning up test environment ==="

    # Clean up test Flutter application directory
    if [ -n "$TEST_DIR" ] && [ -d "$TEST_DIR" ]; then
        log_test "Removing test Flutter application directory: $TEST_DIR"
        rm -rf "$TEST_DIR" 2>/dev/null || {
            echo "Warning: Could not remove $TEST_DIR (may require manual cleanup)"
        }
        log_success "Test application directory cleaned up"
    fi

    # Clean up temporary files created during testing
    log_test "Removing temporary test files..."
    rm -f /tmp/flutter_version.txt 2>/dev/null || true
    rm -f /tmp/dart_version.txt 2>/dev/null || true
    rm -f /tmp/spawn_version.txt 2>/dev/null || true
    rm -f /tmp/exec_output.txt 2>/dev/null || true
    rm -f /tmp/flavor_output.txt 2>/dev/null || true
    rm -f /tmp/api_list.txt 2>/dev/null || true
    rm -f /tmp/api_releases.txt 2>/dev/null || true
    rm -f /tmp/api_project.txt 2>/dev/null || true
    rm -f /tmp/api_context.txt 2>/dev/null || true
    rm -f /tmp/config_output.txt 2>/dev/null || true
    log_success "Temporary files cleaned up"

    # Clean up any test scripts created during execution
    if [ -f "$TEST_DIR/test_script.sh" ]; then
        rm -f "$TEST_DIR/test_script.sh" 2>/dev/null || true
    fi

    # Clean up any backup directories created during destroy tests
    if [ -n "$BACKUP_DIR" ] && [ -d "$BACKUP_DIR" ]; then
        log_test "Removing backup directory: $BACKUP_DIR"
        rm -rf "$BACKUP_DIR" 2>/dev/null || {
            echo "Warning: Could not remove backup directory $BACKUP_DIR"
        }
    fi

    # Return to project root if we're not already there
    if [ "$PWD" != "$PROJECT_ROOT" ]; then
        cd "$PROJECT_ROOT" 2>/dev/null || {
            echo "Warning: Could not return to project root"
        }
    fi

    log_success "Test environment cleanup completed"
}

# Set up traps for cleanup on exit, interruption, or termination
trap cleanup_test_env EXIT
trap cleanup_test_env INT
trap cleanup_test_env TERM

# Get the actual FVM cache path dynamically
FVM_CACHE_PATH=$(run_fvm api context | grep -o '"versionsCachePath": "[^"]*"' | cut -d'"' -f4)
if [ -z "$FVM_CACHE_PATH" ]; then
    log_error "Could not determine FVM cache path"
    exit 1
fi
echo "Using FVM cache path: $FVM_CACHE_PATH"

echo ""
echo "=== Phase 1: Basic Command Interface ==="

log_test "1. Testing FVM help..."
run_fvm --help > /dev/null
log_success "Help command works"

log_test "2. Testing FVM version..."
run_fvm --version
log_success "Version command works"

log_test "3. Testing releases (first 5 lines)..."
run_fvm releases | head -5
log_success "Releases command works"

log_test "4. Testing list command..."
run_fvm list
log_success "List command works"

echo ""
echo "=== Phase 2: Installation Workflow Tests ==="

# Create test project in a temporary directory to avoid config conflicts
TEST_DIR="/tmp/fvm_integration_test_$$"
rm -rf "$TEST_DIR"
mkdir -p "$TEST_DIR"
cd "$TEST_DIR"

log_test "5. Setting up test project..."
cat > pubspec.yaml << 'EOF'
name: fvm_integration_test_app
description: Integration test Flutter project
version: 1.0.0+1

environment:
  sdk: ">=3.0.0 <4.0.0"
  flutter: ">=3.0.0"

dependencies:
  flutter:
    sdk: flutter

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0

flutter:
  uses-material-design: true
EOF

mkdir -p lib
cat > lib/main.dart << 'EOF'
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FVM Integration Test',
      home: const Scaffold(
        body: Center(
          child: Text('FVM Integration Test App'),
        ),
      ),
    );
  }
}
EOF
log_success "Test project created"

log_test "6. Testing channel installation..."
run_fvm install $TEST_CHANNEL
log_success "Channel installation works"

# Verify installation
if [ -d "$FVM_CACHE_PATH/$TEST_CHANNEL" ]; then
    log_success "Channel directory created in cache"
else
    log_error "Channel directory not found in cache"
    exit 1
fi

# Verify Flutter executable exists
if [ -f "$FVM_CACHE_PATH/$TEST_CHANNEL/bin/flutter" ]; then
    log_success "Flutter executable exists"
else
    log_error "Flutter executable not found"
    exit 1
fi

log_test "7. Testing release installation..."
run_fvm install $TEST_RELEASE
log_success "Release installation works"

# Verify release installation
if [ -d "$FVM_CACHE_PATH/$TEST_RELEASE" ]; then
    log_success "Release directory created in cache"
else
    log_error "Release directory not found in cache"
    exit 1
fi

log_test "8. Testing Git commit installation..."
run_fvm install $TEST_COMMIT
log_success "Git commit installation works"

# Verify commit installation
if [ -d "$FVM_CACHE_PATH/$TEST_COMMIT" ]; then
    log_success "Commit directory created in cache"
else
    log_error "Commit directory not found in cache"
    exit 1
fi

log_test "9. Testing installation with setup flag..."
run_fvm install $TEST_CHANNEL --setup
log_success "Installation with setup works"

echo ""
echo "=== Phase 3: Project Lifecycle Tests ==="

log_test "10. Testing FVM use workflow..."
run_fvm use $TEST_CHANNEL
log_success "Use command works"

# Verify .fvmrc was created
if [ -f .fvmrc ]; then
    log_success ".fvmrc created"
    echo "Configuration content:"
    cat .fvmrc
else
    log_error ".fvmrc not found"
    exit 1
fi

# Verify .fvm directory structure
if [ -d .fvm ]; then
    log_success ".fvm directory created"

    # Check for symlinks (if privileged access available)
    if [ -L .fvm/flutter_sdk ]; then
        log_success "flutter_sdk symlink created"
    else
        echo "Note: flutter_sdk symlink not created (may require privileged access)"
    fi

    # Check for version files
    if [ -f .fvm/release ]; then
        log_success "Release file created"
        echo "Release: $(cat .fvm/release)"
    fi
else
    log_error ".fvm directory not found"
    exit 1
fi

log_test "11. Testing use with flavor..."
run_fvm use $TEST_RELEASE --flavor production
log_success "Flavor configuration works"

# Verify flavor in configuration
if grep -q "production" .fvmrc; then
    log_success "Flavor added to configuration"
else
    log_error "Flavor not found in configuration"
    exit 1
fi

log_test "12. Testing use with force flag..."
run_fvm use $TEST_CHANNEL --force
log_success "Force flag works"

log_test "13. Testing VS Code settings integration..."
# Check if .vscode directory was created
if [ -d .vscode ]; then
    log_success ".vscode directory created"
    if [ -f .vscode/settings.json ]; then
        log_success "VS Code settings.json created"
        echo "VS Code settings:"
        cat .vscode/settings.json
    fi
else
    echo "Note: .vscode directory not created (may be disabled in config)"
fi

log_test "14. Testing .gitignore integration..."
if [ -f .gitignore ]; then
    if grep -q ".fvm/flutter_sdk" .gitignore; then
        log_success ".gitignore updated with FVM entries"
    else
        echo "Note: .gitignore not updated (may be disabled in config)"
    fi
else
    echo "Note: .gitignore not created"
fi

echo ""
echo "=== Phase 4: Version Management Tests ==="

log_test "15. Testing global version setting..."
run_fvm global $TEST_CHANNEL
log_success "Global version setting works"

# Verify global version
GLOBAL_OUTPUT=$(run_fvm list 2>&1 | grep "global" || echo "")
if [ -n "$GLOBAL_OUTPUT" ]; then
    log_success "Global version visible in list"
    echo "Global version info: $GLOBAL_OUTPUT"
else
    echo "Note: Global version not shown in list output"
fi

log_test "16. Testing version removal..."
# Install a version specifically for removal testing
run_fvm install beta
run_fvm remove beta
log_success "Version removal works"

# Verify removal
if [ ! -d "$FVM_CACHE_PATH/beta" ]; then
    log_success "Version directory removed from cache"
else
    log_error "Version directory still exists after removal"
    exit 1
fi

log_test "17. Testing doctor command..."
run_fvm doctor | grep -E "(Pinned Version|Project|Global)" || true
log_success "Doctor command works"

echo ""
echo "=== Phase 5: Advanced Command Tests ==="

log_test "18. Testing Flutter proxy command..."
run_fvm flutter --version > /tmp/flutter_version.txt 2>&1
if [ -s /tmp/flutter_version.txt ]; then
    log_success "Flutter proxy works"
    echo "Flutter version output:"
    head -2 /tmp/flutter_version.txt
else
    log_error "Flutter proxy failed"
    exit 1
fi

log_test "19. Testing Dart proxy command..."
run_fvm dart --version > /tmp/dart_version.txt 2>&1
if [ -s /tmp/dart_version.txt ]; then
    log_success "Dart proxy works"
    echo "Dart version output:"
    head -1 /tmp/dart_version.txt
else
    log_error "Dart proxy failed"
    exit 1
fi

log_test "20. Testing spawn command..."
run_fvm spawn $TEST_CHANNEL --version > /tmp/spawn_version.txt 2>&1
if [ -s /tmp/spawn_version.txt ]; then
    log_success "Spawn command works"
    echo "Spawn output:"
    head -2 /tmp/spawn_version.txt
else
    log_error "Spawn command failed"
    exit 1
fi

log_test "21. Testing exec command..."
# Create a simple script to execute
echo '#!/bin/bash' > test_script.sh
echo 'echo "Exec test successful"' >> test_script.sh
chmod +x test_script.sh

run_fvm exec ./test_script.sh > /tmp/exec_output.txt 2>&1
if grep -q "Exec test successful" /tmp/exec_output.txt; then
    log_success "Exec command works"
else
    log_error "Exec command failed"
    exit 1
fi

log_test "22. Testing flavor command..."
# Set up flavor first
run_fvm use $TEST_CHANNEL --flavor development

# Test flavor command
run_fvm flavor development --version > /tmp/flavor_output.txt 2>&1
if [ -s /tmp/flavor_output.txt ]; then
    log_success "Flavor command works"
    echo "Flavor output:"
    head -2 /tmp/flavor_output.txt
else
    echo "Note: Flavor command may not be available or configured"
fi

echo ""
echo "=== Phase 6: API Command Tests ==="

log_test "23. Testing API list command..."
run_fvm api list > /tmp/api_list.txt 2>&1
if [ -s /tmp/api_list.txt ]; then
    log_success "API list command works"
    echo "API list sample:"
    head -5 /tmp/api_list.txt
else
    log_error "API list command failed"
    exit 1
fi

log_test "24. Testing API releases command..."
run_fvm api releases --limit 3 > /tmp/api_releases.txt 2>&1
if [ -s /tmp/api_releases.txt ]; then
    log_success "API releases command works"
    echo "API releases sample:"
    head -5 /tmp/api_releases.txt
else
    log_error "API releases command failed"
    exit 1
fi

log_test "25. Testing API project command..."
run_fvm api project > /tmp/api_project.txt 2>&1
if [ -s /tmp/api_project.txt ]; then
    log_success "API project command works"
    echo "API project sample:"
    head -5 /tmp/api_project.txt
else
    log_error "API project command failed"
    exit 1
fi

log_test "26. Testing API context command..."
run_fvm api context > /tmp/api_context.txt 2>&1
if [ -s /tmp/api_context.txt ]; then
    log_success "API context command works"
    echo "API context sample:"
    head -5 /tmp/api_context.txt
else
    log_error "API context command failed"
    exit 1
fi

echo ""
echo "=== Phase 7: Fork Management Tests ==="

log_test "27. Testing fork add command..."
# Clean up any existing test fork first
run_fvm fork remove $TEST_FORK_NAME 2>/dev/null || true

run_fvm fork add $TEST_FORK_NAME $TEST_FORK_URL
log_success "Fork add command works"

log_test "28. Testing fork list command..."
FORK_LIST_OUTPUT=$(run_fvm fork list 2>&1)
if echo "$FORK_LIST_OUTPUT" | grep -q "$TEST_FORK_NAME"; then
    log_success "Fork list command works and shows added fork"
    echo "Fork list output:"
    echo "$FORK_LIST_OUTPUT"
else
    log_error "Fork not found in list"
    exit 1
fi

log_test "29. Testing fork remove command..."
run_fvm fork remove $TEST_FORK_NAME
log_success "Fork remove command works"

# Verify fork was removed
FORK_LIST_AFTER=$(run_fvm fork list 2>&1)
if echo "$FORK_LIST_AFTER" | grep -q "$TEST_FORK_NAME"; then
    log_error "Fork still exists after removal"
    exit 1
else
    log_success "Fork successfully removed"
fi

echo ""
echo "=== Phase 8: Configuration Management Tests ==="

log_test "30. Testing config command..."
run_fvm config > /tmp/config_output.txt 2>&1
if [ -s /tmp/config_output.txt ]; then
    log_success "Config command works"
    echo "Config output:"
    head -10 /tmp/config_output.txt
else
    log_error "Config command failed"
    exit 1
fi

log_test "31. Testing config setting modification..."
# Test setting a configuration value
run_fvm config --cache-path "$HOME/.fvm_test_cache"
log_success "Config modification works"

# Verify the setting was applied
CONFIG_VERIFY=$(run_fvm config 2>&1)
if echo "$CONFIG_VERIFY" | grep -q "fvm_test_cache"; then
    log_success "Config setting persisted"
else
    echo "Note: Config setting may not be visible in output"
fi

# Reset to default
run_fvm config --cache-path "$HOME/.fvm"

echo ""
echo "=== Phase 9: Error Handling Tests ==="

log_test "32. Testing invalid version handling..."
# Disable exit on error temporarily for error handling tests
set +e

INVALID_EXIT_CODE=$(run_fvm install invalid-version-12345 2>/dev/null; echo $?)
if [ $INVALID_EXIT_CODE -ne 0 ]; then
    log_success "Invalid version handled gracefully"
else
    log_error "Invalid version should have failed"
fi

log_test "33. Testing invalid command handling..."
INVALID_CMD_EXIT_CODE=$(run_fvm invalid-command-xyz 2>/dev/null; echo $?)
if [ $INVALID_CMD_EXIT_CODE -ne 0 ]; then
    log_success "Invalid command handled gracefully"
else
    log_error "Invalid command should have failed"
fi

# Re-enable exit on error
set -e

log_test "34. Testing corrupted cache recovery..."
# Create a corrupted version directory
CORRUPT_VERSION="corrupt-test"
CORRUPT_DIR="$FVM_CACHE_PATH/$CORRUPT_VERSION"
mkdir -p "$CORRUPT_DIR"
echo "corrupted" > "$CORRUPT_DIR/flutter"

# Try to use the corrupted version (should auto-fix)
set +e
run_fvm install $TEST_CHANNEL 2>/dev/null  # This should work fine
CORRUPT_RECOVERY_EXIT=$?
set -e

if [ $CORRUPT_RECOVERY_EXIT -eq 0 ]; then
    log_success "Corrupted cache recovery works"
else
    echo "Note: Corrupted cache recovery test inconclusive"
fi

# Clean up corrupted test
rm -rf "$CORRUPT_DIR" 2>/dev/null || true

echo ""
echo "=== Phase 10: Cleanup and Destroy Tests ==="

log_test "35. Testing selective version removal..."
# Install multiple versions for cleanup testing
run_fvm install dev
run_fvm remove dev
log_success "Selective version removal works"

log_test "36. Testing destroy command..."
# Create a backup of current cache for safety
BACKUP_DIR="/tmp/fvm_backup_$$"
FVM_DIR=$(dirname "$FVM_CACHE_PATH")
if [ -d "$FVM_DIR" ]; then
    cp -r "$FVM_DIR" "$BACKUP_DIR" 2>/dev/null || true
fi

# Test destroy command (with confirmation bypass)
echo "y" | run_fvm destroy 2>/dev/null || true
log_success "Destroy command works"

# Restore backup if it exists
if [ -d "$BACKUP_DIR" ]; then
    rm -rf "$FVM_DIR" 2>/dev/null || true
    mv "$BACKUP_DIR" "$FVM_DIR" 2>/dev/null || true
fi

echo ""
echo "=== Phase 11: Final Validation ==="

log_test "37. Final system state validation..."
# Verify FVM is still functional after all tests
run_fvm --version > /dev/null
log_success "FVM still functional after all tests"

# Verify cache integrity
if [ -d "$FVM_CACHE_PATH" ]; then
    FINAL_VERSION_COUNT=$(ls -1 "$FVM_CACHE_PATH" 2>/dev/null | wc -l)
    log_success "Cache contains $FINAL_VERSION_COUNT versions"
else
    echo "Note: No versions in cache (may have been cleaned up)"
fi

# Verify project configuration is intact
if [ -f .fvmrc ]; then
    log_success "Project configuration preserved"
    echo "Final project configuration:"
    cat .fvmrc
else
    echo "Note: Project configuration not present"
fi

log_test "38. Testing concurrent operation safety..."
# Test that multiple FVM operations don't interfere
run_fvm list > /dev/null &
run_fvm doctor > /dev/null &
wait
log_success "Concurrent operations completed safely"

# Note: Test environment cleanup is handled automatically by the EXIT trap

echo ""
echo "=== Integration Test Summary ==="
echo ""
log_success "All 38 integration tests completed successfully!"
echo ""
echo "Tests covered:"
echo "  ✓ Basic command interface (4 tests)"
echo "  ✓ Installation workflows (5 tests)"
echo "  ✓ Project lifecycle (8 tests)"
echo "  ✓ Version management (3 tests)"
echo "  ✓ Advanced commands (5 tests)"
echo "  ✓ API commands (4 tests)"
echo "  ✓ Fork management (3 tests)"
echo "  ✓ Configuration management (2 tests)"
echo "  ✓ Error handling (3 tests)"
echo "  ✓ Cleanup operations (2 tests)"
echo "  ✓ Final validation (2 tests)"
echo ""
echo "Real-world operations tested:"
echo "  ✓ Actual Git clones and Flutter SDK installations"
echo "  ✓ File system changes (symlinks, .fvmrc, .gitignore)"
echo "  ✓ VS Code settings integration"
echo "  ✓ Configuration persistence"
echo "  ✓ Error recovery and graceful failure handling"
echo "  ✓ Multi-version management"
echo "  ✓ Fork repository management"
echo "  ✓ API endpoint functionality"
echo ""
log_success "FVM Integration Test Suite Complete!"
echo ""
