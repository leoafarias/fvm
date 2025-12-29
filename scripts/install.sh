#!/usr/bin/env bash
# =============================================================================
# FVM Installer
# =============================================================================
# v2.1.0 (2025-12)
#   - Auto-add FVM to PATH in shell config (bash/zsh/fish)
#   - Support ZDOTDIR (zsh) and XDG_CONFIG_HOME (fish)
#   - Preserve symlinked dotfiles, detect musl on all Linux archs
#   - Old v1 installations: warning-only (no auto-deletion)
#
# v2.0.0 (2025-12)
#   - Install to ~/fvm/bin (no sudo required)
#   - FVM_INSTALL_DIR for custom location
#   - Auto-migrate from v1 (~/.fvm_flutter)
#
# v1.1.0
#   - Install to ~/.fvm_flutter/bin with /usr/local/bin symlink
#   - Auto-modify shell config
# =============================================================================
set -euo pipefail
umask 022

# ---- installer metadata ----
readonly INSTALLER_NAME="install_fvm.sh"
readonly INSTALLER_VERSION="2.1.0"

# ---- config ----
readonly REPO="leoafarias/fvm"
readonly OLD_SYSTEM_PATH="/usr/local/bin/fvm"
readonly OLD_USER_PATH="${HOME}/.fvm_flutter"

UNINSTALL_ONLY=0
REQUESTED_VERSION=""

# ---- helpers ----
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

validate_install_base() {
  local base="$1"

  # Reject empty, root, or non-absolute paths
  if [ -z "$base" ] || [ "$base" = "/" ]; then
    echo "error: invalid install base: '${base:-<empty>}'" >&2
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

  # Must be under HOME (not equal to HOME)
  if [ "$base" = "$HOME" ]; then
    echo "error: refusing to use HOME as install base. Use a subdirectory like \$HOME/fvm." >&2
    exit 1
  fi

  case "$base" in
    "$HOME"/*) ;;
    *)
      echo "error: install path must be under HOME: $base" >&2
      echo "       Use a directory under $HOME (e.g. $HOME/fvm), or use a package manager for system-wide installs." >&2
      exit 1
      ;;
  esac

  # Reject system bin directories
  case "${base}/bin" in
    /bin|/usr/bin|/usr/local/bin|/sbin|/usr/sbin)
      echo "error: refusing to use unsafe bin directory: ${base}/bin" >&2
      exit 1
      ;;
  esac
}

# These will be set after arg parsing (so --help/--version work without validation)
INSTALL_BASE=""
BIN_DIR=""

usage() {
  cat <<EOF
FVM Installer v${INSTALLER_VERSION} - User-Local Installation

USAGE:
  install.sh [FLAGS] [VERSION]

ARGUMENTS:
  VERSION               Version to install (e.g., 4.0.1 or v4.0.1)
                        If omitted, installs the latest version

ENVIRONMENT:
  FVM_INSTALL_DIR        Install base directory (default: \$HOME/fvm)
  FVM_NO_PROFILE=1       Skip auto-modifying shell config
  FVM_PROFILE=/path      Override detected shell profile path
  PROFILE=/dev/null      Alternative way to skip profile modification (nvm-style)

FLAGS:
  -h, --help            Show this help and exit
  -v, --version         Show installer version and exit
  -u, --uninstall       Remove FVM installation

EXAMPLES:
  # Install latest version
  curl -fsSL https://fvm.app/install.sh | bash

  # Install specific version
  ./install.sh 4.0.1

  # Uninstall
  ./install.sh --uninstall

AFTER INSTALLATION:
  Add FVM to your PATH by adding this line to your shell config:

    export PATH="\$HOME/fvm/bin:\$PATH"

  Then restart your shell or run: source ~/.bashrc

FOR MORE INFO:
  https://fvm.app/docs/getting_started/installation
EOF
}

print_installer_version() {
  printf '%s version %s\n' "$INSTALLER_NAME" "$INSTALLER_VERSION"
}

require() { command -v "$1" >/dev/null 2>&1 || { echo "error: $1 is required" >&2; exit 1; }; }

curl_supports() {
  local flag="$1"
  curl --help all 2>/dev/null | grep -q -- "$flag"
}

CURL_FLAGS=()

init_curl_flags() {
  # Use an array to preserve argument boundaries.
  CURL_FLAGS=(
    -fsSL
    --connect-timeout 10
    --max-time 300
  )

  if curl_supports "--proto"; then
    CURL_FLAGS+=( --proto "=https" --tlsv1.2 )
  fi
}

normalize_version() { printf '%s\n' "${1#v}"; }

get_latest_version() {
  # Follows redirect from /releases/latest -> .../tag/vX.Y.Z
  local url
  url="$(curl "${CURL_FLAGS[@]}" -o /dev/null -w '%{url_effective}' "https://github.com/${REPO}/releases/latest")" || return 1
  normalize_version "${url##*/}"
}

print_path_instructions() {
  local profile_updated="${1:-false}"

  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "✓ Installation complete!"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""

  if [ "$profile_updated" = "true" ]; then
    echo "FVM has been added to your PATH. To use it now, either:"
    echo "  • Restart your terminal, or"
    echo "  • Run: source ~/.bashrc  # (or ~/.zshrc)"
    echo ""
    if ! is_ci; then
      echo "If you ran this via curl | bash, also run in this shell:"
      echo "  export PATH=\"$BIN_DIR:\$PATH\""
      echo ""
    fi
  else
    echo "To use FVM, add it to your PATH:"
    echo ""
    echo "  # For bash (add to ~/.bashrc):"
    echo "  export PATH=\"$BIN_DIR:\$PATH\""
    echo ""
    echo "  # For zsh (add to ~/.zshrc):"
    echo "  export PATH=\"$BIN_DIR:\$PATH\""
    echo ""
    echo "  # For fish (run once):"
    echo "  fish_add_path \"$BIN_DIR\""
    echo ""
    echo "Then restart your shell or run:"
    echo "  source ~/.bashrc  # or ~/.zshrc"
    echo ""
    if is_ci; then
      echo "CI detected."
      echo "To use FVM in this same step, run:"
      echo "  export PATH=\"$BIN_DIR:\$PATH\""
      echo "To persist for later steps, use your CI's env file mechanism"
      echo "  (e.g., \$GITHUB_PATH on GitHub Actions, \$BASH_ENV on CircleCI)."
      echo ""
    else
      echo "Note: If you ran this via curl | bash, run the export command"
      echo "above in your current shell."
      echo ""
    fi
  fi
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

is_ci() {
  if [ -n "${CI:-}" ] && [ "${CI}" != "false" ]; then
    return 0
  fi
  [ -n "${GITHUB_ACTIONS:-}" ] || [ -n "${GITLAB_CI:-}" ] || [ -n "${CIRCLECI:-}" ] || \
  [ -n "${TRAVIS:-}" ] || [ -n "${BUILDKITE:-}" ] || [ -n "${DRONE:-}" ] || \
  [ -n "${TF_BUILD:-}" ] || [ -n "${TEAMCITY_VERSION:-}" ] || \
  [ -n "${JENKINS_URL:-}" ] || [ -n "${APPVEYOR:-}" ]
}

# ---- optional profile / PATH modification ----
# Opt-out options:
#   - PROFILE=/dev/null        (nvm-style)
#   - FVM_NO_PROFILE=1|true
# Optional override:
#   - FVM_PROFILE=/path/to/file

fvm_should_modify_profile() {
  # Don't modify profiles in CI by default
  if is_ci; then
    return 1
  fi

  # Respect opt-outs
  case "${PROFILE:-}" in /dev/null) return 1 ;; esac
  case "${FVM_PROFILE:-}" in /dev/null) return 1 ;; esac
  case "${FVM_NO_PROFILE:-}" in 1|true|TRUE|yes|YES) return 1 ;; esac

  # Avoid modifying root's dotfiles automatically
  if [ "${EUID:-$(id -u)}" -eq 0 ]; then
    return 1
  fi

  return 0
}

fvm_detect_profile() {
  # Explicit override first
  if [ -n "${FVM_PROFILE:-}" ] && [ "${FVM_PROFILE}" != "/dev/null" ]; then
    printf '%s\n' "${FVM_PROFILE}"
    return 0
  fi
  if [ -n "${PROFILE:-}" ] && [ "${PROFILE}" != "/dev/null" ]; then
    printf '%s\n' "${PROFILE}"
    return 0
  fi

  # Detect by login shell (what you actually want to configure)
  local shell_name
  shell_name="$(basename "${SHELL:-}")"

  case "$shell_name" in
    fish)
      # Respect XDG_CONFIG_HOME if set (XDG Base Directory spec)
      printf '%s\n' "${XDG_CONFIG_HOME:-$HOME/.config}/fish/config.fish"
      return 0
      ;;
    zsh)
      # Respect ZDOTDIR if set (zsh standard)
      local zsh_home="${ZDOTDIR:-$HOME}"
      if [ -f "$zsh_home/.zshrc" ]; then
        printf '%s\n' "$zsh_home/.zshrc"
      elif [ -f "$zsh_home/.zprofile" ]; then
        printf '%s\n' "$zsh_home/.zprofile"
      else
        # create .zshrc if nothing exists
        printf '%s\n' "$zsh_home/.zshrc"
      fi
      return 0
      ;;
    bash)
      if [ -f "$HOME/.bashrc" ]; then
        printf '%s\n' "$HOME/.bashrc"
      elif [ -f "$HOME/.bash_profile" ]; then
        printf '%s\n' "$HOME/.bash_profile"
      else
        # create ~/.bashrc if nothing exists
        printf '%s\n' "$HOME/.bashrc"
      fi
      return 0
      ;;
  esac

  # Fallback for unknown shells
  printf '%s\n' "$HOME/.profile"
}

fvm_remove_managed_block() {
  local file="$1"
  local begin="# >>> fvm >>>"
  local end="# <<< fvm <<<"

  [ -f "$file" ] || return 0
  grep -Fqs "$begin" "$file" || return 0
  grep -Fqs "$end" "$file" || return 0

  # Use awk to remove the managed block
  # Write to temp, then use cat redirection to preserve symlinks
  local tmp="${file}.tmp.$$"
  awk -v begin="$begin" -v end="$end" '
    $0==begin {skip=1; next}
    $0==end {skip=0; next}
    !skip {print}
  ' "$file" > "$tmp" || { rm -f "$tmp"; return 1; }
  cat "$tmp" > "$file" && rm -f "$tmp"
}

fvm_maybe_add_to_path() {
  fvm_should_modify_profile || return 0

  local profile
  profile="$(fvm_detect_profile)"

  # Ensure parent directory exists (fish config path needs dirs)
  mkdir -p "$(dirname "$profile")" 2>/dev/null || true

  # Test actual append capability (not just touch)
  if ! : >> "$profile" 2>/dev/null; then
    echo "Note: Could not write to $profile" >&2
    echo "Add PATH manually: export PATH=\"$BIN_DIR:\$PATH\"" >&2
    return 0
  fi

  # If user already added BIN_DIR manually (anywhere), do nothing
  if grep -Fqs "$BIN_DIR" "$profile"; then
    return 0
  fi

  # Replace previous managed block (handles changing install dir cleanly)
  fvm_remove_managed_block "$profile"

  local begin="# >>> fvm >>>"
  local end="# <<< fvm <<<"
  local shell_name
  shell_name="$(basename "${SHELL:-}")"
  local append_success=false

  if [ "$shell_name" = "fish" ] || [ "$(basename "$profile")" = "config.fish" ]; then
    # fish_add_path already handles duplicates
    if cat >> "$profile" <<EOF

$begin
# Add FVM to PATH
if type -q fish_add_path
  fish_add_path "$BIN_DIR"
else
  set -gx PATH "$BIN_DIR" \$PATH
end
$end
EOF
    then
      append_success=true
    fi
  else
    # Use case pattern to avoid duplicates when sourced multiple times (rustup-style)
    if cat >> "$profile" <<EOF

$begin
# Add FVM to PATH (only if not already present)
case ":\${PATH}:" in
  *:"$BIN_DIR":*)
    ;;
  *)
    export PATH="$BIN_DIR:\$PATH"
    ;;
esac
$end
EOF
    then
      append_success=true
    fi
  fi

  if [ "$append_success" = "true" ]; then
    echo "✓ Added FVM to PATH in: $profile" >&2
    FVM_PROFILE_UPDATED="true"
  else
    echo "Warning: Failed to update $profile" >&2
    echo "Add PATH manually: export PATH=\"$BIN_DIR:\$PATH\"" >&2
  fi
}

fvm_remove_from_profile() {
  local profile
  profile="$(fvm_detect_profile)"

  if [ -f "$profile" ]; then
    if grep -Fqs "# >>> fvm >>>" "$profile"; then
      fvm_remove_managed_block "$profile"
      echo "✓ Removed FVM PATH entry from: $profile" >&2
    fi
  fi
}

# Check for old FVM v1 installation and print warnings (no auto-deletion)
check_old_installation() {
  local found=0

  if [ -L "$OLD_SYSTEM_PATH" ] || [ -e "$OLD_SYSTEM_PATH" ]; then
    echo "" >&2
    echo "Note: Old FVM found at $OLD_SYSTEM_PATH" >&2
    echo "  Remove with: sudo rm $OLD_SYSTEM_PATH" >&2
    found=1
  fi

  if [ -d "$OLD_USER_PATH" ]; then
    echo "" >&2
    echo "Note: Old FVM directory found at $OLD_USER_PATH" >&2
    echo "  Remove with: rm -rf $OLD_USER_PATH" >&2
    found=1
  fi

  if [ "$found" -eq 1 ]; then
    echo "" >&2
    echo "These old paths may cause PATH conflicts." >&2
  fi
}

do_uninstall() {
  local removed_any=0

  echo "Uninstalling FVM..." >&2
  echo "" >&2

  # 1. Remove only the FVM binary (not entire directory - preserves shared bin dirs)
  if [ -f "${BIN_DIR}/fvm" ]; then
    rm -f "${BIN_DIR}/fvm" 2>/dev/null || true
    if [ ! -f "${BIN_DIR}/fvm" ]; then
      echo "✓ Removed: ${BIN_DIR}/fvm" >&2
      removed_any=1
    else
      echo "⚠ Could not remove ${BIN_DIR}/fvm (check permissions)" >&2
    fi
  fi

  # Try to remove bin directory only if empty (safe for shared directories)
  if [ -d "$BIN_DIR" ]; then
    rmdir "$BIN_DIR" 2>/dev/null && echo "✓ Removed empty directory: $BIN_DIR" >&2 || true
  fi

  # 2. Remove FVM PATH entry from shell profile (if we added it)
  fvm_remove_from_profile || true

  # 3. Print warnings about old installations (no auto-deletion)
  check_old_installation

  if [ "$removed_any" -eq 0 ]; then
    echo "No FVM installation found (ok)" >&2
  fi

  echo "" >&2
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >&2
  echo "Uninstall complete." >&2
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >&2
  echo "" >&2
  echo "Note: Cached Flutter SDKs remain in $INSTALL_BASE/versions/" >&2
  echo "      To remove them: rm -rf $INSTALL_BASE/" >&2
  echo "" >&2
  echo "If you added FVM to your PATH manually, remove entries from:" >&2
  echo "  - ~/.bashrc" >&2
  echo "  - ~/.zshrc" >&2
  echo "  - ~/.config/fish/config.fish" >&2
  echo "" >&2
  echo "Look for lines containing: $BIN_DIR" >&2

  exit 0
}

# ---- arg parsing ----
for arg in "$@"; do
  case "$arg" in
    -h|--help) usage; exit 0 ;;
    -v|--version) print_installer_version; exit 0 ;;
    -u|--uninstall) UNINSTALL_ONLY=1 ;;
    -*)
      echo "error: unknown option: $arg" >&2
      echo ""
      usage
      exit 1
      ;;
    *)
      if [ -n "$REQUESTED_VERSION" ]; then
        echo "error: multiple versions specified" >&2
        exit 1
      fi
      REQUESTED_VERSION="$arg"
      ;;
  esac
done

if [ -n "$REQUESTED_VERSION" ]; then
  if ! [[ "$REQUESTED_VERSION" =~ ^v?[0-9]+\.[0-9]+\.[0-9]+([.-][0-9A-Za-z._-]+)?$ ]]; then
    echo "error: invalid version format: $REQUESTED_VERSION (expected X.Y.Z or vX.Y.Z)" >&2
    exit 1
  fi
fi

# ---- initialize install paths ----
INSTALL_BASE="$(resolve_install_base)"
readonly INSTALL_BASE
BIN_DIR="${INSTALL_BASE}/bin"
readonly BIN_DIR

# Validate paths before any operations
validate_install_base "$INSTALL_BASE"

# Create bin directory (needed for install)
if [ "$UNINSTALL_ONLY" -ne 1 ]; then
  mkdir -p "$BIN_DIR" || {
    echo "error: cannot create directory: $BIN_DIR" >&2
    exit 1
  }
fi

# ---- handle uninstall ----
if [ "$UNINSTALL_ONLY" -eq 1 ]; then
  do_uninstall
fi

# ---- root user handling ----
if [ "${EUID:-$(id -u)}" -eq 0 ]; then
  echo "⚠ Warning: Running as root" >&2
  echo "  FVM will be installed to $BIN_DIR and likely won't be accessible to other users." >&2
  echo "  It is recommended that each user install FVM individually in their own home directory." >&2
  echo "" >&2
fi

# ---- prereqs ----
require curl
require tar
[ -n "${BASH_VERSION:-}" ] || { echo "error: bash is required to run this installer" >&2; exit 1; }
init_curl_flags

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

# ---- detect libc (Linux only, all architectures) ----
LIBC_SUFFIX=""
if [ "$OS" = "linux" ]; then
  # Detect glibc positively via getconf; otherwise check for musl
  if command -v getconf >/dev/null 2>&1 && getconf GNU_LIBC_VERSION >/dev/null 2>&1; then
    : # glibc detected
  elif command -v ldd >/dev/null 2>&1 && ldd --version 2>&1 | grep -qi musl; then
    LIBC_SUFFIX="-musl"
    echo "" >&2
    echo "Note: Detected musl libc (Alpine Linux)." >&2
    echo "      Flutter SDK requires glibc. You may need: apk add gcompat" >&2
    echo "" >&2
  elif ls /lib/ld-musl-*.so.1 >/dev/null 2>&1 || ls /usr/lib/ld-musl-*.so.1 >/dev/null 2>&1; then
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

# ---- construct asset URL (musl -> glibc fallback happens during download) ----
TARBALL="fvm-${VERSION}-${OS}-${ARCH}${LIBC_SUFFIX}.tar.gz"
URL="https://github.com/${REPO}/releases/download/${VERSION}/${TARBALL}"

# ---- prep dirs and cleanup trap ----
TMP_DIR=""  # Initialize for set -u (nounset)
cleanup() { if [ -n "$TMP_DIR" ]; then rm -rf "$TMP_DIR" 2>/dev/null || true; fi; }
trap cleanup EXIT

TMP_DIR="$(mktemp -d 2>/dev/null || mktemp -d -t 'fvm_install')" || {
  echo "error: failed to create temp directory" >&2
  exit 1
}

# ---- download ----
download_archive() {
  local url="$1"
  local dest="$2"
  curl "${CURL_FLAGS[@]}" "$url" -o "$dest"
}

ARCHIVE="${TMP_DIR}/${TARBALL}"
echo "Downloading ${URL##*/}..." >&2
if ! download_archive "$URL" "$ARCHIVE"; then
  if [ -n "$LIBC_SUFFIX" ]; then
    rm -f "$ARCHIVE"
    ALT_TARBALL="fvm-${VERSION}-${OS}-${ARCH}.tar.gz"
    ALT_URL="https://github.com/${REPO}/releases/download/${VERSION}/${ALT_TARBALL}"
    ALT_ARCHIVE="${TMP_DIR}/${ALT_TARBALL}"
    echo "Note: musl asset not available, trying glibc variant..." >&2
    if download_archive "$ALT_URL" "$ALT_ARCHIVE"; then
      URL="$ALT_URL"
      TARBALL="$ALT_TARBALL"
      ARCHIVE="$ALT_ARCHIVE"
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

# ---- validate archive ----
if ! tar -tzf "$ARCHIVE" >/dev/null 2>&1; then
  echo "error: downloaded archive appears corrupted" >&2
  exit 1
fi

# ---- validate no path traversal ----
if tar -tzf "$ARCHIVE" | grep -qE '^/|^\.\.$|^\.\./|/\.\.$|/\.\./'; then
  echo "error: archive contains unsafe paths (absolute or traversal)" >&2
  exit 1
fi

# ---- extract ----
echo "Extracting..." >&2
tar -xzf "$ARCHIVE" -C "$TMP_DIR"

# ---- validate extracted contents (no symlinks or hardlinks) ----
if find "$TMP_DIR" -type l 2>/dev/null | grep -q .; then
  echo "error: archive contains symlinks (refusing to install)" >&2
  exit 1
fi
if find "$TMP_DIR" -type f -links +1 2>/dev/null | grep -q .; then
  echo "error: archive contains hardlinks (refusing to install)" >&2
  exit 1
fi

# ---- locate binary and copy contents per tarball structure ----
SOURCE_BIN=""
if [ -d "${TMP_DIR}/fvm" ] && [ -f "${TMP_DIR}/fvm/fvm" ]; then
  cp -a "${TMP_DIR}/fvm/." "$BIN_DIR/"
  SOURCE_BIN="${TMP_DIR}/fvm/fvm"
elif [ -f "${TMP_DIR}/fvm" ]; then
  SOURCE_BIN="${TMP_DIR}/fvm"
else
  FOUND="$(find "$TMP_DIR" -type f -name 'fvm' 2>/dev/null | head -n1 || true)"
  [ -n "$FOUND" ] || { echo "error: fvm binary not found in archive" >&2; exit 1; }
  SOURCE_BIN="$FOUND"
fi

# Atomic install of the binary to avoid partial writes
TMP_BIN="${BIN_DIR}/fvm.new"
cp -a "$SOURCE_BIN" "$TMP_BIN"
chmod +x "$TMP_BIN"
mv -f "$TMP_BIN" "${BIN_DIR}/fvm"

# ---- check for old installations (warning only) ----
check_old_installation

# ---- verify and report ----
echo ""
echo "Installed to: ${BIN_DIR}/fvm"

if "${BIN_DIR}/fvm" --version >/dev/null 2>&1; then
  echo "FVM version: ${VERSION}"

  # Attempt to auto-add to PATH in shell config
  FVM_PROFILE_UPDATED="false"
  fvm_maybe_add_to_path || true

  print_path_instructions "$FVM_PROFILE_UPDATED"
else
  echo ""
  echo "⚠ Binary installed but cannot execute (missing libraries)."
  echo "  On Alpine Linux: apk add gcompat"
  echo "  Then verify: ${BIN_DIR}/fvm --version"
  echo ""
  echo "  PATH: export PATH=\"$BIN_DIR:\$PATH\""
fi
