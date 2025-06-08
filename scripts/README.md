# FVM Scripts

This directory contains installation and testing scripts for FVM.

## Scripts

### install.sh
The main FVM installation script for Linux/macOS that:
- Detects OS and architecture
- Downloads the appropriate FVM binary
- Creates a system-wide symlink
- Configures shell PATH
- Supports container environments (Docker, Podman, CI)

Usage:
```bash
# Install latest version
curl -fsSL https://github.com/leoafarias/fvm/raw/main/scripts/install.sh | bash

# Install specific version
curl -fsSL https://github.com/leoafarias/fvm/raw/main/scripts/install.sh | bash -s 3.0.0
```

### install.ps1
PowerShell installation script for Windows.

### uninstall.sh
Uninstallation script that removes FVM and cleans up configuration.

### test-install.sh
Simple test script for the root detection logic:
- Tests container detection (Docker, Podman)
- Tests CI environment detection
- Tests manual override (FVM_ALLOW_ROOT)
- Validates security (blocks root in regular environments)

Usage:
```bash
# Test as regular user
./scripts/test-install.sh

# Test all scenarios (requires root)
sudo ./scripts/test-install.sh
```

### install.md
Documentation for the installation process.

## Design Principles

Both scripts follow:
- **KISS**: Simple, straightforward logic
- **DRY**: No code duplication
- **YAGNI**: Only essential features
- **Security**: Safe defaults with escape hatches for containers
