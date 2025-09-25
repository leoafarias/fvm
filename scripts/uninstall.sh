#!/usr/bin/env bash
# FVM Uninstaller - Remove Flutter Version Management
#
# Usage:
#   curl -fsSL https://fvm.app/uninstall.sh | bash
#   ./uninstall.sh
#
# This script safely removes FVM and cleans up system integration

set -euo pipefail

# Installation paths (matching install.sh)
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

# Store root/container status for symlink removal
IS_ROOT=$([[ $(id -u) -eq 0 ]] && echo "true" || echo "false")

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

# Helper to remove symlinks
remove_symlink() {
  local target="$1"
  
  if [[ "$IS_ROOT" == "true" ]]; then
    rm -f "$target" || error "Failed to remove symlink: $target"
  else
    "$ESCALATION_TOOL" rm -f "$target" || error "Failed to remove symlink: $target"
  fi
}

# Main uninstall function
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
  if [[ -L "$SYMLINK_TARGET" ]]; then
    local link_target
    link_target="$(readlink "$SYMLINK_TARGET" || true)"
    if [[ "$link_target" == "$FVM_DIR_BIN/fvm" ]]; then
      fvm_found=true
      info "Found FVM symlink: $SYMLINK_TARGET"
    else
      warn "Skipping symlink removal: $SYMLINK_TARGET points to '$link_target'"
    fi
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
  
  # Remove symlink (only if it points to our install)
  if [[ -L "$SYMLINK_TARGET" ]]; then
    local link_target
    link_target="$(readlink "$SYMLINK_TARGET" || true)"
    if [[ "$link_target" == "$FVM_DIR_BIN/fvm" ]]; then
      info "Removing FVM symlink..."
      remove_symlink "$SYMLINK_TARGET"
      success "Removed $SYMLINK_TARGET"
    fi
  fi
  
  # Notify about PATH cleanup
  warn "Note: FVM PATH entries may still exist in your shell config files:"
  log "  - ~/.bashrc"
  log "  - ~/.zshrc"
  log "  - ~/.config/fish/config.fish"
  log ""
  log "To remove them, search for lines containing '$FVM_DIR_BIN' in these files."
  
  success "FVM has been uninstalled!"
}

# Execute uninstall
uninstall_fvm