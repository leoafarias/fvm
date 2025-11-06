# FVM Scripts

This directory contains installation and testing scripts for FVM.

## Scripts

### install.sh
The main FVM installation script for Linux/macOS that:
- Detects OS and architecture
- Downloads the appropriate FVM binary
- Configures shell PATH
- Optionally copies the binary into /usr/local/bin via `--system`
- Supports container environments (Docker, Podman, CI)
- **Now includes uninstall functionality via `--uninstall` flag**

Usage:
```bash
# Install latest version
curl -fsSL https://fvm.app/install.sh | bash

# Install specific version
curl -fsSL https://fvm.app/install.sh | bash -s 3.2.1

# Uninstall FVM
./install.sh --uninstall

# Container/CI support
export FVM_ALLOW_ROOT=true
./install.sh
```

### test-install.sh
Test script for the installation logic:
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

All scripts follow:
- **KISS**: Simple, straightforward logic
- **DRY**: No code duplication
- **YAGNI**: Only essential features
- **Security**: Safe defaults with escape hatches for containers
