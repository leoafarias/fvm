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

### test-install-arch.sh
Deterministic regression test for install target selection:
- Verifies macOS Rosetta-aware arm64 detection
- Verifies Linux architecture mapping and unsupported-arch failures
- Avoids downloads by stubbing `uname`, `sysctl`, `curl`, and `tar`

Usage:
```bash
./scripts/test-install-arch.sh
```

### install.ps1
PowerShell installation script for Windows.

### install.md
Documentation for the installation process.

### manual-migration-test.sh
One-command validation for legacy git-cache migration to a bare mirror.

What it validates:
- Seeds a legacy cache with `fvm 4.0.1` (`stable`, one stable release, `beta`)
- Confirms pre-migration non-bare cache and legacy alternates paths
- Triggers migration through `dart run bin/main.dart install stable`
- Confirms bare cache and rewritten alternates
- Verifies `list` output and SDK executability

Usage:
```bash
# Default run (isolated cache in .context/tmp)
./scripts/manual-migration-test.sh

# Specify release version explicitly
./scripts/manual-migration-test.sh --release-version 3.41.3

# Remove test cache at the end
./scripts/manual-migration-test.sh --cleanup
```

## Design Principles

All scripts follow:
- **KISS**: Simple, straightforward logic
- **DRY**: No code duplication
- **YAGNI**: Only essential features
- **Security**: Safe defaults with escape hatches for containers
