#!/usr/bin/env bash
# Install FVM to user-local directory ($HOME/.fvm_flutter/bin)
# No sudo required. Add to PATH after installation.
set -Eeuo pipefail
umask 022

# ---- installer metadata ----
INSTALLER_NAME="install_fvm.sh"
INSTALLER_VERSION="3.0.0"  # v3: single behavior, user-local only

# ---- config ----
REPO="leoafarias/fvm"
INSTALL_BASE="${HOME}/.fvm_flutter"
BIN_DIR="${INSTALL_BASE}/bin"
TMP_DIR="${INSTALL_BASE}/temp_extract"
OLD_SYSTEM_PATH="/usr/local/bin/fvm"

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

normalize_version() { printf '%s\n' "$1" | sed -E 's/^v//'; }

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
    echo ""
    echo "Detected old installation at $OLD_SYSTEM_PATH"
    echo "Migrating to user-local install..."

    # Try to remove without sudo first
    rm "$OLD_SYSTEM_PATH" 2>/dev/null
    if [ ! -e "$OLD_SYSTEM_PATH" ]; then
      echo "✓ Removed old system install"
    else
      # Try with sudo if available
      if command -v sudo >/dev/null 2>&1; then
        sudo rm "$OLD_SYSTEM_PATH" 2>/dev/null
        if [ ! -e "$OLD_SYSTEM_PATH" ]; then
          echo "✓ Removed old system install (required sudo)"
        else
          echo "⚠ Could not remove $OLD_SYSTEM_PATH"
          echo "  You may remove it manually: sudo rm $OLD_SYSTEM_PATH"
        fi
      else
        echo "⚠ Could not remove $OLD_SYSTEM_PATH (need sudo)"
        echo "  You may remove it manually with: sudo rm $OLD_SYSTEM_PATH"
      fi
    fi
  fi
}

do_uninstall() {
  local removed_any=0

  echo "Uninstalling FVM..."
  echo ""

  # Remove user installation directory
  if [ -d "$INSTALL_BASE" ]; then
    rm -rf "$INSTALL_BASE"
    echo "✓ Removed user directory: $INSTALL_BASE"
    removed_any=1
  fi

  # Remove old system install if present (from v1/v2)
  if [ -L "$OLD_SYSTEM_PATH" ] || [ -f "$OLD_SYSTEM_PATH" ]; then
    rm "$OLD_SYSTEM_PATH" 2>/dev/null
    if [ ! -e "$OLD_SYSTEM_PATH" ]; then
      echo "✓ Removed old system install: $OLD_SYSTEM_PATH"
      removed_any=1
    else
      if command -v sudo >/dev/null 2>&1; then
        sudo rm "$OLD_SYSTEM_PATH" 2>/dev/null
        if [ ! -e "$OLD_SYSTEM_PATH" ]; then
          echo "✓ Removed old system install: $OLD_SYSTEM_PATH"
          removed_any=1
        else
          echo "⚠ Could not remove $OLD_SYSTEM_PATH (may need sudo)"
        fi
      else
        echo "⚠ Could not remove $OLD_SYSTEM_PATH (may need sudo)"
      fi
    fi
  fi

  if [ "$removed_any" -eq 0 ]; then
    echo "No FVM installation found (ok)"
  fi

  echo ""
  echo "Uninstall complete."
  echo ""
  echo "Note: You may want to remove PATH entries from your shell config:"
  echo "  - ~/.bashrc"
  echo "  - ~/.zshrc"
  echo "  - ~/.config/fish/config.fish"
  echo ""
  echo 'Look for lines containing: $HOME/.fvm_flutter/bin'

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
  echo "⚠ Running as root"
  echo "  FVM will be installed to /root/.fvm_flutter/bin"
  echo "  For system-wide access, each user should install FVM individually."
  echo ""
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

# ---- detect ARCH ----
case "$(uname -m)" in
  x86_64|amd64)                   ARCH="x64" ;;
  aarch64|arm64)                  ARCH="arm64" ;;
  armv7l|armv7|armv6l|armv6|armhf) ARCH="arm" ;;
  riscv64)                        ARCH="riscv64" ;;
  *) echo "error: unsupported architecture: $(uname -m)" >&2; exit 1 ;;
esac

# ---- detect libc (Linux only), musl suffix only for x64/arm64 ----
LIBC_SUFFIX=""
if [ "$OS" = "linux" ] && { [ "$ARCH" = "x64" ] || [ "$ARCH" = "arm64" ]; }; then
  if (ldd --version 2>&1 | grep -qi musl) || grep -qi musl /proc/self/maps 2>/dev/null; then
    LIBC_SUFFIX="-musl"
    echo ""
    echo "Note: Detected musl libc (Alpine Linux)."
    echo "      Flutter SDK requires glibc. You may need: apk add gcompat"
    echo ""
  fi
fi

# ---- resolve version ----
if [ -n "$REQUESTED_VERSION" ]; then
  VERSION="$(normalize_version "$REQUESTED_VERSION")"
else
  echo "Fetching latest FVM version..."
  VERSION="$(get_latest_version)" || { echo "error: failed to determine latest version" >&2; exit 1; }
fi

echo "Installing FVM ${VERSION} for ${OS}-${ARCH}${LIBC_SUFFIX}..."

# ---- construct asset URL and validate existence, with musl->glibc fallback ----
TARBALL="fvm-${VERSION}-${OS}-${ARCH}${LIBC_SUFFIX}.tar.gz"
URL="https://github.com/${REPO}/releases/download/${VERSION}/${TARBALL}"

if ! curl -fsSLI -o /dev/null "$URL"; then
  if [ -n "$LIBC_SUFFIX" ]; then
    ALT_URL="https://github.com/${REPO}/releases/download/${VERSION}/fvm-${VERSION}-${OS}-${ARCH}.tar.gz"
    if curl -fsSLI -o /dev/null "$ALT_URL"; then
      URL="$ALT_URL"
      TARBALL="fvm-${VERSION}-${OS}-${ARCH}.tar.gz"
      echo "Note: Using glibc variant (musl not available)"
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
mkdir -p "$BIN_DIR" "$TMP_DIR"
cleanup() { rm -rf "$TMP_DIR" 2>/dev/null || true; }
trap cleanup EXIT

# ---- download ----
ARCHIVE="${TMP_DIR}/${TARBALL}"
echo "Downloading ${URL##*/}..."
curl -fsSL "$URL" -o "$ARCHIVE"

# ---- validate archive ----
if ! tar -tzf "$ARCHIVE" >/dev/null 2>&1; then
  echo "error: downloaded archive appears corrupted" >&2
  exit 1
fi

# ---- extract ----
echo "Extracting..."
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
  echo "⚠ Installed, but running '${BIN_DIR}/fvm --version' failed."
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
