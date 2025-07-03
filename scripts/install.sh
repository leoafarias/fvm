#!/usr/bin/env bash
# FVM Installer - Install/Uninstall Flutter Version Management
#
# Usage:
#   curl -fsSL https://fvm.app/install.sh | bash
#   curl -fsSL https://fvm.app/install.sh | bash -s 3.2.1
#   ./install.sh [OPTIONS] [VERSION]
#
# Examples:
#   ./install.sh              # Install latest version
#   ./install.sh 3.2.1        # Install specific version
#   ./install.sh --uninstall  # Uninstall FVM
#   ./install.sh --help       # Show help
#
# Environment:
#   FVM_ALLOW_ROOT=true       # Allow root installation (for containers/CI)

set -euo pipefail

# Script version
SCRIPT_VERSION="1.1.0"

# Installation paths
FVM_DIR="$HOME/.fvm_flutter"
FVM_DIR_BIN="$FVM_DIR/bin"
SYMLINK_TARGET="/usr/local/bin/fvm"

# Colors for output
Color_Off='\033[0m'
Red='\033[0;31m'
Green='\033[0;32m'
Yellow='\033[1;33m'
Bold_White='\033[1m'

# Simple logging functions
log() {
  printf "%b\n" "$1"
}

info() {
  log "${Bold_White}$1${Color_Off}"
}

success() {
  log "${Green}$1${Color_Off}"
}

warn() {
  log "${Yellow}$1${Color_Off}"
}

error() {
  log "${Red}error: $1${Color_Off}" >&2
  exit 1
}

# Show help
show_help() {
  cat << EOF
FVM Installer v${SCRIPT_VERSION}

Install/Uninstall Flutter Version Management (FVM) on Linux/macOS

USAGE:
    curl -fsSL https://fvm.app/install.sh | bash
    curl -fsSL https://fvm.app/install.sh | bash -s [VERSION]
    ./install.sh [OPTIONS] [VERSION]

OPTIONS:
    -h, --help        Show this help message
    -v, --version     Show script version
    -u, --uninstall   Uninstall FVM

ARGUMENTS:
    VERSION         Specific FVM version to install (e.g., 3.2.1)
                    If omitted, installs the latest version

EXAMPLES:
    # Install latest version
    curl -fsSL https://fvm.app/install.sh | bash

    # Install specific version
    curl -fsSL https://fvm.app/install.sh | bash -s 3.2.1
    
    # Uninstall FVM
    ./install.sh --uninstall
    
    # Allow root installation in containers
    export FVM_ALLOW_ROOT=true
    ./install.sh

ENVIRONMENT:
    FVM_ALLOW_ROOT  Set to 'true' to allow root installation (containers/CI)

EOF
  exit 0
}

# Check if running in container/CI environment
is_container_env() {
  [[ -f /.dockerenv ]] || [[ -f /.containerenv ]] || [[ -n "${CI:-}" ]]
}

# Store root/container status
IS_ROOT=$([[ $(id -u) -eq 0 ]] && echo "true" || echo "false")
IS_CONTAINER=$(is_container_env && echo "true" || echo "false")

# Find privilege escalation tool (sudo/doas)
ESCALATION_TOOL=''
if [[ "$IS_ROOT" != "true" ]]; then
  for cmd in sudo doas; do
    if command -v "$cmd" &>/dev/null; then
      ESCALATION_TOOL="$cmd"
      break
    fi
  done
fi

# Helper to create symlinks
create_symlink() {
  local source="$1"
  local target="$2"

  if [[ "$IS_ROOT" == "true" ]]; then
    ln -sf "$source" "$target" || error "Failed to create symlink: $target"
  else
    "$ESCALATION_TOOL" ln -sf "$source" "$target" || error "Failed to create symlink: $target"
  fi
}

# Helper to remove symlinks
remove_symlink() {
  local target="$1"
  
  if [[ "$IS_ROOT" == "true" ]]; then
    rm -f "$target" || error "Failed to remove symlink: $target"
  else
    "$ESCALATION_TOOL" rm -f "$target" || error "Failed to remove symlink: $target"
  fi
}

# Uninstall FVM
uninstall_fvm() {
  info "Uninstalling FVM..."
  
  # Check if FVM is installed
  local fvm_found=false
  
  # Check for FVM directory
  if [[ -d "$FVM_DIR" ]]; then
    fvm_found=true
    info "Found FVM directory: $FVM_DIR"
  fi
  
  # Check for symlink
  if [[ -L "$SYMLINK_TARGET" ]] && [[ "$(readlink "$SYMLINK_TARGET")" == *"fvm"* ]]; then
    fvm_found=true
    info "Found FVM symlink: $SYMLINK_TARGET"
  fi
  
  if [[ "$fvm_found" == false ]]; then
    warn "FVM installation not found. Nothing to uninstall."
    exit 0
  fi
  
  # Remove FVM directory
  if [[ -d "$FVM_DIR" ]]; then
    info "Removing FVM directory..."
    rm -rf "$FVM_DIR" || error "Failed to remove $FVM_DIR"
    success "Removed $FVM_DIR"
  fi
  
  # Remove symlink
  if [[ -L "$SYMLINK_TARGET" ]]; then
    info "Removing FVM symlink..."
    remove_symlink "$SYMLINK_TARGET"
    success "Removed $SYMLINK_TARGET"
  fi
  
  # Notify about PATH cleanup
  warn "Note: FVM PATH entries may still exist in your shell config files:"
  log "  - ~/.bashrc"
  log "  - ~/.zshrc"
  log "  - ~/.config/fish/config.fish"
  log ""
  log "To remove them, search for lines containing '$FVM_DIR_BIN' in these files."
  
  success "FVM has been uninstalled!"
  exit 0
}

# Parse command line arguments
FVM_VERSION=""
UNINSTALL_MODE=false

while [[ $# -gt 0 ]]; do
  case $1 in
    -h|--help)
      show_help
      ;;
    -v|--version)
      echo "FVM Installer v${SCRIPT_VERSION}"
      exit 0
      ;;
    -u|--uninstall)
      UNINSTALL_MODE=true
      ;;
    -*)
      error "Unknown option: $1. Use --help for usage."
      ;;
    *)
      # Assume it's a version number
      FVM_VERSION="$1"
      ;;
  esac
  shift
done

# Handle uninstall mode
if [[ "$UNINSTALL_MODE" == true ]]; then
  uninstall_fvm
fi

# From here on is installation logic...

# Detect OS and architecture
OS="$(uname -s)"
ARCH="$(uname -m)"

case "$OS" in
  Linux*)
    OS='linux'
    ;;
  Darwin*)
    OS='macos'
    ;;
  *)
    error "Unsupported OS: $OS"
    ;;
esac

case "$ARCH" in
  x86_64)
    ARCH='x64'
    ;;
  arm64|aarch64)
    ARCH='arm64'
    ;;
  *)
    error "Unsupported architecture: $ARCH. Only x64 and arm64 are supported."
    ;;
esac

info "Detected OS: $OS"
info "Detected Architecture: $ARCH"

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
if ! command -v curl &>/dev/null; then
  error "curl is required but not installed. Install it manually and re-run."
fi

# Only check for escalation tools if not running as root
if [[ "$IS_ROOT" != "true" ]]; then
  if [[ -z "$ESCALATION_TOOL" ]]; then
    error "Cannot find sudo or doas. Install one or run as root."
  fi
fi

# Check for existing installation
if command -v fvm &>/dev/null; then
  info "Existing FVM installation detected. It will be replaced."
fi

# Get FVM version (latest if not specified)
if [[ -z "$FVM_VERSION" ]]; then
  info "Getting latest FVM version..."
  
  # Use GitHub's web redirect instead of API to avoid rate limits
  # GitHub Actions runners share IPs and hit the 60 req/hour API limit
  # This method has no rate limits and is simpler (KISS principle)
  FVM_VERSION=$(curl -sI https://github.com/leoafarias/fvm/releases/latest | grep -i location | cut -d' ' -f2 | rev | cut -d'/' -f1 | rev | tr -d '\r')
  
  if [[ -z "$FVM_VERSION" ]]; then
    # Simple fallback - no complex error handling needed
    FVM_VERSION="3.2.1"
    warn "Could not fetch latest version. Using fallback: $FVM_VERSION"
  fi
else
  # Validate version format
  if [[ ! "$FVM_VERSION" =~ ^v?[0-9]+\.[0-9]+\.[0-9]+(-[a-zA-Z0-9._-]+)?$ ]]; then
    error "Invalid version format: $FVM_VERSION. Expected format: 1.2.3 or v1.2.3"
  fi
fi

info "Preparing to install FVM version: $FVM_VERSION"

# Ensure symlink directory exists
SYMLINK_DIR="$(dirname "$SYMLINK_TARGET")"
if [[ ! -d "$SYMLINK_DIR" ]]; then
  if [[ "$IS_ROOT" == "true" ]]; then
    mkdir -p "$SYMLINK_DIR" || error "Failed to create directory: $SYMLINK_DIR"
    info "Created directory: $SYMLINK_DIR"
  else
    error "Symlink target directory does not exist: $SYMLINK_DIR
    
Please create it with: sudo mkdir -p $SYMLINK_DIR"
  fi
fi

# Clean existing installation
if [[ -d "$FVM_DIR_BIN" ]]; then
  info "FVM bin directory [$FVM_DIR_BIN] already exists. Removing it."
  rm -rf "$FVM_DIR_BIN" || error "Failed to remove existing FVM bin directory."
fi

mkdir -p "$FVM_DIR_BIN" || error "Failed to create directory: $FVM_DIR_BIN"

# Download FVM
URL="https://github.com/leoafarias/fvm/releases/download/$FVM_VERSION/fvm-$FVM_VERSION-$OS-$ARCH.tar.gz"

info "Downloading $URL"
if ! curl -L --fail --show-error "$URL" -o fvm.tar.gz; then
  error "Download failed. Possible causes:
  - Check your internet connection
  - Verify the version exists: $FVM_VERSION
  - Check releases at: https://github.com/leoafarias/fvm/releases"
fi

# Validate download
if [[ ! -s fvm.tar.gz ]]; then
  rm -f fvm.tar.gz
  error "Downloaded file is empty."
fi

# Test if valid gzip
if ! tar -tzf fvm.tar.gz &>/dev/null; then
  rm -f fvm.tar.gz
  error "Downloaded file is not a valid gzip archive."
fi

# Extract FVM
info "Extracting fvm.tar.gz into temporary directory"
TEMP_EXTRACT="$FVM_DIR/temp_extract"
mkdir -p "$TEMP_EXTRACT"
if ! tar xzf fvm.tar.gz -C "$TEMP_EXTRACT"; then
  rm -rf "$TEMP_EXTRACT"
  rm -f fvm.tar.gz
  error "Extraction failed. Possibly corrupt tar or insufficient permissions."
fi

# Handle different tarball structures
if [[ -d "$TEMP_EXTRACT/fvm" ]]; then
  # New structure: fvm directory with binary and dependencies
  mv "$TEMP_EXTRACT/fvm"/* "$FVM_DIR_BIN/" || error "Failed to move fvm contents"
  rm -rf "$TEMP_EXTRACT"
elif [[ -f "$TEMP_EXTRACT/fvm" ]]; then
  # Old structure: just the binary at root
  mv "$TEMP_EXTRACT/fvm" "$FVM_DIR_BIN/" || error "Failed to move fvm binary"
  rm -rf "$TEMP_EXTRACT"
else
  rm -rf "$TEMP_EXTRACT"
  rm -f fvm.tar.gz
  error "Expected 'fvm' binary not found after extraction."
fi

# Verify binary exists
if [[ ! -f "$FVM_DIR_BIN/fvm" ]]; then
  rm -f fvm.tar.gz
  error "FVM binary not found in expected location after extraction."
fi

# Cleanup
rm -f fvm.tar.gz || error "Failed to remove the downloaded fvm.tar.gz"

# Create system symlink
info "Creating symlink: $SYMLINK_TARGET -> $FVM_DIR_BIN/fvm"
create_symlink "$FVM_DIR_BIN/fvm" "$SYMLINK_TARGET"

# Shell configuration helpers
get_path_export() {
  local shell_type="$1"
  case "$shell_type" in
    fish)
      echo "set --export PATH $FVM_DIR_BIN \$PATH"
      ;;
    *)
      echo "export PATH=\"$FVM_DIR_BIN:\$PATH\""
      ;;
  esac
}

update_shell_config() {
  local config_file="$1"
  local export_command="$2"
  local tilde_config="${config_file/#$HOME/\~}"
  local tilde_fvm_dir="${FVM_DIR_BIN/#$HOME/\~}"

  if [[ -w "$config_file" ]]; then
    if ! grep -q "$FVM_DIR_BIN" "$config_file"; then
      {
        echo -e "\n# FVM"
        echo "$export_command"
      } >> "$config_file"
      info "Added [$tilde_fvm_dir] to \$PATH in [$tilde_config]"
      refresh_command="source $config_file"
    else
      info "[$tilde_config] already references $tilde_fvm_dir; skipping."
    fi
    return 0
  else
    return 1
  fi
}

# Configure shell PATH (skip for root in non-container environments)
refresh_command=''

if [[ "$IS_ROOT" == "true" ]] && [[ "$IS_CONTAINER" != "true" ]]; then
  info "Installation complete! (Shell config skipped for root user)"
  log "fvm is available system-wide. Other users should add to their shell config:"
  info "  export PATH=\"$FVM_DIR_BIN:\$PATH\""
  exit 0
fi

# Update shell config based on current shell
case "$(basename "$SHELL")" in
  fish)
    fish_config="$HOME/.config/fish/config.fish"
    if ! update_shell_config "$fish_config" "$(get_path_export fish)"; then
      log "Manually add the following line to ${fish_config/#$HOME/\~}:"
      info "  $(get_path_export fish)"
    fi
    ;;
  zsh)
    zsh_config="$HOME/.zshrc"
    if ! update_shell_config "$zsh_config" "$(get_path_export zsh)"; then
      log "Manually add the following line to ${zsh_config/#$HOME/\~}:"
      info "  $(get_path_export zsh)"
    fi
    ;;
  bash)
    bash_configs=("$HOME/.bashrc" "$HOME/.bash_profile")

    set_manually=true
    for bash_config in "${bash_configs[@]}"; do
      if update_shell_config "$bash_config" "$(get_path_export bash)"; then
        set_manually=false
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

# Final instructions
echo
info "Installation complete!"
log "To use fvm right away, run:"
echo

if [[ -n "$refresh_command" ]]; then
  info "  $refresh_command"
else
  log "  # (No shell config updated automatically, or not necessary.)"
fi

info "  fvm --help"
