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
  armv7l)
    ARCH='arm'
    ;;
  *)
    error "Unsupported architecture: $ARCH"
    ;;
esac

# Print out the detection results to keep the user informed.
info "Detected OS: $OS"
info "Detected Architecture: $ARCH"

###############################################################################
# Avoid Running as Root
# -----------------------------------------------------------------------------
# Installing software as root can be dangerous, especially for userland tools
# that don't *need* full privileges. We want a user-level directory, but do
# require a small privilege escalation for symlinking to /usr/local/bin.
# Alternative approach: We could ask the user if they want a system-level or
# user-level only. Here, we forcibly disallow root for simplicity.
###############################################################################
if [[ $(id -u) -eq 0 ]]; then
  error "This script should not be run as root. Please run as a normal user."
fi

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
# Finding a Privilege-Escalation Tool
# -----------------------------------------------------------------------------
# We only need elevated privileges to create a symlink in /usr/local/bin, which
# is typically root-owned. We'll look for 'sudo' or 'doas'. If neither is found,
# we cannot proceed with system-wide symlink.
# Alternative approach: We could skip this if we only do user-level. But for a
# globally accessible 'fvm' command, we do need it.
###############################################################################
ESCALATION_TOOL=''
for cmd in sudo doas; do
  if command -v "$cmd" &>/dev/null; then
    ESCALATION_TOOL="$cmd"
    break
  fi
done

if [[ -z "$ESCALATION_TOOL" ]]; then
  error "Cannot find sudo or doas for escalated privileges. Aborting."
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
  # Use the argument as version
  FVM_VERSION="$1"
fi

info "Preparing to install FVM version: $FVM_VERSION"

###############################################################################
# Detect Currently Installed FVM and Skip or Upgrade if Needed
# -----------------------------------------------------------------------------
# If FVM is already installed, get its version. If it's the same as the
# requested version, exit early. Otherwise, let the script continue to perform
# an upgrade.
###############################################################################
INSTALLED_FVM_VERSION=""
if command -v fvm &>/dev/null; then
  INSTALLED_FVM_VERSION="$(fvm --version 2>/dev/null | awk '{print $2}')"
  if [[ -z "$INSTALLED_FVM_VERSION" ]]; then
    error "Failed to fetch installed FVM version."
  fi

  if [[ "$INSTALLED_FVM_VERSION" == "$FVM_VERSION" ]]; then
    success "FVM $FVM_VERSION is already installed."
    exit 0
  else
    info "Upgrading FVM from $INSTALLED_FVM_VERSION to $FVM_VERSION"
  fi
fi

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
# If you wanted to verify checksums, you could fetch a .sha256 file and compare.
###############################################################################
URL="https://github.com/leoafarias/fvm/releases/download/$FVM_VERSION/fvm-$FVM_VERSION-$OS-$ARCH.tar.gz"

info "Downloading $URL"
if ! curl -L "$URL" -o fvm.tar.gz; then
  error "Download failed. Check your internet connection and the URL."
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
  error "Extraction failed. Possibly corrupt tar or insufficient permissions."
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
# We use whichever escalation tool we found earlier (sudo/doas) to link
# ~/.fvm_flutter/bin/fvm => /usr/local/bin/fvm. That way any user can type 'fvm'
# in their shell. If we skip this, the user must rely on local PATH changes only.
###############################################################################
info "Creating symlink: $SYMLINK_TARGET -> $FVM_DIR_BIN/fvm"
"$ESCALATION_TOOL" ln -sf "$FVM_DIR_BIN/fvm" "$SYMLINK_TARGET" || error "Failed to symlink in /usr/local/bin"

###############################################################################
# tildify() Helper Function
# -----------------------------------------------------------------------------
# This is purely for cosmetic output. It replaces the real $HOME path with '~'
# for readability when we display paths to the user. E.g., /home/username/.fvm_flutter/bin => ~/.fvm_flutter/bin
###############################################################################
tildify() {
  case $1 in
    "$HOME"*) echo "${1/#$HOME/~}" ;;
    *) echo "$1" ;;
  esac
}

tilde_FVM_DIR_BIN="$(tildify "$FVM_DIR_BIN")"

###############################################################################
# Attempt to Add FVM_DIR_BIN to the User's Shell RC
# -----------------------------------------------------------------------------
# Many shells won't automatically include ~/.fvm_flutter/bin in PATH. We'll try
# to detect if the user is using fish, zsh, or bash by looking at $SHELL. Then
# we append a line to their config only if it's not already present. If we can't
# write to the config, we instruct them to do it manually.
# Why do it this way? So we avoid duplicating PATH lines, especially if the script
# is run multiple times. Checking with 'grep -q' helps skip if it already exists.
###############################################################################
refresh_command=''

case "$(basename "$SHELL")" in
  fish)
    commands=( "set --export PATH $FVM_DIR_BIN \$PATH" )
    fish_config="$HOME/.config/fish/config.fish"
    tilde_fish_config="$(tildify "$fish_config")"

    if [[ -w "$fish_config" ]]; then
      if ! grep -q "$FVM_DIR_BIN" "$fish_config"; then
        {
          echo -e "\n# FVM"
          for cmd in "${commands[@]}"; do
            echo "$cmd"
          done
        } >> "$fish_config"
        info "Added [$tilde_FVM_DIR_BIN] to \$PATH in [$tilde_fish_config]"
        refresh_command="source $fish_config"
      else
        info "[$tilde_fish_config] already references $tilde_FVM_DIR_BIN; skipping."
      fi
    else
      log "Manually add the following lines to $tilde_fish_config (or your fish config):"
      for cmd in "${commands[@]}"; do
        info "  $cmd"
      done
    fi
    ;;
  zsh)
    commands=( "export PATH=\"$FVM_DIR_BIN:\$PATH\"" )
    zsh_config="$HOME/.zshrc"
    tilde_zsh_config="$(tildify "$zsh_config")"

    if [[ -w "$zsh_config" ]]; then
      if ! grep -q "$FVM_DIR_BIN" "$zsh_config"; then
        {
          echo -e "\n# FVM"
          for cmd in "${commands[@]}"; do
            echo "$cmd"
          done
        } >> "$zsh_config"
        info "Added [$tilde_FVM_DIR_BIN] to \$PATH in [$tilde_zsh_config]"
        refresh_command="source $zsh_config"
      else
        info "[$tilde_zsh_config] already references $tilde_FVM_DIR_BIN; skipping."
      fi
    else
      log "Manually add the following lines to $tilde_zsh_config (or your zsh config):"
      for cmd in "${commands[@]}"; do
        info "  $cmd"
      done
    fi
    ;;
  bash)
    commands=( "export PATH=$FVM_DIR_BIN:\$PATH" )
    bash_configs=(
      "$HOME/.bashrc"
      "$HOME/.bash_profile"
    )

    # If XDG_CONFIG_HOME is set, also check those possible config files
    if [[ -n "${XDG_CONFIG_HOME:-}" ]]; then
      bash_configs+=(
        "$XDG_CONFIG_HOME/.bash_profile"
        "$XDG_CONFIG_HOME/.bashrc"
        "$XDG_CONFIG_HOME/bash_profile"
        "$XDG_CONFIG_HOME/bashrc"
      )
    fi

    set_manually=true
    for bash_config in "${bash_configs[@]}"; do
      # If the file is writable, we can safely attempt to append.
      if [[ -w "$bash_config" ]]; then
        tilde_bash_config="$(tildify "$bash_config")"

        # Make sure we don't insert multiple lines if it already references FVM.
        if ! grep -q "$FVM_DIR_BIN" "$bash_config"; then
          {
            echo -e "\n# FVM"
            for cmd in "${commands[@]}"; do
              echo "$cmd"
            done
          } >> "$bash_config"
          info "Added [$tilde_FVM_DIR_BIN] to \$PATH in [$tilde_bash_config]"
          refresh_command="source $bash_config"
        else
          info "[$tilde_bash_config] already references $tilde_FVM_DIR_BIN; skipping."
        fi
        set_manually=false
        break
      fi
    done

    if [[ "$set_manually" == true ]]; then
      # We ended up here if none of the known bash files were writable.
      log "Manually add the directory to your bash config (e.g., ~/.bashrc):"
      for cmd in "${commands[@]}"; do
        info "  $cmd"
      done
    fi
    ;;
  *)
    # If the shell isn't fish, zsh, or bash, we can't easily auto-detect the config.
    # We ask the user to do it manually.
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
