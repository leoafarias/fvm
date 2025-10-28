#!/usr/bin/env bash
# Quick smoke test - run before pushing install.sh changes
# Full cross-platform tests run in CI (.github/workflows/test-install.yml)

set -euo pipefail

SMOKE_DIR="$(mktemp -d)"
trap 'rm -rf "$SMOKE_DIR"' EXIT INT TERM

echo "🔥 Smoke testing install.sh"

# Test 1: Basic install works
echo "→ Basic installation"
FVM_DIR="$SMOKE_DIR/fvm" FVM_NO_PATH=true bash scripts/install.sh 3.2.1 >/dev/null
test -x "$SMOKE_DIR/fvm/bin/fvm" || { echo "❌ Binary not found"; exit 1; }
"$SMOKE_DIR/fvm/bin/fvm" --version >/dev/null || { echo "❌ Binary doesn't run"; exit 1; }

# Test 2: Dangerous paths blocked
echo "→ Dangerous path rejection"
if FVM_DIR="/usr" bash scripts/install.sh 3.2.1 2>/dev/null; then
  echo "❌ Should block dangerous paths"; exit 1
fi

# Test 3: Reinstall works (idempotent)
echo "→ Reinstall/upgrade"
FVM_DIR="$SMOKE_DIR/fvm" FVM_NO_PATH=true bash scripts/install.sh 3.2.1 >/dev/null
"$SMOKE_DIR/fvm/bin/fvm" --version >/dev/null || { echo "❌ Reinstall failed"; exit 1; }

echo "✅ Smoke tests passed"
echo "   For full tests: gh workflow run test-install.yml"
