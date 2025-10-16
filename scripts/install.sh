#!/usr/bin/env bash
# FVM Installer - Install Flutter Version Management
#
# Usage:
#   curl -fsSL https://fvm.app/install.sh | bash
#   curl -fsSL https://fvm.app/install.sh | bash -s 3.2.1
#   ./install.sh [VERSION]
#
# Environment:
#   FVM_DIR             Custom installation directory (default: $HOME/.fvm_flutter)
#   FVM_ALLOW_ROOT      Set to 'true' to allow root installation (containers/CI)
#   FVM_NO_PATH         Set to 'true' to skip automatic PATH configuration

set -euo pipefail

SCRIPT_VERSION="3.0.0"

# Installation paths
FVM_DIR="${FVM_DIR:-$HOME/.fvm_flutter}"
FVM_DIR_BIN="$FVM_DIR/bin"

# Colors for output (only in terminal)
Color_Off=''
Red=''
Green=''
Yellow=''
Bold_White=''

if [[ -t 1 ]] && [[ "${TERM:-}" != "dumb" ]] && [[ -z "${NO_COLOR:-}" ]]; then
  Color_Off='\033[0m'
  Red='\033[0;31m'
  Green='\033[0;32m'
  Yellow='\033[1;33m'
  Bold_White='\033[1m'
fi

# Logging functions
log() { printf "%b\n" "$1"; }
info() { log "${Bold_White}$1${Color_Off}"; }
success() { log "${Green}$1${Color_Off}"; }
warn() { log "${Yellow}$1${Color_Off}"; }
error() { log "${Red}error: $1${Color_Off}" >&2; exit 1; }

# Temp file tracking for cleanup
TEMP_FILES=()
cleanup() {
  for temp_file in "${TEMP_FILES[@]}"; do
    if [[ -e "$temp_file" ]]; then
      rm -rf "$temp_file" 2>/dev/null || true
    fi
  done
}
trap cleanup EXIT INT TERM

# Check if running in container/CI environment
is_container_env() {
  [[ -f /.dockerenv ]] || [[ -f /.containerenv ]] || [[ -n "${CI:-}" ]]
}

# Show help
show_help() {
  cat << EOF
FVM Installer v${SCRIPT_VERSION}

Install Flutter Version Management (FVM) on Linux/macOS

USAGE:
    curl -fsSL https://fvm.app/install.sh | bash
    curl -fsSL https://fvm.app/install.sh | bash -s [VERSION]
    ./install.sh [VERSION]

OPTIONS:
    -h, --help       Show this help message
    -v, --version    Show script version

ARGUMENTS:
    VERSION         Specific FVM version to install (e.g., 3.2.1)
                    If omitted, installs the latest version

ENVIRONMENT:
    FVM_DIR          Installation directory (default: ~/.fvm_flutter)
    FVM_ALLOW_ROOT   Set to 'true' to allow root installation (containers/CI)
    FVM_NO_PATH      Set to 'true' to skip automatic PATH configuration

EXAMPLES:
    # Install latest version
    curl -fsSL https://fvm.app/install.sh | bash

    # Install specific version
    curl -fsSL https://fvm.app/install.sh | bash -s 3.2.1

    # Custom installation directory
    FVM_DIR=/opt/fvm ./install.sh

    # Skip PATH configuration
    FVM_NO_PATH=true ./install.sh

EOF
  exit 0
}

# Parse command line arguments
FVM_VERSION=""

while [[ $# -gt 0 ]]; do
  case $1 in
    -h|--help)
      show_help
      ;;
    -v|--version)
      echo "FVM Installer v${SCRIPT_VERSION}"
      exit 0
      ;;
    -*)
      error "Unknown option: $1. Use --help for usage."
      ;;
    *)
      # Strip leading 'v' if provided (e.g., v3.2.1 -> 3.2.1)
      FVM_VERSION="${1#v}"
      ;;
  esac
  shift
done

# Detect OS and architecture
OS="$(uname -s)"
ARCH="$(uname -m)"

case "$OS" in
  Linux*) OS='linux' ;;
  Darwin*) OS='macos' ;;
  *) error "Unsupported OS: $OS" ;;
esac

case "$ARCH" in
  x86_64) ARCH='x64' ;;
  arm64|aarch64) ARCH='arm64' ;;
  *) error "Unsupported architecture: $ARCH. Only x64 and arm64 are supported." ;;
esac

# Detect Rosetta on macOS (avoid downloading wrong binary)
if [[ "$OS" == "macos" ]] && sysctl -n sysctl.proc_translated 2>/dev/null | grep -q '^1$'; then
  if sysctl -n hw.optional.arm64 2>/dev/null | grep -q '^1$'; then
    ARCH='arm64'
  fi
fi

# Detect musl libc on Linux (Alpine, etc.)
LIBC=""
if [[ "$OS" == "linux" ]]; then
  if grep -qi alpine /etc/os-release 2>/dev/null; then
    LIBC="-musl"
  elif command -v ldd >/dev/null 2>&1 && ldd --version 2>&1 | grep -qi musl; then
    LIBC="-musl"
  fi
fi

info "Detected OS: $OS"
info "Detected Architecture: $ARCH${LIBC}"

# Block root execution except in containers
if [[ $(id -u) -eq 0 ]]; then
  if is_container_env || [[ "${FVM_ALLOW_ROOT:-}" == "true" ]]; then
    info "Root execution allowed (container/CI/override detected)"
  else
    error "This script should not be run as root. Please run as a normal user.

For containers/CI: This should be detected automatically.
To override: export FVM_ALLOW_ROOT=true"
  fi
fi

# Check for required tools
if ! command -v curl &>/dev/null && ! command -v wget &>/dev/null; then
  error "curl or wget is required but neither is installed."
fi

if ! command -v tar &>/dev/null; then
  error "tar is required but not installed."
fi

# Get FVM version (latest if not specified)
if [[ -z "$FVM_VERSION" ]]; then
  info "Getting latest FVM version..."

  # Use GitHub's redirect to get latest version (no API rate limits)
  LATEST_URL=$(curl -fsSL -o /dev/null -w '%{url_effective}' \
    https://github.com/leoafarias/fvm/releases/latest 2>/dev/null)
  FVM_VERSION="${LATEST_URL##*/}"

  if [[ -z "$FVM_VERSION" ]]; then
    FVM_VERSION="3.2.1"  # Fallback to known stable version
    warn "⚠️  Could not fetch latest version from GitHub"
    warn "⚠️  Using fallback version: $FVM_VERSION"
    info "💡 Specify exact version to override: ./install.sh 3.2.1"
  fi
else
  # Validate version format (with or without v prefix, stripped above)
  if [[ ! "$FVM_VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+(-[a-zA-Z0-9._-]+)?$ ]]; then
    error "Invalid version format: $FVM_VERSION. Expected format: 1.2.3"
  fi
fi

info "Preparing to install FVM version: $FVM_VERSION"

# Clean existing installation
if [[ -d "$FVM_DIR_BIN" ]]; then
  info "Removing existing FVM installation..."
  rm -rf "$FVM_DIR_BIN" || error "Failed to remove existing FVM bin directory."
fi

mkdir -p "$FVM_DIR_BIN" || error "Failed to create directory: $FVM_DIR_BIN"

# Download FVM
URL="https://github.com/leoafarias/fvm/releases/download/$FVM_VERSION/fvm-$FVM_VERSION-$OS-$ARCH${LIBC}.tar.gz"
info "Downloading $URL"

ARCHIVE=$(mktemp "${TMPDIR:-/tmp}/fvm-archive.XXXXXX")
TEMP_FILES+=("$ARCHIVE")

# Try curl first (with retry and HTTPS enforcement)
if command -v curl &>/dev/null; then
  if ! curl -fsSL \
       --proto '=https' \
       --tlsv1.2 \
       --retry 3 \
       --retry-delay 2 \
       -o "$ARCHIVE" \
       "$URL"; then
    error "Download failed. Possible causes:
  - Check your internet connection
  - Verify the version exists: $FVM_VERSION
  - Check releases at: https://github.com/leoafarias/fvm/releases"
  fi
elif command -v wget &>/dev/null; then
  if ! wget -q \
       --secure-protocol=TLSv1_2 \
       --https-only \
       --tries=3 \
       -O "$ARCHIVE" \
       "$URL"; then
    error "Download failed. Check connection and version: $FVM_VERSION"
  fi
fi

# Validate download
if [[ ! -s "$ARCHIVE" ]]; then
  error "Downloaded file is empty."
fi

if ! tar -tzf "$ARCHIVE" &>/dev/null; then
  error "Downloaded file is not a valid gzip archive."
fi

# Extract FVM
info "Extracting archive..."
TEMP_EXTRACT="$FVM_DIR/temp_extract"
mkdir -p "$TEMP_EXTRACT"
TEMP_FILES+=("$TEMP_EXTRACT")

if ! tar xzf "$ARCHIVE" -C "$TEMP_EXTRACT"; then
  error "Extraction failed. Possibly corrupt archive or insufficient permissions."
fi

# Handle different tarball structures
if [[ -d "$TEMP_EXTRACT/fvm" ]]; then
  # cli_pkg structure: fvm directory with binary and dependencies
  mv "$TEMP_EXTRACT/fvm"/* "$FVM_DIR_BIN/" || error "Failed to move fvm contents"
elif [[ -f "$TEMP_EXTRACT/fvm" ]]; then
  # Single binary at root
  mv "$TEMP_EXTRACT/fvm" "$FVM_DIR_BIN/" || error "Failed to move fvm binary"
else
  error "Expected 'fvm' binary not found after extraction."
fi

# Verify binary exists and is executable
if [[ ! -f "$FVM_DIR_BIN/fvm" ]]; then
  error "FVM binary not found in expected location after extraction."
fi

if [[ ! -x "$FVM_DIR_BIN/fvm" ]]; then
  chmod +x "$FVM_DIR_BIN/fvm" || warn "Could not make fvm executable"
fi

# Shell configuration helpers
get_path_export() {
  local shell_type="$1"
  case "$shell_type" in
    fish)
      # Use set --export for immediate effect (fish_add_path doesn't work in sourced scripts)
      cat <<EOF
if not contains "$FVM_DIR_BIN" \$PATH
    set --export PATH "$FVM_DIR_BIN" \$PATH
end
EOF
      ;;
    *) echo "export PATH=\"$FVM_DIR_BIN:\$PATH\"" ;;
  esac
}

update_shell_config() {
  local config_file="$1"
  local export_command="$2"
  local tilde_config="${config_file/#$HOME/\~}"
  local tilde_fvm_dir="${FVM_DIR_BIN/#$HOME/\~}"

  # Create parent directory if needed
  local config_dir
  config_dir="$(dirname "$config_file")"
  if [[ ! -d "$config_dir" ]]; then
    mkdir -p "$config_dir" || {
      warn "Could not create directory: $config_dir"
      return 1
    }
  fi

  # Create config file if it doesn't exist
  if [[ ! -f "$config_file" ]]; then
    touch "$config_file" || {
      warn "Could not create file: $tilde_config"
      return 1
    }
    info "Created $tilde_config"
  fi

  # Check if writable
  if [[ ! -w "$config_file" ]]; then
    warn "$tilde_config exists but is not writable"
    return 1
  fi

  # Add PATH if not already present
  if ! grep -q "$FVM_DIR_BIN" "$config_file"; then
    {
      echo -e "\n# FVM"
      echo "$export_command"
    } >> "$config_file"
    info "Added [$tilde_fvm_dir] to \$PATH in [$tilde_config]"
    return 0
  else
    info "[$tilde_config] already references $tilde_fvm_dir; skipping."
    return 0
  fi
}

# Configure shell PATH
success "Installation complete!"
echo ""
info "FVM has been installed to: $FVM_DIR_BIN/fvm"
echo ""

# Skip PATH configuration if requested or running as root in non-container
if [[ "${FVM_NO_PATH:-}" == "true" ]]; then
  info "Skipping PATH configuration (FVM_NO_PATH is set)"
  info "Add to your shell config manually:"
  info "  export PATH=\"$FVM_DIR_BIN:\$PATH\""
elif [[ $(id -u) -eq 0 ]] && ! is_container_env; then
  info "Skipping PATH configuration for root user"
  info "Add to shell config manually:"
  info "  export PATH=\"$FVM_DIR_BIN:\$PATH\""
else
  # Auto-configure shell PATH
  refresh_command=""
  case "$(basename "$SHELL")" in
    fish)
      fish_config="$HOME/.config/fish/config.fish"
      if ! update_shell_config "$fish_config" "$(get_path_export fish)"; then
        log "Manually add the following line to ${fish_config/#$HOME/\~}:"
        info "  $(get_path_export fish)"
      else
        refresh_command="source $fish_config"
      fi
      ;;
    zsh)
      zsh_config="$HOME/.zshrc"
      if ! update_shell_config "$zsh_config" "$(get_path_export zsh)"; then
        log "Manually add the following line to ${zsh_config/#$HOME/\~}:"
        info "  $(get_path_export zsh)"
      else
        refresh_command="source $zsh_config"
      fi
      ;;
    bash)
      bash_configs=("$HOME/.bashrc" "$HOME/.bash_profile")
      set_manually=true
      for bash_config in "${bash_configs[@]}"; do
        if update_shell_config "$bash_config" "$(get_path_export bash)"; then
          set_manually=false
          refresh_command="source $bash_config"
          break
        fi
      done
      if [[ "$set_manually" == true ]]; then
        log "Manually add the following line to your bash config (e.g., ~/.bashrc):"
        info "  $(get_path_export bash)"
      fi
      ;;
    *)
      log "Unknown shell: $(basename "$SHELL"). Manually add to your rc file:"
      info "  $(get_path_export default)"
      ;;
  esac

  echo ""
  info "To use FVM, reload your shell or run:"
  if [[ -n "$refresh_command" ]]; then
    info "  $refresh_command"
  else
    case "$(basename "$SHELL")" in
      fish) info "  source ~/.config/fish/config.fish" ;;
      zsh) info "  source ~/.zshrc" ;;
      bash) info "  source ~/.bashrc" ;;
      *) info "  # Restart your terminal or start a new shell session" ;;
    esac
  fi
fi

echo ""
info "Then verify with:"
info "  fvm --version"
echo ""