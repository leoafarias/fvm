#!/usr/bin/env bash
# =============================================================================
# FVM Installer
# =============================================================================
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
readonly INSTALLER_VERSION="2.0.0"

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

INSTALL_BASE="$(resolve_install_base)"
readonly INSTALL_BASE
readonly BIN_DIR="${INSTALL_BASE}/bin"

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
      echo "error: refusing to install outside HOME: $base" >&2
      echo "       Use a directory under $HOME (e.g. $HOME/fvm), or use a package manager for system-wide installs." >&2
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
  PROFILE                Override shell profile file for PATH instructions
                         Set to /dev/null to skip profile detection

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

    export PATH="$BIN_DIR:\$PATH"

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

  # CI environment: automatically configure PATH
  if is_ci; then
    echo "CI environment detected - configuring PATH automatically..."
    echo ""
    setup_ci_path "$BIN_DIR"
    echo ""
    echo "FVM is now available in this step and subsequent steps."
  else
    # Interactive: check if already configured, otherwise show instructions
    local shell_type
    local profile_file
    shell_type="$(detect_shell)"
    profile_file="$(get_profile_file "$shell_type")"

    if [ -n "$profile_file" ] && is_path_configured "$profile_file" "$BIN_DIR"; then
      echo "✓ FVM is already configured in $profile_file"
      echo ""
      echo "Restart your shell or run: source $profile_file"
    else
      echo "To use FVM, add it to your PATH:"
      echo ""
      echo "  # For bash (add to ~/.bashrc or ~/.bash_profile):"
      echo "  export PATH=\"$BIN_DIR:\$PATH\""
      echo ""
      echo "  # For zsh (add to ~/.zshrc or ~/.zprofile):"
      echo "  export PATH=\"$BIN_DIR:\$PATH\""
      echo ""
      echo "  # For fish (run once):"
      echo "  fish_add_path \"$BIN_DIR\""
      echo ""
      if [ -n "$profile_file" ]; then
        echo "Then restart your shell or run: source $profile_file"
      else
        echo "Then restart your shell to apply changes."
      fi
    fi
  fi

  echo ""
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

# ---- profile auto-detection ----

# Detect the user's shell (works on Linux, macOS, BSD)
detect_shell() {
  local shell_name=""

  # Primary: use ps command (portable across Linux, macOS, BSD)
  if command -v ps >/dev/null 2>&1; then
    shell_name="$(ps -p "$PPID" -o 'comm=' 2>/dev/null || true)"
    shell_name="${shell_name##-}"       # Remove leading dash (login shells)
    shell_name="${shell_name##*/}"      # Extract basename
  fi

  # Fallback: use $SHELL environment variable
  if [ -z "$shell_name" ] && [ -n "${SHELL:-}" ]; then
    shell_name="$(basename "$SHELL" 2>/dev/null)" || shell_name=""
  fi

  # Normalize shell names
  case "$shell_name" in
    bash*)  echo "bash" ;;
    zsh*)   echo "zsh" ;;
    fish*)  echo "fish" ;;
    *)      echo "unknown" ;;
  esac
}

# Get the appropriate profile file for a shell
# Supports PROFILE env var override (NVM-compatible)
get_profile_file() {
  local shell_type="$1"
  local profile_file=""

  # Allow explicit override via PROFILE environment variable
  if [ -n "${PROFILE:-}" ]; then
    if [ "${PROFILE}" = "/dev/null" ]; then
      # User explicitly wants to skip profile detection
      echo ""
      return
    fi
    if [ -f "${PROFILE}" ]; then
      echo "${PROFILE}"
      return
    fi
    # PROFILE set but file doesn't exist - warn and continue with auto-detection
    echo "Warning: PROFILE='${PROFILE}' not found, using auto-detection" >&2
  fi

  case "$shell_type" in
    bash)
      # Platform-aware priority (verified against NVM and Homebrew patterns):
      # - macOS Terminal.app opens login shells -> .bash_profile first
      # - Linux terminals typically open non-login interactive shells -> .bashrc first
      if [ "$(uname -s)" = "Darwin" ]; then
        # macOS: .bash_profile > .bash_login > .bashrc > .profile
        if [ -f "$HOME/.bash_profile" ]; then
          profile_file="$HOME/.bash_profile"
        elif [ -f "$HOME/.bash_login" ]; then
          profile_file="$HOME/.bash_login"
        elif [ -f "$HOME/.bashrc" ]; then
          profile_file="$HOME/.bashrc"
        elif [ -f "$HOME/.profile" ]; then
          profile_file="$HOME/.profile"
        else
          profile_file="$HOME/.bash_profile"
        fi
      else
        # Linux/BSD: .bashrc > .bash_profile > .profile
        # (most .bash_profile files source .bashrc anyway)
        if [ -f "$HOME/.bashrc" ]; then
          profile_file="$HOME/.bashrc"
        elif [ -f "$HOME/.bash_profile" ]; then
          profile_file="$HOME/.bash_profile"
        elif [ -f "$HOME/.profile" ]; then
          profile_file="$HOME/.profile"
        else
          profile_file="$HOME/.bashrc"
        fi
      fi
      ;;
    zsh)
      # Platform-aware priority (matches Homebrew):
      # - macOS: .zprofile (login shell)
      # - Linux: .zshrc (interactive shell)
      if [ "$(uname -s)" = "Darwin" ]; then
        if [ -f "$HOME/.zprofile" ]; then
          profile_file="$HOME/.zprofile"
        elif [ -f "$HOME/.zshrc" ]; then
          profile_file="$HOME/.zshrc"
        else
          profile_file="$HOME/.zprofile"
        fi
      else
        if [ -f "$HOME/.zshrc" ]; then
          profile_file="$HOME/.zshrc"
        elif [ -f "$HOME/.zprofile" ]; then
          profile_file="$HOME/.zprofile"
        else
          profile_file="$HOME/.zshrc"
        fi
      fi
      ;;
    fish)
      # Respect XDG_CONFIG_HOME for fish configuration
      local fish_config_dir="${XDG_CONFIG_HOME:-$HOME/.config}"
      profile_file="$fish_config_dir/fish/config.fish"
      ;;
    *)
      # Unknown shell - try common profile files in order (NVM pattern)
      for profile in ".profile" ".bashrc" ".bash_profile" ".zprofile" ".zshrc"; do
        if [ -f "$HOME/$profile" ]; then
          profile_file="$HOME/$profile"
          break
        fi
      done
      ;;
  esac

  echo "$profile_file"
}

# Check if FVM is already in PATH configuration
is_path_configured() {
  local profile_file="$1"
  local bin_dir="$2"

  if [ ! -f "$profile_file" ]; then
    return 1
  fi

  # Use -F for fixed string matching (prevents regex injection)
  # Check for FVM bin directory in profile (skip comment lines)
  # Note: Use [[:space:]] instead of \s for POSIX portability (BSD/macOS grep)
  if grep -v '^[[:space:]]*#' "$profile_file" 2>/dev/null | grep -qF "$bin_dir"; then
    return 0
  fi

  # Also check for ~/fvm/bin or $HOME/fvm/bin patterns (unexpanded)
  if grep -v '^[[:space:]]*#' "$profile_file" 2>/dev/null | grep -qE '(\$HOME|~)/fvm/bin'; then
    return 0
  fi

  return 1
}

# Setup CI environment PATH automatically
setup_ci_path() {
  local bin_dir="$1"
  local ci_setup_done=0

  # GitHub Actions - write to GITHUB_PATH for subsequent steps
  if [ -n "${GITHUB_PATH:-}" ]; then
    if echo "$bin_dir" >> "$GITHUB_PATH" 2>/dev/null; then
      echo "✓ Added to GITHUB_PATH (available in subsequent steps)" >&2
      ci_setup_done=1
    else
      echo "⚠ Failed to write to GITHUB_PATH" >&2
    fi
  fi

  # CircleCI / Generic BASH_ENV - sourced at start of every step
  if [ -n "${BASH_ENV:-}" ] && [ -w "$BASH_ENV" ]; then
    if echo "export PATH=\"$bin_dir:\$PATH\"" >> "$BASH_ENV" 2>/dev/null; then
      echo "✓ Added to BASH_ENV (available in subsequent steps)" >&2
      ci_setup_done=1
    fi
  fi

  # Azure DevOps - logging command modifies PATH for subsequent tasks
  if [ -n "${TF_BUILD:-}" ]; then
    echo "##vso[task.prependpath]$bin_dir"
    echo "✓ Added via Azure DevOps logging command" >&2
    ci_setup_done=1
  fi

  # GitLab CI - export PATH works within the same job's script section
  # No special setup needed; the export below handles it

  # Always export for current shell/step
  export PATH="$bin_dir:$PATH"

  if [ "$ci_setup_done" -eq 1 ]; then
    echo "✓ Configured PATH for CI environment" >&2
  else
    echo "✓ Exported PATH for current step" >&2
  fi

  return 0
}

migrate_from_v1() {
  local migrated=0

  # 1. Remove old system symlink (v1 or v2 --system) only if it points to FVM
  if [ -L "$OLD_SYSTEM_PATH" ]; then
    local symlink_target
    symlink_target="$(readlink "$OLD_SYSTEM_PATH" 2>/dev/null || true)"

    # Only remove if symlink points to a known FVM location
    case "$symlink_target" in
      *fvm_flutter/bin/fvm|*fvm/bin/fvm)
        echo "" >&2
        echo "Detected old system symlink at $OLD_SYSTEM_PATH -> $symlink_target" >&2

        # Try to remove without sudo first (|| true prevents set -e exit)
        rm -f "$OLD_SYSTEM_PATH" 2>/dev/null || true
        if [ ! -e "$OLD_SYSTEM_PATH" ] && [ ! -L "$OLD_SYSTEM_PATH" ]; then
          echo "✓ Removed old system symlink" >&2
          migrated=1
        else
          # Try with sudo if available
          if command -v sudo >/dev/null 2>&1; then
            sudo rm -f "$OLD_SYSTEM_PATH" 2>/dev/null || true
            if [ ! -e "$OLD_SYSTEM_PATH" ] && [ ! -L "$OLD_SYSTEM_PATH" ]; then
              echo "✓ Removed old system symlink (required sudo)" >&2
              migrated=1
            else
              echo "⚠ Could not remove $OLD_SYSTEM_PATH" >&2
              echo "  You may remove it manually: sudo rm $OLD_SYSTEM_PATH" >&2
            fi
          else
            echo "⚠ Could not remove $OLD_SYSTEM_PATH (need sudo)" >&2
            echo "  You may remove it manually: sudo rm $OLD_SYSTEM_PATH" >&2
          fi
        fi
        ;;
      *)
        echo "" >&2
        echo "⚠ Found symlink at $OLD_SYSTEM_PATH pointing to: $symlink_target" >&2
        echo "  Not removing (does not appear to be an FVM installation)" >&2
        ;;
    esac
  elif [ -e "$OLD_SYSTEM_PATH" ]; then
    echo "" >&2
    echo "⚠ Detected existing non-symlink file at $OLD_SYSTEM_PATH" >&2
    echo "  Not removing automatically. Remove it manually if it is an old FVM binary." >&2
  fi

  # 2. Backup old user directory (~/.fvm_flutter) instead of deleting
  if [ -d "$OLD_USER_PATH" ]; then
    echo "" >&2
    echo "Detected old installation at $OLD_USER_PATH" >&2

    local backup_path="${OLD_USER_PATH}.bak.$(date +%Y%m%d%H%M%S)"
    if mv "$OLD_USER_PATH" "$backup_path" 2>/dev/null; then
      echo "✓ Backed up old directory to: $backup_path" >&2
      migrated=1
    else
      # Fallback: try to remove if move fails (e.g., cross-device move)
      rm -rf "$OLD_USER_PATH" 2>/dev/null || true
      if [ ! -d "$OLD_USER_PATH" ]; then
        echo "✓ Removed old user directory (backup failed)" >&2
        migrated=1
      else
        echo "⚠ Could not move or remove $OLD_USER_PATH" >&2
        echo "  You may remove it manually: rm -rf $OLD_USER_PATH" >&2
      fi
    fi
  fi

  # 3. Print PATH update notice if migrated
  if [ "$migrated" -eq 1 ]; then
    echo "" >&2
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >&2
    echo "⚠ ACTION REQUIRED: Update your shell PATH" >&2
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >&2
    echo "" >&2
    echo "  Old: export PATH=\"\$HOME/.fvm_flutter/bin:\$PATH\"" >&2
    echo "  New: export PATH=\"$BIN_DIR:\$PATH\"" >&2
    echo "" >&2
    echo "Your cached Flutter SDKs in $INSTALL_BASE/versions/ are preserved." >&2
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >&2
  fi
}

do_uninstall() {
  local removed_any=0

  echo "Uninstalling FVM..." >&2
  echo "" >&2

  validate_install_base "$INSTALL_BASE"

  # 1. Remove the install bin directory only (NOT entire install base - preserve cached SDKs)
  # Note: This removes the entire $BIN_DIR directory.
  if [ -d "$BIN_DIR" ]; then
    rm -rf "$BIN_DIR" 2>/dev/null || true
    if [ ! -d "$BIN_DIR" ]; then
      echo "✓ Removed binary directory: $BIN_DIR" >&2
      removed_any=1
    else
      echo "⚠ Could not remove $BIN_DIR (check permissions)" >&2
    fi
  fi

  # 2. Remove old user directory (~/.fvm_flutter) - safe to nuke entirely
  if [ -d "$OLD_USER_PATH" ]; then
    rm -rf "$OLD_USER_PATH" 2>/dev/null || true
    if [ ! -d "$OLD_USER_PATH" ]; then
      echo "✓ Removed old directory: $OLD_USER_PATH" >&2
      removed_any=1
    else
      echo "⚠ Could not remove $OLD_USER_PATH" >&2
    fi
  fi

  # 3. Remove old system symlink (from v1/v2)
  if [ -L "$OLD_SYSTEM_PATH" ]; then
    rm -f "$OLD_SYSTEM_PATH" 2>/dev/null || true
    if [ ! -e "$OLD_SYSTEM_PATH" ]; then
      echo "✓ Removed old system symlink: $OLD_SYSTEM_PATH" >&2
      removed_any=1
    else
      if command -v sudo >/dev/null 2>&1; then
        sudo rm -f "$OLD_SYSTEM_PATH" 2>/dev/null || true
        if [ ! -e "$OLD_SYSTEM_PATH" ]; then
          echo "✓ Removed old system symlink: $OLD_SYSTEM_PATH" >&2
          removed_any=1
        else
          echo "⚠ Could not remove $OLD_SYSTEM_PATH (may need sudo)" >&2
        fi
      else
        echo "⚠ Could not remove $OLD_SYSTEM_PATH (may need sudo)" >&2
      fi
    fi
  elif [ -e "$OLD_SYSTEM_PATH" ]; then
    echo "⚠ Found existing non-symlink file at $OLD_SYSTEM_PATH; not removing automatically." >&2
  fi

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
  echo "Remove PATH entries from your shell config:" >&2
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

validate_install_base "$INSTALL_BASE"

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
TMP_DIR=""  # Initialize for set -u (nounset)
cleanup() { if [ -n "$TMP_DIR" ]; then rm -rf "$TMP_DIR" 2>/dev/null || true; fi; }
trap cleanup EXIT

TMP_DIR="$(mktemp -d 2>/dev/null || mktemp -d -t 'fvm_install')" || {
  echo "error: failed to create temp directory" >&2
  exit 1
}
mkdir -p "$BIN_DIR"

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
if tar -tzf "$ARCHIVE" | grep -qE '^/|^\.\.$|^\.\./|/\.\.$|/\.\./'; then
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

# ---- migrate from v1/v2 ----
migrate_from_v1

# ---- verify and report ----
echo ""
echo "Installed to: ${BIN_DIR}/fvm"

if "${BIN_DIR}/fvm" --version >/dev/null 2>&1; then
  echo "FVM version: ${VERSION}"
  print_path_instructions
else
  echo ""
  echo "⚠ Binary installed but cannot execute (missing libraries)."
  echo "  On Alpine Linux: apk add gcompat"
  echo "  Then verify: ${BIN_DIR}/fvm --version"
  echo ""
  echo "  PATH: export PATH=\"$BIN_DIR:\$PATH\""
fi
