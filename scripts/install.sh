#!/usr/bin/env bash
###############################################################################
# FVM Installer
# -----------------------------------------------------------------------------
# This script installs FVM (Flutter Version Management) in a user-level location
# (~/.fvm_flutter/bin) and then symlinks it system-wide to /usr/local/bin/fvm.
#
# Key Points:
# 1. We do not rely on package managers (Homebrew, apt, yum, etc.). We only
#    require core tools like curl, tar, grep, sed.
# 2. We detect OS/architecture and automatically fetch the appropriate prebuilt
#    binary from GitHub.
# 3. We avoid root execution on desktop/server systems but allow it in containers.
# 4. We set "strict mode" to fail quickly on errors or referencing unset vars.
# 5. We attempt to update the user's shell rc (fish, zsh, bash) to add fvm's bin
#    path if not already present, preventing repeated PATH lines on reruns.
# 6. We thoroughly log what’s happening, using color-coded or bold messages.
###############################################################################


# Exit on error, undefined vars, pipe failures
set -euo pipefail

###############################################################################
# Logging & Color Setup
# -----------------------------------------------------------------------------
# We define ANSI escape codes for colored output. Then we define helper functions
# (log, info, success, error) for consistent, readable messaging.
# Why do it this way? Because it avoids external dependencies like 'tput' or
# non-standard libraries, ensuring maximum compatibility across macOS & Linux.
###############################################################################
Color_Off='\033[0m'      # Reset color
Red='\033[0;31m'         # Red
Bold_White='\033[1m'     # Bold White text

# log() prints a line with no extra formatting.
log() {
  echo -e "$1"
}

# info() prints in bold white for emphasis or step announcements.
info() {
  log "${Bold_White}$1${Color_Off}"
}

# error() prints in red to stderr, then exits the script with code 1.
error() {
  log "${Red}error: $1${Color_Off}" >&2
  exit 1
}

# Detect OS and architecture for GitHub release naming (e.g., fvm-2.0.0-linux-x64.tar.gz)
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

# Print out the detection results to keep the user informed.
info "Detected OS: $OS"
info "Detected Architecture: $ARCH"

# Helper function to detect container environment
is_container_env() {
  [[ -f /.dockerenv ]] || [[ -f /.containerenv ]] || [[ -n "${CI:-}" ]]
}

###############################################################################
# Root User Check with Simple Override
# -----------------------------------------------------------------------------
# Block root execution by default for security, but allow override for containers/CI.
# Simple detection: check for common container/CI indicators or explicit override.
###############################################################################
if [[ $(id -u) -eq 0 ]]; then
  # Allow root if: Docker/Podman container, CI environment, or explicit override
  if is_container_env || [[ "${FVM_ALLOW_ROOT:-}" == "true" ]]; then
    info "Root execution allowed (container/CI/override detected)"
  else
    error "This script should not be run as root. Please run as a normal user.

For containers/CI: This should be detected automatically.
To override: export FVM_ALLOW_ROOT=true"
  fi
fi

# Store root status for later use
IS_ROOT=$([[ $(id -u) -eq 0 ]] && echo "true" || echo "false")

# Store container status for later use
IS_CONTAINER=$(is_container_env && echo "true" || echo "false")

# Helper function to create symlinks (DRY)
create_symlink() {
  local source="$1"
  local target="$2"

  if [[ "$IS_ROOT" == "true" ]]; then
    ln -sf "$source" "$target" || error "Failed to create symlink: $target"
  else
    "$ESCALATION_TOOL" ln -sf "$source" "$target" || error "Failed to create symlink: $target"
  fi
}

# Require curl for GitHub API access
if ! command -v curl &>/dev/null; then
  error "curl is required but not installed. Install it manually and re-run."
fi

# Find sudo/doas for system symlink creation (only needed if not root)
ESCALATION_TOOL=''

if [[ "$IS_ROOT" != "true" ]]; then
  for cmd in sudo doas; do
    if command -v "$cmd" &>/dev/null; then
      ESCALATION_TOOL="$cmd"
      break
    fi
  done

  [[ -z "$ESCALATION_TOOL" ]] && error "Cannot find sudo or doas. Install one or run as root."
fi

# Detect existing FVM installation
if command -v fvm &>/dev/null; then
  info "Existing FVM installation detected. It will be replaced."
fi

# Determine FVM version: use argument or fetch latest from GitHub
FVM_VERSION=""
if [[ $# -eq 0 ]]; then
  # No arguments => fetch the 'latest' from GitHub
  FVM_VERSION="$(
    curl --silent https://api.github.com/repos/leoafarias/fvm/releases/latest \
    | grep '"tag_name":' \
    | sed -E 's/.*"([^"]+)".*/\1/'
  )"
  if [[ -z "$FVM_VERSION" ]]; then
    error "Failed to determine the latest FVM version from GitHub."
  fi
else
  # Use the argument as version - validate it matches semantic versioning pattern
  FVM_VERSION="$1"
  if [[ ! "$FVM_VERSION" =~ ^v?[0-9]+\.[0-9]+\.[0-9]+(-[a-zA-Z0-9._-]+)?$ ]]; then
    error "Invalid version format: $FVM_VERSION. Expected format: 1.2.3 or v1.2.3"
  fi
fi

info "Preparing to install FVM version: $FVM_VERSION"

# Define installation directories
FVM_DIR="$HOME/.fvm_flutter"
FVM_DIR_BIN="$FVM_DIR/bin"
SYMLINK_TARGET="/usr/local/bin/fvm"

# Ensure symlink target directory exists
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

# Clean up existing installation and create fresh directory
if [[ -d "$FVM_DIR_BIN" ]]; then
  info "FVM bin directory [$FVM_DIR_BIN] already exists. Removing it."
  rm -rf "$FVM_DIR_BIN" || error "Failed to remove existing FVM bin directory."
fi

mkdir -p "$FVM_DIR_BIN" || error "Failed to create directory: $FVM_DIR_BIN"

# Download FVM release tarball
URL="https://github.com/leoafarias/fvm/releases/download/$FVM_VERSION/fvm-$FVM_VERSION-$OS-$ARCH.tar.gz"

info "Downloading $URL"
if ! curl -L --fail --show-error "$URL" -o fvm.tar.gz; then
  error "Download failed. Possible causes:
  - Check your internet connection
  - Verify the version exists: $FVM_VERSION
  - Check releases at: https://github.com/leoafarias/fvm/releases"
fi

# Validate the downloaded file
if [[ ! -s fvm.tar.gz ]]; then
  rm -f fvm.tar.gz
  error "Downloaded file is empty."
fi

# Test if it's a valid gzip by trying to list its contents
if ! tar -tzf fvm.tar.gz &>/dev/null; then
  rm -f fvm.tar.gz
  error "Downloaded file is not a valid gzip archive."
fi

# Extract and validate FVM binary
info "Extracting fvm.tar.gz into temporary directory"
TEMP_EXTRACT="$FVM_DIR/temp_extract"
mkdir -p "$TEMP_EXTRACT"
if ! tar xzf fvm.tar.gz -C "$TEMP_EXTRACT"; then
  rm -rf "$TEMP_EXTRACT"
  rm -f fvm.tar.gz
  error "Extraction failed. Possibly corrupt tar or insufficient permissions."
fi

# The tarball contains fvm/fvm structure with dependencies in fvm/src/
# We need to preserve the entire structure
if [[ -d "$TEMP_EXTRACT/fvm" ]]; then
  # Move all contents from fvm/ to bin/
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

# Verify the fvm binary exists
if [[ ! -f "$FVM_DIR_BIN/fvm" ]]; then
  rm -f fvm.tar.gz
  error "FVM binary not found in expected location after extraction."
fi

# Cleanup the tarball to avoid clutter
rm -f fvm.tar.gz || error "Failed to remove the downloaded fvm.tar.gz"

# Create system-wide symlink
info "Creating symlink: $SYMLINK_TARGET -> $FVM_DIR_BIN/fvm"
create_symlink "$FVM_DIR_BIN/fvm" "$SYMLINK_TARGET"

# Helper functions for shell configuration

# Get the appropriate PATH export command for a shell type
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

# update_shell_config(config_file, export_command)
# Updates a shell configuration file with the FVM PATH export
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

# Skip shell config for root in non-container environments (security)
if [[ "$IS_ROOT" == "true" ]] && [[ "$IS_CONTAINER" != "true" ]]; then
  info "Installation complete! (Shell config skipped for root user)"
  log "fvm is available system-wide. Other users should add to their shell config:"
  info "  export PATH=\"$FVM_DIR_BIN:\$PATH\""
  exit 0
fi

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
    # Try common bash config files in order of preference
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

# Final installation instructions
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