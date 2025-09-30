#!/usr/bin/env bash
# Validation script for install.sh
# Tests the installation script against real FVM releases

set -euo pipefail

# Colors
if [[ -z "${NO_COLOR:-}" ]]; then
  RED='\033[0;31m'
  GREEN='\033[0;32m'
  YELLOW='\033[1;33m'
  NC='\033[0m'
else
  RED=''
  GREEN=''
  YELLOW=''
  NC=''
fi

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Logging functions
info() {
  echo -e "${YELLOW}► $1${NC}"
}

success() {
  echo -e "${GREEN}✓ $1${NC}"
  TESTS_PASSED=$((TESTS_PASSED + 1))
}

fail() {
  echo -e "${RED}✗ $1${NC}"
  TESTS_FAILED=$((TESTS_FAILED + 1))
}

# Test framework
test_name=""
start_test() {
  test_name="$1"
  TESTS_RUN=$((TESTS_RUN + 1))
  info "Test $TESTS_RUN: $test_name"
}

pass_test() {
  success "$test_name"
}

fail_test() {
  fail "$test_name - $1"
}

# Setup
TEST_DIR=$(mktemp -d)
trap 'rm -rf "$TEST_DIR"' EXIT

info "Test directory: $TEST_DIR"
echo ""

# Test 1: Verify cli_pkg archive structure
start_test "Download and inspect real release archive structure"

VERSION="3.2.1"
OS="macos"
ARCH="arm64"
URL="https://github.com/leoafarias/fvm/releases/download/$VERSION/fvm-$VERSION-$OS-$ARCH.tar.gz"

if curl -fsSL --max-time 30 "$URL" -o "$TEST_DIR/test.tar.gz"; then
  # Inspect structure
  STRUCTURE=$(tar -tzf "$TEST_DIR/test.tar.gz" | head -10)

  if echo "$STRUCTURE" | grep -q "^fvm/fvm$" && \
     echo "$STRUCTURE" | grep -q "^fvm/src/dart$" && \
     echo "$STRUCTURE" | grep -q "^fvm/src/fvm.snapshot$"; then
    pass_test
    info "Archive structure:"
    echo "$STRUCTURE" | sed 's/^/  /'
  else
    fail_test "Unexpected archive structure"
    info "Found structure:"
    echo "$STRUCTURE" | sed 's/^/  /'
  fi
else
  fail_test "Failed to download release"
fi
echo ""

# Test 2: Verify extraction preserves structure
start_test "Extract archive and verify directory layout"

mkdir -p "$TEST_DIR/extract"
if tar -xzf "$TEST_DIR/test.tar.gz" -C "$TEST_DIR/extract"; then
  if [[ -f "$TEST_DIR/extract/fvm/fvm" ]] && \
     [[ -d "$TEST_DIR/extract/fvm/src" ]] && \
     [[ -f "$TEST_DIR/extract/fvm/src/dart" ]] && \
     [[ -f "$TEST_DIR/extract/fvm/src/fvm.snapshot" ]]; then
    pass_test
  else
    fail_test "Missing expected files after extraction"
    info "Found:"
    find "$TEST_DIR/extract" -type f | sed 's/^/  /'
  fi
else
  fail_test "Extraction failed"
fi
echo ""

# Test 3: Verify fvm wrapper is executable
start_test "Check fvm wrapper script is executable"

if [[ -x "$TEST_DIR/extract/fvm/fvm" ]]; then
  pass_test
else
  fail_test "fvm wrapper not executable"
fi
echo ""

# Test 4: Test fvm wrapper runs
start_test "Execute fvm wrapper to verify functionality"

export PATH="$TEST_DIR/extract/fvm:$PATH"
if "$TEST_DIR/extract/fvm/fvm" --version &>/dev/null; then
  VERSION_OUTPUT=$("$TEST_DIR/extract/fvm/fvm" --version)
  pass_test
  info "Version output: $VERSION_OUTPUT"
else
  fail_test "fvm wrapper failed to execute"
fi
echo ""

# Test 5: Simulate install script's structure handling
start_test "Simulate current install.sh structure handling (should fail)"

mkdir -p "$TEST_DIR/test_current_method/bin"
cp -r "$TEST_DIR/extract/fvm" "$TEST_DIR/test_current_method/temp_fvm"

# This is what current install.sh does (WRONG):
if mv "$TEST_DIR/test_current_method/temp_fvm"/* "$TEST_DIR/test_current_method/bin/" 2>/dev/null; then
  # Check if src/ subdirectory still exists properly
  if [[ -d "$TEST_DIR/test_current_method/bin/src" ]] && \
     [[ -f "$TEST_DIR/test_current_method/bin/src/dart" ]]; then
    fail_test "Current method worked (unexpected - structure may have changed)"
  else
    pass_test
    info "Confirmed: mv fvm/* breaks subdirectory structure"
  fi
else
  pass_test
  info "Confirmed: mv fvm/* fails with current structure"
fi
echo ""

# Test 6: Simulate correct structure handling
start_test "Simulate correct structure handling (proposed fix)"

mkdir -p "$TEST_DIR/test_correct_method"
FVM_DIR="$TEST_DIR/test_correct_method"
FVM_DIR_BIN="$FVM_DIR/bin"
mkdir -p "$FVM_DIR_BIN"

cp -r "$TEST_DIR/extract/fvm" "$FVM_DIR/"

# Create symlink (proposed fix)
ln -sf "$FVM_DIR/fvm/fvm" "$FVM_DIR_BIN/fvm"

if [[ -L "$FVM_DIR_BIN/fvm" ]] && \
   [[ -f "$FVM_DIR/fvm/src/dart" ]] && \
   [[ -x "$FVM_DIR_BIN/fvm" ]]; then
  pass_test
  info "Structure preserved correctly"
else
  fail_test "Symlink or structure incorrect"
fi
echo ""

# Test 7: Verify corrected installation works
start_test "Execute fvm through corrected installation layout"

if "$TEST_DIR/test_correct_method/bin/fvm" --version &>/dev/null; then
  pass_test
else
  fail_test "fvm doesn't work through corrected layout"
fi
echo ""

# Test 8: Verify version detection method
start_test "Test current version detection method"

DETECTED_VERSION=$(curl -sI https://github.com/leoafarias/fvm/releases/latest | \
  grep -i location | cut -d' ' -f2 | rev | cut -d'/' -f1 | rev | tr -d '\r')

if [[ -n "$DETECTED_VERSION" ]] && [[ "$DETECTED_VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  pass_test
  info "Detected version: $DETECTED_VERSION"
else
  fail_test "Version detection failed or invalid format: '$DETECTED_VERSION'"
fi
echo ""

# Summary
echo ""
echo "========================================"
echo "          VALIDATION SUMMARY"
echo "========================================"
echo -e "Total tests:  $TESTS_RUN"
echo -e "${GREEN}Passed:       $TESTS_PASSED${NC}"
if [[ $TESTS_FAILED -gt 0 ]]; then
  echo -e "${RED}Failed:       $TESTS_FAILED${NC}"
  exit 1
else
  echo -e "${GREEN}Failed:       0${NC}"
  echo ""
  success "All validation tests passed!"
  exit 0
fi