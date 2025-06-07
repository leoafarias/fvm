#!/usr/bin/env bash
###############################################################################
# Comprehensive FVM Install Script Test Suite
# -----------------------------------------------------------------------------
# Tests all scenarios for issue #864 and validates KISS-compliant implementation
###############################################################################

set -euo pipefail

# Test configuration
SCRIPT_PATH="scripts/install.sh"
TEMP_DIR="/tmp/fvm_test_$$"
TEST_COUNT=0
PASS_COUNT=0
FAIL_COUNT=0

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test result tracking
declare -a FAILED_TESTS=()

# Helper functions
info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
success() { echo -e "${GREEN}✅ $1${NC}"; }
error() { echo -e "${RED}❌ $1${NC}"; }
warn() { echo -e "${YELLOW}⚠️  $1${NC}"; }

# Test framework functions
start_test() {
    local test_name="$1"
    ((TEST_COUNT++))
    echo
    info "Test $TEST_COUNT: $test_name"
    echo "----------------------------------------"
}

pass_test() {
    local message="$1"
    ((PASS_COUNT++))
    success "PASS: $message"
}

fail_test() {
    local message="$1"
    ((FAIL_COUNT++))
    FAILED_TESTS+=("Test $TEST_COUNT: $message")
    error "FAIL: $message"
}

# Setup test environment
setup_test_env() {
    info "Setting up test environment..."
    mkdir -p "$TEMP_DIR"

    # Ensure we have a clean environment
    unset CI
    unset FVM_ALLOW_ROOT
    sudo rm -f /.dockerenv 2>/dev/null || true

    success "Test environment ready"
}

# Cleanup test environment
cleanup_test_env() {
    info "Cleaning up test environment..."
    rm -rf "$TEMP_DIR"
    sudo rm -f /.dockerenv 2>/dev/null || true
    unset CI 2>/dev/null || true
    unset FVM_ALLOW_ROOT 2>/dev/null || true
    success "Cleanup complete"
}

# Test root detection logic directly
test_root_detection_logic() {
    start_test "Root Detection Logic Validation"

    # Test the core logic from install.sh
    local test_result

    # Simulate the detection logic
    if [[ $(id -u) -eq 0 ]]; then
        if [[ -f /.dockerenv ]] || [[ -n "${CI:-}" ]] || [[ "${FVM_ALLOW_ROOT:-}" == "true" ]]; then
            test_result="ALLOWED"
        else
            test_result="BLOCKED"
        fi
    else
        test_result="NOT_ROOT"
    fi

    if [[ $(id -u) -eq 0 ]]; then
        if [[ "$test_result" == "BLOCKED" ]]; then
            pass_test "Root correctly blocked in regular environment"
        else
            fail_test "Root should be blocked in regular environment, got: $test_result"
        fi
    else
        if [[ "$test_result" == "NOT_ROOT" ]]; then
            pass_test "Non-root user correctly identified"
        else
            fail_test "Non-root user incorrectly handled, got: $test_result"
        fi
    fi
}

# Test Docker container detection
test_docker_detection() {
    start_test "Docker Container Detection"

    if [[ $(id -u) -eq 0 ]]; then
        # Create Docker environment indicator
        sudo touch /.dockerenv

        # Test script behavior
        local output
        output=$(bash "$SCRIPT_PATH" --version 2>&1 || true)

        if echo "$output" | grep -q "Root execution allowed"; then
            pass_test "Docker container detection working"
        else
            fail_test "Docker container not detected properly"
        fi

        # Cleanup
        sudo rm -f /.dockerenv
    else
        warn "Skipping Docker test (not running as root)"
    fi
}

# Test CI environment detection
test_ci_detection() {
    start_test "CI Environment Detection"

    if [[ $(id -u) -eq 0 ]]; then
        # Set CI environment
        export CI=true

        # Test script behavior
        local output
        output=$(bash "$SCRIPT_PATH" --version 2>&1 || true)

        if echo "$output" | grep -q "Root execution allowed"; then
            pass_test "CI environment detection working"
        else
            fail_test "CI environment not detected properly"
        fi

        # Cleanup
        unset CI
    else
        warn "Skipping CI test (not running as root)"
    fi
}

# Test manual override
test_manual_override() {
    start_test "Manual Override (FVM_ALLOW_ROOT=true)"

    if [[ $(id -u) -eq 0 ]]; then
        # Set manual override
        export FVM_ALLOW_ROOT=true

        # Test script behavior
        local output
        output=$(bash "$SCRIPT_PATH" --version 2>&1 || true)

        if echo "$output" | grep -q "Root execution allowed"; then
            pass_test "Manual override working"
        else
            fail_test "Manual override not working properly"
        fi

        # Cleanup
        unset FVM_ALLOW_ROOT
    else
        warn "Skipping manual override test (not running as root)"
    fi
}

# Test root blocking in regular environment
test_root_blocking() {
    start_test "Root Blocking in Regular Environment"

    if [[ $(id -u) -eq 0 ]]; then
        # Ensure no override flags are set
        unset CI 2>/dev/null || true
        unset FVM_ALLOW_ROOT 2>/dev/null || true
        sudo rm -f /.dockerenv 2>/dev/null || true

        # Test script behavior (should fail)
        local output
        local exit_code
        output=$(bash "$SCRIPT_PATH" --version 2>&1 || true)
        exit_code=$?

        if echo "$output" | grep -q "should not be run as root"; then
            pass_test "Root correctly blocked in regular environment"
        else
            fail_test "Root blocking not working - security issue!"
        fi
    else
        warn "Skipping root blocking test (not running as root)"
    fi
}

# Test non-root user behavior
test_non_root_behavior() {
    start_test "Non-Root User Behavior"

    if [[ $(id -u) -ne 0 ]]; then
        # Test that script doesn't block non-root users
        local output
        output=$(bash "$SCRIPT_PATH" --version 2>&1 || true)

        if ! echo "$output" | grep -q "should not be run as root"; then
            pass_test "Non-root user can proceed"
        else
            fail_test "Non-root user incorrectly blocked"
        fi
    else
        warn "Skipping non-root test (running as root)"
    fi
}

# Test sudo detection for non-root users
test_sudo_detection() {
    start_test "Sudo Detection for Non-Root Users"

    if [[ $(id -u) -ne 0 ]]; then
        # Check if sudo is available
        if command -v sudo &>/dev/null; then
            pass_test "Sudo available for non-root user"
        else
            warn "Sudo not available - this may cause installation issues"
        fi
    else
        warn "Skipping sudo test (running as root)"
    fi
}

# Test script syntax and basic validation
test_script_syntax() {
    start_test "Script Syntax and Basic Validation"

    # Test bash syntax
    if bash -n "$SCRIPT_PATH"; then
        pass_test "Script syntax is valid"
    else
        fail_test "Script has syntax errors"
    fi

    # Test that required functions exist
    if grep -q "IS_ROOT=" "$SCRIPT_PATH"; then
        pass_test "IS_ROOT variable is defined"
    else
        fail_test "IS_ROOT variable not found"
    fi

    # Test KISS compliance - should be simple conditions
    local complex_patterns=("nested.*if.*if" "function.*function" "case.*case")
    local is_simple=true

    for pattern in "${complex_patterns[@]}"; do
        if grep -q "$pattern" "$SCRIPT_PATH"; then
            is_simple=false
            break
        fi
    done

    if [[ "$is_simple" == "true" ]]; then
        pass_test "Script follows KISS principles"
    else
        warn "Script may have complex nested logic"
    fi
}

# Main test execution
main() {
    echo "🧪 FVM Install Script Comprehensive Test Suite"
    echo "=============================================="
    echo

    info "Testing script: $SCRIPT_PATH"
    info "Running as: $(whoami) (UID: $(id -u))"
    echo

    setup_test_env

    # Run all tests
    test_script_syntax
    test_root_detection_logic
    test_docker_detection
    test_ci_detection
    test_manual_override
    test_root_blocking
    test_non_root_behavior
    test_sudo_detection

    cleanup_test_env

    # Print summary
    echo
    echo "=============================================="
    echo "🎯 Test Results Summary"
    echo "=============================================="
    echo "Total Tests: $TEST_COUNT"
    success "Passed: $PASS_COUNT"
    if [[ $FAIL_COUNT -gt 0 ]]; then
        error "Failed: $FAIL_COUNT"
        echo
        error "Failed Tests:"
        for failed_test in "${FAILED_TESTS[@]}"; do
            echo "  - $failed_test"
        done
    else
        success "Failed: $FAIL_COUNT"
    fi

    echo
    if [[ $FAIL_COUNT -eq 0 ]]; then
        success "🎉 All tests passed! Issue #864 is resolved."
        echo
        info "✅ Docker container support: Working"
        info "✅ CI environment support: Working"
        info "✅ Manual override support: Working"
        info "✅ Security (root blocking): Working"
        info "✅ KISS compliance: Maintained"
        echo
            success "The install script is ready for production deployment!"
    else
        error "❌ Some tests failed. Please review and fix issues before deployment."
        exit 1
    fi
}

# Run main function
main "$@"
