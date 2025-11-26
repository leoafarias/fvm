#!/usr/bin/env bash
# Install FVM to user-local directory ($HOME/.fvm_flutter/bin)
# No sudo required. Add to PATH after installation.
set -euo pipefail
umask 022

# ---- installer metadata ----
readonly INSTALLER_NAME="install_fvm.sh"
readonly INSTALLER_VERSION="3.0.0"  # v3: single behavior, user-local only

# ---- config ----
readonly REPO="leoafarias/fvm"
readonly INSTALL_BASE="${HOME}/.fvm_flutter"
readonly BIN_DIR="${INSTALL_BASE}/bin"
readonly TMP_DIR="${INSTALL_BASE}/temp_extract"
readonly OLD_SYSTEM_PATH="/usr/local/bin/fvm"

UNINSTALL_ONLY=0
REQUESTED_VERSION=""

# ---- helpers ----
usage() {
  cat <<'EOF'
FVM Installer v3.0.0 - User-Local Installation

USAGE:
  install.sh [FLAGS] [VERSION]

ARGUMENTS:
  VERSION               Version to install (e.g., 4.0.1 or v4.0.1)
                        If omitted, installs the latest version

FLAGS:
  -h, --help            Show this help and exit
  -v, --version         Show installer version and exit
  --uninstall           Remove FVM installation

EXAMPLES:
  # Install latest version
  curl -fsSL https://fvm.app/install.sh | bash

  # Install specific version
  ./install.sh 4.0.1

  # Uninstall
  ./install.sh --uninstall

AFTER INSTALLATION:
  Add FVM to your PATH by adding this line to your shell config:

    export PATH="$HOME/.fvm_flutter/bin:$PATH"

  Then restart your shell or run: source ~/.bashrc

FOR MORE INFO:
  https://fvm.app/docs/getting_started/installation
EOF
}

print_installer_version() {
  printf '%s version %s\n' "$INSTALLER_NAME" "$INSTALLER_VERSION"
}

require() { command -v "$1" >/dev/null 2>&1 || { echo "error: $1 is required" >&2; exit 1; }; }

normalize_version() { printf '%s\n' "${1#v}"; }

get_latest_version() {
  # Follows redirect from /releases/latest -> .../tag/vX.Y.Z
  local url
  url="$(curl -fsSLI -o /dev/null -w '%{url_effective}' "https://github.com/${REPO}/releases/latest")" || return 1
  normalize_version "${url##*/}"
}

print_path_instructions() {
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "✓ Installation complete!"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  echo "To use FVM, add it to your PATH:"
  echo ""
  echo "  # For bash (add to ~/.bashrc):"
  echo '  export PATH="$HOME/.fvm_flutter/bin:$PATH"'
  echo ""
  echo "  # For zsh (add to ~/.zshrc):"
  echo '  export PATH="$HOME/.fvm_flutter/bin:$PATH"'
  echo ""
  echo "  # For fish (run once):"
  echo '  fish_add_path "$HOME/.fvm_flutter/bin"'
  echo ""
  echo "Then restart your shell or run:"
  echo "  source ~/.bashrc  # or ~/.zshrc"
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

migrate_from_v1() {
  # Automatically remove old system install (v1 or v2 --system)
  if [ -L "$OLD_SYSTEM_PATH" ] || [ -f "$OLD_SYSTEM_PATH" ]; then
    echo "" >&2
    echo "Detected old installation at $OLD_SYSTEM_PATH" >&2
    echo "Migrating to user-local install..." >&2

    # Try to remove without sudo first (|| true prevents set -e exit)
    rm -f "$OLD_SYSTEM_PATH" 2>/dev/null || true
    if [ ! -e "$OLD_SYSTEM_PATH" ]; then
      echo "✓ Removed old system install" >&2
    else
      # Try with sudo if available
      if command -v sudo >/dev/null 2>&1; then
        sudo rm -f "$OLD_SYSTEM_PATH" 2>/dev/null || true
        if [ ! -e "$OLD_SYSTEM_PATH" ]; then
          echo "✓ Removed old system install (required sudo)" >&2
        else
          echo "⚠ Could not remove $OLD_SYSTEM_PATH" >&2
          echo "  You may remove it manually: sudo rm $OLD_SYSTEM_PATH" >&2
        fi
      else
        echo "⚠ Could not remove $OLD_SYSTEM_PATH (need sudo)" >&2
        echo "  You may remove it manually with: sudo rm $OLD_SYSTEM_PATH" >&2
      fi
    fi
  fi
}

do_uninstall() {
  local removed_any=0

  echo "Uninstalling FVM..." >&2
  echo "" >&2

  # Remove user installation directory (|| true prevents set -e exit)
  if [ -d "$INSTALL_BASE" ]; then
    rm -rf "$INSTALL_BASE" 2>/dev/null || true
    if [ ! -d "$INSTALL_BASE" ]; then
      echo "✓ Removed user directory: $INSTALL_BASE" >&2
      removed_any=1
    else
      echo "⚠ Could not remove $INSTALL_BASE (check permissions)" >&2
    fi
  fi

  # Remove old system install if present (from v1/v2)
  if [ -L "$OLD_SYSTEM_PATH" ] || [ -f "$OLD_SYSTEM_PATH" ]; then
    rm -f "$OLD_SYSTEM_PATH" 2>/dev/null || true
    if [ ! -e "$OLD_SYSTEM_PATH" ]; then
      echo "✓ Removed old system install: $OLD_SYSTEM_PATH" >&2
      removed_any=1
    else
      if command -v sudo >/dev/null 2>&1; then
        sudo rm -f "$OLD_SYSTEM_PATH" 2>/dev/null || true
        if [ ! -e "$OLD_SYSTEM_PATH" ]; then
          echo "✓ Removed old system install: $OLD_SYSTEM_PATH" >&2
          removed_any=1
        else
          echo "⚠ Could not remove $OLD_SYSTEM_PATH (may need sudo)" >&2
        fi
      else
        echo "⚠ Could not remove $OLD_SYSTEM_PATH (may need sudo)" >&2
      fi
    fi
  fi

  if [ "$removed_any" -eq 0 ]; then
    echo "No FVM installation found (ok)" >&2
  fi

  echo "" >&2
  echo "Uninstall complete." >&2
  echo "" >&2
  echo "Note: You may want to remove PATH entries from your shell config:" >&2
  echo "  - ~/.bashrc" >&2
  echo "  - ~/.zshrc" >&2
  echo "  - ~/.config/fish/config.fish" >&2
  echo "" >&2
  echo 'Look for lines containing: $HOME/.fvm_flutter/bin' >&2

  exit 0
}

# ---- arg parsing ----
for arg in "$@"; do
  case "$arg" in
    -h|--help) usage; exit 0 ;;
    -v|--version) print_installer_version; exit 0 ;;
    --uninstall) UNINSTALL_ONLY=1 ;;
    v[0-9]*|[0-9]*.[0-9]*.[0-9]*) REQUESTED_VERSION="$arg" ;;
    *)
      echo "error: unknown argument: $arg" >&2
      echo ""
      usage
      exit 1
      ;;
  esac
done

# ---- handle uninstall ----
if [ "$UNINSTALL_ONLY" -eq 1 ]; then
  do_uninstall
fi

# ---- root user handling ----
if [ "${EUID:-$(id -u)}" -eq 0 ]; then
  echo "⚠ Warning: Running as root" >&2
  echo "  FVM will be installed to $HOME/.fvm_flutter/bin and likely won't be accessible to other users." >&2
  echo "  It is recommended that each user install FVM individually in their own home directory." >&2
  echo "" >&2
fi

# ---- prereqs ----
require curl
require tar
[ -n "${BASH_VERSION:-}" ] || { echo "error: bash is required to run this installer" >&2; exit 1; }

# ---- detect OS ----
case "$(uname -s)" in
  Linux)  OS="linux" ;;
  Darwin) OS="macos" ;;
  *) echo "error: unsupported OS: $(uname -s)" >&2; exit 1 ;;
esac
readonly OS

# ---- detect ARCH ----
case "$(uname -m)" in
  x86_64|amd64)                   ARCH="x64" ;;
  aarch64|arm64)                  ARCH="arm64" ;;
  armv7l|armv7|armv6l|armv6|armhf) ARCH="arm" ;;
  riscv64)                        ARCH="riscv64" ;;
  *) echo "error: unsupported architecture: $(uname -m)" >&2; exit 1 ;;
esac
readonly ARCH

# ---- detect libc (Linux only), musl suffix only for x64/arm64 ----
LIBC_SUFFIX=""
if [ "$OS" = "linux" ] && { [ "$ARCH" = "x64" ] || [ "$ARCH" = "arm64" ]; }; then
  if (ldd --version 2>&1 | grep -qi musl) || grep -qi musl /proc/self/maps 2>/dev/null; then
    LIBC_SUFFIX="-musl"
    echo "" >&2
    echo "Note: Detected musl libc (Alpine Linux)." >&2
    echo "      Flutter SDK requires glibc. You may need: apk add gcompat" >&2
    echo "" >&2
  fi
fi
readonly LIBC_SUFFIX

# ---- resolve version ----
if [ -n "$REQUESTED_VERSION" ]; then
  VERSION="$(normalize_version "$REQUESTED_VERSION")"
else
  echo "Fetching latest FVM version..." >&2
  VERSION="$(get_latest_version)" || { echo "error: failed to determine latest version" >&2; exit 1; }
fi

echo "Installing FVM ${VERSION} for ${OS}-${ARCH}${LIBC_SUFFIX}..." >&2

# ---- construct asset URL and validate existence, with musl->glibc fallback ----
TARBALL="fvm-${VERSION}-${OS}-${ARCH}${LIBC_SUFFIX}.tar.gz"
URL="https://github.com/${REPO}/releases/download/${VERSION}/${TARBALL}"

if ! curl -fsSLI -o /dev/null "$URL"; then
  if [ -n "$LIBC_SUFFIX" ]; then
    ALT_URL="https://github.com/${REPO}/releases/download/${VERSION}/fvm-${VERSION}-${OS}-${ARCH}.tar.gz"
    if curl -fsSLI -o /dev/null "$ALT_URL"; then
      URL="$ALT_URL"
      TARBALL="fvm-${VERSION}-${OS}-${ARCH}.tar.gz"
      echo "Note: Using glibc variant (musl not available)" >&2
    else
      echo "error: no asset found for ${OS}/${ARCH} (tried musl and glibc variants)" >&2
      exit 1
    fi
  else
    echo "error: asset not found: $URL" >&2
    exit 1
  fi
fi

# ---- prep dirs and cleanup trap ----
rm -rf "$TMP_DIR" 2>/dev/null || true  # Clear any stale content from previous runs
mkdir -p "$BIN_DIR" "$TMP_DIR"
cleanup() { rm -rf "$TMP_DIR" 2>/dev/null || true; }
trap cleanup EXIT

# ---- download ----
ARCHIVE="${TMP_DIR}/${TARBALL}"
echo "Downloading ${URL##*/}..." >&2
curl -fsSL "$URL" -o "$ARCHIVE"

# ---- validate archive ----
if ! tar -tzf "$ARCHIVE" >/dev/null 2>&1; then
  echo "error: downloaded archive appears corrupted" >&2
  exit 1
fi

# ---- validate no path traversal ----
if tar -tzf "$ARCHIVE" | grep -qE '^/|(\.\./)|(/\.\.)'; then
  echo "error: archive contains unsafe paths (absolute or traversal)" >&2
  exit 1
fi

# ---- extract ----
echo "Extracting..." >&2
tar -xzf "$ARCHIVE" -C "$TMP_DIR"

# ---- locate binary and copy contents per tarball structure ----
if [ -d "${TMP_DIR}/fvm" ] && [ -f "${TMP_DIR}/fvm/fvm" ]; then
  cp -a "${TMP_DIR}/fvm/." "$BIN_DIR/"
elif [ -f "${TMP_DIR}/fvm" ]; then
  cp -a "${TMP_DIR}/fvm" "${BIN_DIR}/fvm"
else
  FOUND="$(find "$TMP_DIR" -type f -name 'fvm' 2>/dev/null | head -n1 || true)"
  [ -n "$FOUND" ] || { echo "error: fvm binary not found in archive" >&2; exit 1; }
  cp -a "$FOUND" "${BIN_DIR}/fvm"
fi
chmod +x "${BIN_DIR}/fvm"

# ---- verify binary works (non-fatal) ----
if ! "${BIN_DIR}/fvm" --version >/dev/null 2>&1; then
  echo "⚠ Installed, but running '${BIN_DIR}/fvm --version' failed." >&2
  echo "  Ensure system libraries are present." >&2
fi

# ---- migrate from v1/v2 ----
migrate_from_v1

# ---- success ----
echo ""
echo "Installed to: ${BIN_DIR}/fvm"
echo "FVM version: ${VERSION}"

# ---- print PATH instructions ----
print_path_instructions
