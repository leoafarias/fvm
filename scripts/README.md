# FVM Scripts

This directory contains installation and testing scripts for FVM.

## Scripts

### install.sh
The main FVM installation script for Linux/macOS that:
- Detects OS and architecture (including musl/Alpine support)
- Downloads the appropriate FVM binary
- Installs to `~/.fvm_flutter/bin` (customizable with `FVM_DIR`)
- Configures shell PATH automatically (skip with `FVM_NO_PATH`)
- Supports container environments (Docker, Podman, CI)
- Handles macOS Rosetta detection
- Accepts version with or without `v` prefix

Usage:
```bash
# Install latest version
curl -fsSL https://fvm.app/install.sh | bash

# Install specific version (with or without v prefix)
curl -fsSL https://fvm.app/install.sh | bash -s 3.2.1
curl -fsSL https://fvm.app/install.sh | bash -s v3.2.1

# Custom installation directory
FVM_DIR=/opt/fvm ./install.sh

# Skip automatic PATH configuration
FVM_NO_PATH=true ./install.sh

# Container/CI support
export FVM_ALLOW_ROOT=true
./install.sh
```

### uninstall.sh
Separate script to remove FVM installation:
- Removes `~/.fvm_flutter` directory
- Cleans up old symlinks from previous versions
- Provides guidance for PATH cleanup

Usage:
```bash
# Uninstall FVM
curl -fsSL https://fvm.app/uninstall.sh | bash
# or
./scripts/uninstall.sh
```

### validate_install.sh
Validation script that tests the install script against real FVM releases:
- Downloads actual release archives
- Verifies cli_pkg structure handling
- Tests version detection method
- Validates extraction logic

Usage:
```bash
./scripts/validate_install.sh
```

### smoke-test.sh
Quick pre-push validation for install.sh changes:
- Basic installation test
- Dangerous path rejection
- Reinstall/upgrade check
- Fast (~5 seconds), no external dependencies

Usage:
```bash
./scripts/smoke-test.sh
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

### test-workflows.sh
Helper script to run GitHub Actions workflows locally using `act`:
- Tests workflows before pushing
- Supports dry-run mode
- Can run specific jobs or full workflows

Usage:
```bash
# List all workflows
./scripts/test-workflows.sh -l

# Run specific workflow
./scripts/test-workflows.sh -w test-install.yml

# Run specific job
./scripts/test-workflows.sh -w test-install.yml -j validate

# Dry run
./scripts/test-workflows.sh -w test-install.yml --dry-run
```

### install.md
Documentation for the installation process.

## Design Principles

All scripts follow:
- **KISS**: Simple, straightforward logic
- **DRY**: No code duplication
- **YAGNI**: Only essential features
- **Security**: Safe defaults with escape hatches for containers