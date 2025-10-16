#!/usr/bin/env bash
# FVM Uninstaller - Remove Flutter Version Management
#
# Usage:
#   curl -fsSL https://fvm.app/uninstall.sh | bash
#   ./uninstall.sh

set -euo pipefail

# Installation paths
FVM_DIR="${FVM_DIR:-$HOME/.fvm_flutter}"
FVM_DIR_BIN="$FVM_DIR/bin"

# Colors
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

info "Uninstalling FVM..."
echo ""

# Check if FVM is installed
fvm_found=false

# Check for FVM directory
if [[ -d "$FVM_DIR" ]]; then
  fvm_found=true
  info "Found FVM directory: $FVM_DIR"
fi

# Check for old symlink (from previous versions)
old_symlink="/usr/local/bin/fvm"
if [[ -L "$old_symlink" ]] && [[ "$(readlink "$old_symlink" 2>/dev/null)" == *"fvm"* ]]; then
  fvm_found=true
  info "Found old FVM symlink: $old_symlink"
fi

if [[ "$fvm_found" == false ]]; then
  warn "FVM installation not found. Nothing to uninstall."
  exit 0
fi

echo ""

# Remove FVM directory
if [[ -d "$FVM_DIR" ]]; then
  info "Removing FVM directory..."
  rm -rf "$FVM_DIR" || error "Failed to remove $FVM_DIR"
  success "Removed $FVM_DIR"
fi

# Remove old symlink if it exists (from previous versions)
if [[ -L "$old_symlink" ]]; then
  info "Removing old FVM symlink..."
  # Try direct removal first
  if rm -f "$old_symlink" 2>/dev/null; then
    success "Removed $old_symlink"
  else
    # Need sudo for removal
    if command -v sudo &>/dev/null && sudo -n true 2>/dev/null; then
      sudo rm -f "$old_symlink" && success "Removed $old_symlink"
    else
      warn "Could not remove $old_symlink (requires sudo)"
      info "Remove manually with: sudo rm -f $old_symlink"
    fi
  fi
fi

echo ""
success "FVM has been uninstalled!"
echo ""

# Notify about PATH cleanup
warn "Note: FVM PATH entries may still exist in your shell config files:"
log "  - ~/.bashrc"
log "  - ~/.zshrc"
log "  - ~/.bash_profile"
log "  - ~/.config/fish/config.fish"
log ""
log "To remove them, search for lines containing '$FVM_DIR_BIN' and delete:"
info "  grep -l '$FVM_DIR_BIN' ~/.bashrc ~/.zshrc ~/.bash_profile 2>/dev/null"
echo ""