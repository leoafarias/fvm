#!/usr/bin/env bash
# Test install.sh root warning behavior
#
# The current install.sh behavior is:
# - Warns when running as root
# - Still proceeds (it does not block root)
#
# To avoid downloading/installing binaries, this test intentionally forces an
# early failure (unsafe install base) after the root warning is printed.
#
# Usage:
#   ./test-install.sh         (run as regular user)
#   sudo ./test-install.sh    (run as root)
#
set -euo pipefail

RED=$'\033[0;31m'
GREEN=$'\033[0;32m'
NC=$'\033[0m'

pass() { echo -e "${GREEN}✅ $1${NC}"; }
fail() { echo -e "${RED}❌ $1${NC}"; exit 1; }

echo "🧪 Testing scripts/install.sh root warning behavior"
echo "=================================================="
echo ""
echo "This test forces an early failure to avoid downloads."
echo ""

run_install_sh_with_early_failure() {
  # Use an unsafe install base (/) so install.sh exits before requiring curl/tar.
  # This should still print the root warning when executed as root.
  FVM_INSTALL_DIR="/" ./scripts/install.sh 2>&1 || true
}

assert_contains() {
  local haystack="$1"
  local needle="$2"
  if echo "$haystack" | grep -Fq "$needle"; then
    pass "Contains: $needle"
  else
    echo "$haystack" >&2
    fail "Expected output to contain: $needle"
  fi
}

assert_not_contains() {
  local haystack="$1"
  local needle="$2"
  if echo "$haystack" | grep -Fq "$needle"; then
    echo "$haystack" >&2
    fail "Expected output to NOT contain: $needle"
  else
    pass "Does not contain: $needle"
  fi
}

if [[ $(id -u) -eq 0 ]]; then
  echo "Running as root"
  echo ""

  output="$(run_install_sh_with_early_failure)"
  assert_contains "$output" "⚠ Warning: Running as root"
  assert_contains "$output" "refusing to use unsafe install base"
else
  echo "Running as non-root"
  echo ""

  output="$(run_install_sh_with_early_failure)"
  assert_not_contains "$output" "⚠ Warning: Running as root"
  assert_contains "$output" "refusing to use unsafe install base"

  echo ""
  echo "ℹ️  To test root behavior, run: sudo $0"
fi

echo ""
echo "✅ All tests passed!"
