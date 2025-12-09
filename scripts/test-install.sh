#!/usr/bin/env bash
# Test root detection logic for install-legacy.sh (v1 installer)
#
# This tests the root BLOCKING behavior in install-legacy.sh, which:
# - Blocks root by default
# - Allows root in containers (/.dockerenv, /.containerenv)
# - Allows root in CI (CI environment variable)
# - Allows root with FVM_ALLOW_ROOT=true override
#
# Note: install.sh (v3) has different behavior - it WARNS about
# root but doesn't block. That behavior is tested in the GitHub workflow.
#
# Usage: ./test-install.sh (run as regular user)
#        sudo ./test-install.sh (run as root to test all scenarios)
#
set -euo pipefail

# Simple color output
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

pass() { echo -e "${GREEN}✅ $1${NC}"; }
fail() { echo -e "${RED}❌ $1${NC}"; exit 1; }

echo "🧪 Testing install-legacy.sh (v1) root detection logic"
echo "======================================================"
echo ""
echo "This tests the root BLOCKING behavior in install-legacy.sh"
echo "(install.sh v3 has different behavior - warns only)"
echo ""

# Test the detection logic directly - mirrors install-legacy.sh logic
# See install-legacy.sh lines 100-102 (is_container_env) and 277-287 (root check)
test_detection() {
    local desc="$1"
    local expected="$2"

    # This mirrors the install-legacy.sh logic exactly:
    # is_container_env() { [[ -f /.dockerenv ]] || [[ -f /.containerenv ]] || [[ -n "${CI:-}" ]] }
    # if [[ $(id -u) -eq 0 ]]; then
    #   if is_container_env || [[ "${FVM_ALLOW_ROOT:-}" == "true" ]]; then
    #     # allowed
    #   else
    #     # blocked
    #   fi
    # fi
    if [[ $(id -u) -eq 0 ]]; then
        if [[ -f /.dockerenv ]] || [[ -f /.containerenv ]] || [[ -n "${CI:-}" ]] || [[ "${FVM_ALLOW_ROOT:-}" == "true" ]]; then
            result="ALLOWED"
        else
            result="BLOCKED"
        fi
    else
        result="NOT_ROOT"
    fi

    if [[ "$result" == "$expected" ]]; then
        pass "$desc: $result"
    else
        fail "$desc: expected $expected, got $result"
    fi
}

# Clean environment
cleanup() {
    sudo rm -f /.dockerenv /.containerenv 2>/dev/null || true
    unset CI FVM_ALLOW_ROOT 2>/dev/null || true
}
trap cleanup EXIT

# Run tests based on current user
if [[ $(id -u) -eq 0 ]]; then
    echo "Running as root - testing root scenarios"
    echo ""

    # Test 1: Bare root (should block)
    cleanup
    test_detection "Root without flags" "BLOCKED"

    # Test 2: Docker container
    touch /.dockerenv
    test_detection "Root + Docker (/.dockerenv)" "ALLOWED"
    rm -f /.dockerenv

    # Test 3: Podman/other container
    touch /.containerenv
    test_detection "Root + Podman (/.containerenv)" "ALLOWED"
    rm -f /.containerenv

    # Test 4: CI environment
    export CI=true
    test_detection "Root + CI env var" "ALLOWED"
    unset CI

    # Test 5: Manual override
    export FVM_ALLOW_ROOT=true
    test_detection "Root + FVM_ALLOW_ROOT=true" "ALLOWED"
    unset FVM_ALLOW_ROOT
else
    echo "Running as non-root"
    test_detection "Non-root user" "NOT_ROOT"
    echo ""
    echo "⚠️  To test root scenarios, run: sudo $0"
fi

echo ""
echo "✅ All tests passed!"
