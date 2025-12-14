#!/usr/bin/env bash
# Uninstall FVM - removes the install bin directory, preserves cached SDKs
set -euo pipefail

# Paths
resolve_install_base() {
  local base="${FVM_INSTALL_DIR:-}"
  if [ -z "$base" ]; then
    base="${HOME}/fvm"
  fi

  case "$base" in
    \~) base="$HOME" ;;
    \~/*) base="$HOME/${base#\~/}" ;;
  esac

  printf '%s\n' "$base"
}

INSTALL_BASE="$(resolve_install_base)"
BIN_DIR="${INSTALL_BASE}/bin"

OLD_USER_PATH="${HOME}/.fvm_flutter"
OLD_SYSTEM_PATH="/usr/local/bin/fvm"

validate_install_base() {
  local base="$1"
  local bin_dir="${base}/bin"

  if [ -z "$base" ] || [ "$base" = "/" ]; then
    echo "error: refusing to use unsafe install base: '${base:-<empty>}'" >&2
    echo "       Set FVM_INSTALL_DIR to a directory under your HOME (default: \$HOME/fvm)" >&2
    exit 1
  fi

  case "$base" in
    /*) ;;
    *)
      echo "error: FVM_INSTALL_DIR must be an absolute path (got: $base)" >&2
      exit 1
      ;;
  esac

  if [ "$base" = "$HOME" ]; then
    echo "error: refusing to use HOME as install base ($HOME). Use a subdirectory like \$HOME/fvm." >&2
    exit 1
  fi

  case "$base" in
    "$HOME"/*) ;;
    *)
      echo "error: refusing to uninstall outside HOME: $base" >&2
      echo "       Use a directory under $HOME, or unset FVM_INSTALL_DIR to use the default." >&2
      exit 1
      ;;
  esac

  case "$bin_dir" in
    /bin|/usr/bin|/usr/local/bin|/sbin|/usr/sbin)
      echo "error: refusing to use unsafe bin directory: $bin_dir" >&2
      exit 1
      ;;
  esac
}

echo "Uninstalling FVM..."
echo ""

removed_any=0

validate_install_base "$INSTALL_BASE"

# 1. Remove install bin directory (NOT entire ~/fvm/)
if [ -d "$BIN_DIR" ]; then
  rm -rf "$BIN_DIR" 2>/dev/null || true
  if [ ! -d "$BIN_DIR" ]; then
    echo "✓ Removed $BIN_DIR"
    removed_any=1
  else
    echo "⚠ Could not remove $BIN_DIR" >&2
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
if [ -L "$OLD_SYSTEM_PATH" ]; then
  rm -f "$OLD_SYSTEM_PATH" 2>/dev/null || {
    if command -v sudo >/dev/null 2>&1; then
      sudo rm -f "$OLD_SYSTEM_PATH" 2>/dev/null
    fi
  } || true
  if [ ! -e "$OLD_SYSTEM_PATH" ]; then
    echo "✓ Removed $OLD_SYSTEM_PATH"
    removed_any=1
  else
    echo "⚠ Could not remove $OLD_SYSTEM_PATH (may need sudo)" >&2
  fi
elif [ -e "$OLD_SYSTEM_PATH" ]; then
  echo "⚠ Found existing non-symlink file at $OLD_SYSTEM_PATH; not removing automatically." >&2
fi

[ "$removed_any" -eq 0 ] && echo "No FVM installation found."

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Note: Cached Flutter SDKs remain in $INSTALL_BASE/versions/"
echo "      To remove them: rm -rf $INSTALL_BASE/"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Remove PATH entries from your shell config:"
echo "  - ~/.bashrc"
echo "  - ~/.zshrc"
echo "  - ~/.config/fish/config.fish"
echo ""
echo "Look for: $BIN_DIR"
echo ""
echo "FVM uninstalled successfully."
