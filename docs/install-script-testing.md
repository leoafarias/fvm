# Install Script Testing Documentation

This document provides comprehensive information about the FVM install script testing infrastructure, validation results, and workflow analysis.

## Overview

The FVM install script (`scripts/install.sh`) is a critical component that handles cross-platform installation of FVM (Flutter Version Management). This document covers the testing approach, validation results, and workflow configuration.

## Install Script Features

### Core Functionality
- **Cross-platform support**: Linux and macOS with automatic OS/architecture detection
- **User-level installation**: Installs to `~/.fvm_flutter/bin` with system-wide symlink to `/usr/local/bin/fvm`
- **Multi-shell support**: Automatically configures PATH for bash, zsh, and fish shells
- **Security-first**: Prevents root execution while requiring minimal privilege escalation
- **Clean installation**: Always overwrites existing installations for consistency

### Installation Behavior
- **Always overwrites**: Follows DRY, YAGNI, KISS principles - no complex version comparison
- **Detects existing installations**: Shows current version but always proceeds with installation
- **Smart shell configuration**: Only adds PATH entries if not already present
- **Self-healing**: Clean slate approach eliminates edge cases from previous installations

## Testing Infrastructure

### GitHub Actions Workflow
The install script is tested via `.github/workflows/install-script-test.yml` with multiple test jobs:

#### 1. Script Quality Tests ✅
- **Shellcheck validation**: Static analysis for shell script best practices
- **Syntax checking**: Bash syntax validation
- **Consistency verification**: Ensures public and development versions match

#### 2. Multi-Shell Support Tests
- **Matrix testing**: 6 combinations (ubuntu/macos × bash/zsh/fish)
- **Shell installation**: Verifies each shell can be installed and configured
- **PATH configuration**: Tests shell-specific export syntax
- **FVM execution**: Validates FVM can be executed in each shell environment

### Local Testing with `act`
- **Local workflow execution**: Test GitHub Actions workflows locally using Docker
- **Fast feedback**: Validate changes without consuming GitHub Actions minutes
- **Matrix validation**: Test complex matrix configurations safely
- **Configuration**: `.actrc` file with optimized platform mappings

## Validation Results

### ✅ Working Components
1. **Script Quality**: All shellcheck, syntax, and consistency checks pass
2. **Install Script Logic**: All helper functions and core logic validated
3. **Matrix Configuration**: All 6 shell/OS combinations properly defined
4. **Shell Installation**: bash, zsh, fish install correctly across platforms
5. **OS/Architecture Detection**: Proper platform detection for downloads

### ⚠️ Known Limitations
1. **Root User Restriction**: Cannot test actual FVM installation in Docker (security feature)
2. **macOS Simulation**: Limited to self-hosted mode in `act` tool
3. **Network Dependencies**: Some API calls may behave differently in local testing

### 🔧 Workflow Issue Identified
**Shell Environment Setup**: The workflow has a tilde expansion issue in the "Setup shell environment" step:

```yaml
# Current (problematic)
touch "${{ matrix.config_file }}"  # ~/ not expanded in Docker

# Fix needed
config_file="${{ matrix.config_file }}"
config_file="${config_file/#\~/$HOME}"  # Expand tilde to $HOME
mkdir -p "$(dirname "$config_file")"
touch "$config_file"
```

## Install Script Architecture

### Security Model
- **Non-root execution**: Prevents dangerous root installations
- **Minimal privilege escalation**: Only requires sudo for `/usr/local/bin` symlink
- **User-level directory**: Primary installation in `~/.fvm_flutter/bin`

### Shell Integration
- **Automatic detection**: Uses `$SHELL` environment variable
- **Shell-specific syntax**: Proper export commands for each shell type
- **Idempotent configuration**: Safe to run multiple times without duplication

### Error Handling
- **Comprehensive validation**: Checks for required tools and permissions
- **Clear error messages**: Descriptive failures with actionable guidance
- **Graceful degradation**: Manual instructions when automatic config fails

## Testing Commands

### Local Testing with act
```bash
# Test script quality (always works)
act -W .github/workflows/install-script-test.yml -j test-script-quality

# Validate matrix configuration
act -W .github/workflows/install-script-test.yml -j test-multi-shell --dryrun

# Test specific shell combination
act --matrix os:ubuntu-latest --matrix shell:bash

# List all available workflows
act --list
```

### Manual Testing
```bash
# Shellcheck validation
shellcheck scripts/install.sh

# Syntax checking
bash -n scripts/install.sh

# Consistency verification
diff scripts/install.sh docs/public/install.sh
```

## Development Workflow

### Making Changes
1. **Modify install script**: Update `scripts/install.sh`
2. **Update public version**: Sync `docs/public/install.sh`
3. **Local validation**: Run `act` tests to validate changes
4. **Commit and push**: GitHub Actions will run full test suite

### Best Practices
- **Test locally first**: Use `act` to catch issues before pushing
- **Maintain consistency**: Keep public and development versions in sync
- **Follow shell standards**: Use shellcheck recommendations
- **Document changes**: Update this file for significant modifications

## Troubleshooting

### Common Issues
1. **Shellcheck warnings**: Fix with proper quoting and variable usage
2. **Matrix configuration errors**: Ensure all combinations have required variables
3. **Shell environment failures**: Check tilde expansion and directory creation
4. **Docker permission errors**: Ensure user is in docker group for `act`

### Debug Commands
```bash
# Verbose act output
act --verbose

# Check act configuration
act --help

# Validate specific workflow
act -W path/to/workflow.yml --dryrun
```

## Conclusion

The FVM install script follows excellent engineering principles with a simple, reliable approach to cross-platform installation. The testing infrastructure provides comprehensive validation while the local testing capability with `act` enables rapid development iteration.

The script's "always overwrite" behavior is intentional and follows DRY, YAGNI, KISS principles, providing predictable and reliable installations across all supported platforms and shell environments.
