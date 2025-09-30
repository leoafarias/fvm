#!/usr/bin/env bash
# Quick local validation for install.sh
# Usage: ./scripts/test-local.sh

set -e

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
BOLD='\033[1m'
NC='\033[0m'

echo -e "${BOLD}🧪 Testing FVM installation locally...${NC}"
echo ""

# Test 1: Clean install
echo "Test 1: Clean install"
rm -rf ~/.fvm_flutter /tmp/fvm_test 2>/dev/null || true
./scripts/install.sh > /dev/null 2>&1
~/.fvm_flutter/bin/fvm --version > /dev/null
echo -e "${GREEN}✅ Clean install works${NC}"
echo ""

# Test 2: Reinstall (idempotency)
echo "Test 2: Reinstall (idempotency)"
./scripts/install.sh > /dev/null 2>&1
~/.fvm_flutter/bin/fvm --version > /dev/null
echo -e "${GREEN}✅ Reinstall works${NC}"
echo ""

# Test 3: Custom directory
echo "Test 3: Custom directory"
FVM_DIR=/tmp/fvm_test ./scripts/install.sh > /dev/null 2>&1
/tmp/fvm_test/bin/fvm --version > /dev/null
echo -e "${GREEN}✅ Custom directory works${NC}"
echo ""

# Test 4: Uninstall
echo "Test 4: Uninstall"
./scripts/uninstall.sh > /dev/null 2>&1
if [[ -d ~/.fvm_flutter ]]; then
  echo -e "${RED}❌ Uninstall failed - directory still exists${NC}"
  exit 1
fi
echo -e "${GREEN}✅ Uninstall works${NC}"
echo ""

# Cleanup
rm -rf /tmp/fvm_test 2>/dev/null || true

echo ""
echo -e "${BOLD}${GREEN}🎉 All local tests passed!${NC}"
echo ""
echo "Next steps:"
echo "  • Run Docker tests: docker run --rm -v \"\$PWD:/workspace\" -w /workspace debian:12 bash -c \"apt-get update && apt-get install -y curl tar && ./scripts/install.sh\""
echo "  • Push changes and check CI"