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
# 3. We avoid letting the script run as root for security and best practice.
# 4. We set "strict mode" to fail quickly on errors or referencing unset vars.
# 5. We attempt to update the user's shell rc (fish, zsh, bash) to add fvm's bin
#    path if not already present, preventing repeated PATH lines on reruns.
# 6. We thoroughly log what’s happening, using color-coded or bold messages.
###############################################################################


###############################################################################
# Strict Mode
# -----------------------------------------------------------------------------
# The following line:
#   set -euo pipefail
# Does three things:
#   - 'set -e': Exit the script immediately if any command returns a non-zero.
#   - 'set -u': Treat references to unset variables as errors, stopping the script.
#   - 'set -o pipefail': If any part of a pipe fails, the pipeline fails as well.
# This prevents partial or confusing installs if something goes wrong.
###############################################################################
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
Green='\033[0;32m'       # Green
Red='\033[0;31m'         # Red
Bold_White='\033[1m'     # Bold White text

# log() prints a line with no extra formatting.
log() {
  echo -e "$1"
}

# success() prints in green (used for positive messages, though not mandatory).
success() {
  log "${Green}$1${Color_Off}"
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

###############################################################################
# OS and Architecture Detection
# -----------------------------------------------------------------------------
# We check 'uname -s' for OS and 'uname -m' for machine architecture. Then we map
# them to specific values expected by the FVM release artifacts:
#   - OS => linux or macos
#   - Arch => x64, arm64, or arm
# Why do it this way? Because FVM's GitHub releases are named accordingly
# (e.g., fvm-2.0.0-linux-x64.tar.gz), so we must unify those naming expectations.
#
# Alternatives: We could parse /etc/os-release or rely on environment variables,
# but 'uname' is the simplest universal approach on macOS & Linux.
###############################################################################
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

###############################################################################
# Root User Check with Simple Override
# -----------------------------------------------------------------------------
# Block root execution by default for security, but allow override for containers/CI.
# Simple detection: check for common container/CI indicators or explicit override.
###############################################################################
if [[ $(id -u) -eq 0 ]]; then
  # Allow root if: Docker container, CI environment, or explicit override
  if [[ -f /.dockerenv ]] || [[ -n "${CI:-}" ]] || [[ "${FVM_ALLOW_ROOT:-}" == "true" ]]; then
    info "Root execution allowed (container/CI/override detected)"
  else
    error "This script should not be run as root. Please run as a normal user.

For containers/CI: This should be detected automatically.
To override: export FVM_ALLOW_ROOT=true"
  fi
fi

# Store root status for later use
IS_ROOT=$([[ $(id -u) -eq 0 ]] && echo "true" || echo "false")

###############################################################################
# Check for 'curl'
# -----------------------------------------------------------------------------
# We need 'curl' to fetch data from GitHub. If it's missing, we fail early with
# instructions. Why not install it automatically? Because we don't want to rely
# on a package manager (brew, apt, etc.). So we just inform the user.
###############################################################################
if ! command -v curl &>/dev/null; then
  error "curl is required but not installed. Install it manually and re-run."
fi

###############################################################################
# Privilege Escalation Tool Detection
# -----------------------------------------------------------------------------
# Find sudo/doas for system symlink creation (only needed if not root).
###############################################################################
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

###############################################################################
# (Optional) Detect Currently Installed FVM
# -----------------------------------------------------------------------------
# If FVM is already installed, we can detect it for informational purposes.
# This could be extended in the future to compare versions or provide upgrade info.
###############################################################################
if command -v fvm &>/dev/null; then
  info "Existing FVM installation detected. It will be replaced."
fi

###############################################################################
# Determine Which FVM Version to Install
# -----------------------------------------------------------------------------
# If the script is called with an argument, we assume it's a version/tag (e.g. 2.0.0).
# Otherwise, we query GitHub releases for the 'latest' tag. If that fails, we bail.
# Why not parse JSON properly with 'jq'? Because 'jq' might not be installed.
# So we do a quick 'grep' & 'sed' approach.
###############################################################################
FVM_VERSION=""
if [[ $# -eq 0 ]]; then
  # No arguments => fetch the 'latest' from GitHub
  FVM_VERSION="$(
    curl -s https://api.github.com/repos/leoafarias/fvm/releases/latest \
    | grep '"tag_name":' \
    | sed -E 's/.*"([^"]+)".*/\1/'
  )"
  if [[ -z "$FVM_VERSION" ]]; then
    error "Failed to determine the latest FVM version from GitHub."
  fi
else
  # Use the argument as version - validate it's not empty and doesn't contain dangerous characters
  FVM_VERSION="$1"
  if [[ -z "$FVM_VERSION" ]] || [[ "$FVM_VERSION" =~ [^a-zA-Z0-9._-] ]]; then
    error "Invalid version format: $FVM_VERSION"
  fi
fi

info "Preparing to install FVM version: $FVM_VERSION"

###############################################################################
# Define Installation Directories
# -----------------------------------------------------------------------------
# We want a user-level directory for storing the FVM binary. We'll create:
#   ~/.fvm_flutter/bin
# Then we place 'fvm' inside that bin, and symlink to /usr/local/bin/fvm.
# Why .fvm_flutter? It's an arbitrary choice, used by convention for FVM.
###############################################################################
FVM_DIR="$HOME/.fvm_flutter"
FVM_DIR_BIN="$FVM_DIR/bin"
SYMLINK_TARGET="/usr/local/bin/fvm"

# Validate that the symlink target directory exists and is writable
SYMLINK_DIR="$(dirname "$SYMLINK_TARGET")"
if [[ ! -d "$SYMLINK_DIR" ]]; then
  error "Symlink target directory does not exist: $SYMLINK_DIR"
fi

###############################################################################
# Clean Up Existing FVM Bin Directory (if any), Then Recreate
# -----------------------------------------------------------------------------
# We remove ~/.fvm_flutter/bin if it exists, to avoid leftover files. Then we
# recreate it so we have a clean slate. If we didn't reorder these steps, we'd
# risk creating it, then immediately deleting it. This ensures clarity.
###############################################################################
if [[ -d "$FVM_DIR_BIN" ]]; then
  info "FVM bin directory [$FVM_DIR_BIN] already exists. Removing it."
  rm -rf "$FVM_DIR_BIN" || error "Failed to remove existing FVM bin directory."
fi

mkdir -p "$FVM_DIR_BIN" || error "Failed to create directory: $FVM_DIR_BIN"

###############################################################################
# Download FVM Tarball
# -----------------------------------------------------------------------------
# We form the GitHub release URL for the chosen version, OS, and architecture.
# Example: https://github.com/leoafarias/fvm/releases/download/2.0.0/fvm-2.0.0-linux-x64.tar.gz
# We then download it to 'fvm.tar.gz'.
###############################################################################
URL="https://github.com/leoafarias/fvm/releases/download/$FVM_VERSION/fvm-$FVM_VERSION-$OS-$ARCH.tar.gz"

info "Downloading $URL"
if ! curl -L --fail --show-error "$URL" -o fvm.tar.gz; then
  error "Download failed. Check your internet connection and verify the version exists."
fi

# Validate the downloaded file is not empty and appears to be a gzip file
if [[ ! -s fvm.tar.gz ]]; then
  rm -f fvm.tar.gz
  error "Downloaded file is empty or corrupted."
fi

if ! file fvm.tar.gz | grep -q "gzip compressed"; then
  rm -f fvm.tar.gz
  error "Downloaded file is not a valid gzip archive."
fi

###############################################################################
# Extract Tarball
# -----------------------------------------------------------------------------
# We extract it directly into ~/.fvm_flutter. The tar presumably contains a
# single 'fvm' binary at the top level. We can verify it's indeed so. If the
# tar file structure changes, we'd need to adjust the logic.
###############################################################################
info "Extracting fvm.tar.gz into $FVM_DIR"
if ! tar xzf fvm.tar.gz -C "$FVM_DIR" 2>&1; then
  rm -f fvm.tar.gz
  error "Extraction failed. Possibly corrupt tar or insufficient permissions."
fi

# Verify the expected binary was extracted
if [[ ! -f "$FVM_DIR/fvm" ]]; then
  rm -f fvm.tar.gz
  error "Expected 'fvm' binary not found after extraction."
fi

# Cleanup the tarball to avoid clutter
rm -f fvm.tar.gz || error "Failed to remove the downloaded fvm.tar.gz"

###############################################################################
# Move 'fvm' into the 'bin' subdirectory
# -----------------------------------------------------------------------------
# After extraction, we expect $FVM_DIR/fvm to exist. We want it in $FVM_DIR/bin
# for clarity. This also makes it easier to add that bin path to the environment.
###############################################################################
mv "$FVM_DIR/fvm" "$FVM_DIR_BIN" || error "Failed to move 'fvm' binary to bin directory."

###############################################################################
# Create Symlink in /usr/local/bin
# -----------------------------------------------------------------------------
# Create a system-wide symlink so any user can type 'fvm'. If we're running as
# root, we can do this directly. Otherwise, we use the escalation tool we found.
###############################################################################
info "Creating symlink: $SYMLINK_TARGET -> $FVM_DIR_BIN/fvm"

if [[ "$IS_ROOT" == "true" ]]; then
  ln -sf "$FVM_DIR_BIN/fvm" "$SYMLINK_TARGET" || error "Failed to symlink in /usr/local/bin"
else
  "$ESCALATION_TOOL" ln -sf "$FVM_DIR_BIN/fvm" "$SYMLINK_TARGET" || error "Failed to symlink in /usr/local/bin"
fi

###############################################################################
# Helper Functions
# -----------------------------------------------------------------------------
# tildify() - Replaces $HOME path with '~' for readability
# update_shell_config() - Common logic for updating shell configuration files
###############################################################################
tildify() {
  if [[ "$1" = "$HOME"* ]]; then
    echo "~${1#"$HOME"}"
  else
    echo "$1"
  fi
}

# update_shell_config(config_file, export_command)
# Updates a shell configuration file with the FVM PATH export
update_shell_config() {
  local config_file="$1"
  local export_command="$2"
  local tilde_config
  tilde_config="$(tildify "$config_file")"

  if [[ -w "$config_file" ]]; then
    if ! grep -q "$FVM_DIR_BIN" "$config_file"; then
      {
        echo -e "\n# FVM"
        echo "$export_command"
      } >> "$config_file"
      info "Added [$tilde_FVM_DIR_BIN] to \$PATH in [$tilde_config]"
      refresh_command="source $config_file"
    else
      info "[$tilde_config] already references $tilde_FVM_DIR_BIN; skipping."
    fi
    return 0
  else
    return 1
  fi
}

tilde_FVM_DIR_BIN="$(tildify "$FVM_DIR_BIN")"

###############################################################################
# Attempt to Add FVM_DIR_BIN to the User's Shell RC
# -----------------------------------------------------------------------------
# Many shells won't automatically include ~/.fvm_flutter/bin in PATH. We'll try
# to detect if the user is using fish, zsh, or bash by looking at $SHELL. Then
# we append a line to their config only if it's not already present. If we can't
# write to the config, we instruct them to do it manually.
#
# Special handling for root: In container environments, we set up shell config
# for root. In regular environments, we provide instructions for manual setup.
###############################################################################
refresh_command=''

# Skip shell config for root in non-container environments (security)
if [[ "$IS_ROOT" == "true" ]] && [[ ! -f /.dockerenv ]] && [[ -z "${CI:-}" ]]; then
  info "Installation complete! (Shell config skipped for root user)"
  log "fvm is available system-wide. Other users should add to their shell config:"
  info "  export PATH=\"$FVM_DIR_BIN:\$PATH\""
  exit 0
fi

case "$(basename "$SHELL")" in
  fish)
    fish_config="$HOME/.config/fish/config.fish"
    if ! update_shell_config "$fish_config" "set --export PATH $FVM_DIR_BIN \$PATH"; then
      log "Manually add the following line to $(tildify "$fish_config"):"
      info "  set --export PATH $FVM_DIR_BIN \$PATH"
    fi
    ;;
  zsh)
    zsh_config="$HOME/.zshrc"
    if ! update_shell_config "$zsh_config" "export PATH=\"$FVM_DIR_BIN:\$PATH\""; then
      log "Manually add the following line to $(tildify "$zsh_config"):"
      info "  export PATH=\"$FVM_DIR_BIN:\$PATH\""
    fi
    ;;
  bash)
    # Try common bash config files in order of preference
    bash_configs=("$HOME/.bashrc" "$HOME/.bash_profile")

    set_manually=true
    for bash_config in "${bash_configs[@]}"; do
      if update_shell_config "$bash_config" "export PATH=$FVM_DIR_BIN:\$PATH"; then
        set_manually=false
        break
      fi
    done

    if [[ "$set_manually" == true ]]; then
      log "Manually add the following line to your bash config (e.g., ~/.bashrc):"
      info "  export PATH=$FVM_DIR_BIN:\$PATH"
    fi
    ;;
  *)
    log "Unknown shell: $(basename "$SHELL"). Manually add to your rc file:"
    info "  export PATH=\"$FVM_DIR_BIN:\$PATH\""
    ;;
esac

###############################################################################
# Final Instructions
# -----------------------------------------------------------------------------
# We print a short message to tell the user how to immediately apply the new PATH
# changes (if we automatically appended them) and how to start using FVM.
###############################################################################
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