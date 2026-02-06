# FVM Scripts

This directory contains testing and utility scripts for FVM.

## Installation Scripts

The main installation scripts (`install.sh` and `uninstall.sh`) are located in `docs/public/` and served at https://fvm.app/install.sh.

Usage:
```bash
# Install latest version
curl -fsSL https://fvm.app/install.sh | bash

# Install specific version
curl -fsSL https://fvm.app/install.sh | bash -s 3.2.1

# Uninstall FVM
./docs/public/install.sh --uninstall
```

## Scripts in This Directory

### test-install.sh
Test script for the installation logic:
- Tests root warning behavior
- Validates security (warns root in regular environments)

Usage:
```bash
# Test as regular user
./scripts/test-install.sh

# Test all scenarios (requires root)
sudo ./scripts/test-install.sh
```

### install.ps1
PowerShell installation script for Windows.

### install.md
Documentation for the installation process.

## Design Principles

All scripts follow:
- **KISS**: Simple, straightforward logic
- **DRY**: No code duplication
- **YAGNI**: Only essential features
- **Security**: Safe defaults with escape hatches for containers
