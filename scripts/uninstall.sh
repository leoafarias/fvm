#!/usr/bin/env bash
# Uninstall FVM - removes binary only, preserves cached SDKs
set -euo pipefail

# Paths
FVM_BASE="${FVM_HOME:-${HOME}/fvm}"
FVM_BIN_DIR="${FVM_BASE}/bin"
OLD_USER_PATH="${HOME}/.fvm_flutter"
OLD_SYSTEM_PATH="/usr/local/bin/fvm"

echo "Uninstalling FVM..."
echo ""

removed_any=0

# 1. Remove new binary directory (NOT entire ~/fvm/)
if [ -d "$FVM_BIN_DIR" ]; then
  rm -rf "$FVM_BIN_DIR" 2>/dev/null || true
  if [ ! -d "$FVM_BIN_DIR" ]; then
    echo "✓ Removed $FVM_BIN_DIR"
    removed_any=1
  else
    echo "⚠ Could not remove $FVM_BIN_DIR" >&2
  fi
fi

# 2. Remove old user directory (safe to nuke - installer-controlled)
if [ -d "$OLD_USER_PATH" ]; then
  rm -rf "$OLD_USER_PATH" 2>/dev/null || true
  if [ ! -d "$OLD_USER_PATH" ]; then
    echo "✓ Removed $OLD_USER_PATH"
    removed_any=1
  else
    echo "⚠ Could not remove $OLD_USER_PATH" >&2
  fi
fi

# 3. Remove old system symlink
if [ -L "$OLD_SYSTEM_PATH" ] || [ -f "$OLD_SYSTEM_PATH" ]; then
  rm -f "$OLD_SYSTEM_PATH" 2>/dev/null || \
    sudo rm -f "$OLD_SYSTEM_PATH" 2>/dev/null || true
  if [ ! -e "$OLD_SYSTEM_PATH" ]; then
    echo "✓ Removed $OLD_SYSTEM_PATH"
    removed_any=1
  else
    echo "⚠ Could not remove $OLD_SYSTEM_PATH (may need sudo)" >&2
  fi
fi

[ "$removed_any" -eq 0 ] && echo "No FVM installation found."

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Note: Cached Flutter SDKs remain in $FVM_BASE/versions/"
echo "      To remove them: rm -rf $FVM_BASE/"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Remove PATH entries from your shell config:"
echo "  - ~/.bashrc"
echo "  - ~/.zshrc"
echo "  - ~/.config/fish/config.fish"
echo ""
echo "Look for: $FVM_BIN_DIR"
echo ""
echo "FVM uninstalled successfully."
