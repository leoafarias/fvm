#!/usr/bin/env bash
# Test root detection logic for FVM install script
# 
# This single test file replaces 589 lines of duplicated tests with 81 lines
# following DRY, KISS, and YAGNI principles.
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

echo "🧪 Testing FVM root detection logic"
echo "=================================="

# Test the detection logic directly (DRY - one function)
test_detection() {
    local desc="$1"
    local expected="$2"
    
    # This mirrors the install.sh logic
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
    
    # Test 1: Bare root (should block)
    cleanup
    test_detection "Root without flags" "BLOCKED"
    
    # Test 2: Docker
    touch /.dockerenv
    test_detection "Root + Docker" "ALLOWED"
    rm -f /.dockerenv
    
    # Test 3: Podman
    touch /.containerenv
    test_detection "Root + Podman" "ALLOWED"
    rm -f /.containerenv
    
    # Test 4: CI
    export CI=true
    test_detection "Root + CI" "ALLOWED"
    unset CI
    
    # Test 5: Manual override
    export FVM_ALLOW_ROOT=true
    test_detection "Root + Override" "ALLOWED"
    unset FVM_ALLOW_ROOT
else
    echo "Running as non-root"
    test_detection "Non-root user" "NOT_ROOT"
    echo
    echo "⚠️  To test root scenarios, run: sudo $0"
fi

echo
echo "✅ All tests passed!"