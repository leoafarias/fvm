# Local GitHub Actions Testing with `act`

This document provides a comprehensive guide for testing GitHub Actions workflows locally using the `act` tool, specifically for the FVM install script testing workflow.

## Overview

The `act` tool allows you to run GitHub Actions workflows locally using Docker containers, providing fast feedback without consuming GitHub Actions minutes or requiring commits/pushes for testing.

## Installation

### Prerequisites
- Docker installed and running
- Linux/macOS/WSL environment

### Install `act`
```bash
# Install act using the official installer
curl -fsSL https://raw.githubusercontent.com/nektos/act/master/install.sh | sudo bash

# Move to system PATH
sudo mv ./bin/act /usr/local/bin/act

# Verify installation
act --version
```

## Configuration

### Create `.actrc` Configuration File
```bash
# Create act configuration in project root
cat > .actrc << 'EOF'
# Use medium-sized Ubuntu image for better compatibility
-P ubuntu-latest=catthehacker/ubuntu:act-latest
-P ubuntu-22.04=catthehacker/ubuntu:act-22.04

# Use self-hosted for macOS simulation (runs on host system)
-P macos-latest=-self-hosted
-P macos-13=-self-hosted
-P macos-12=-self-hosted

# Enable offline mode for faster testing
--action-offline-mode

# Use host network for better connectivity
--network host

# Container architecture
--container-architecture linux/amd64
EOF
```

## Testing Capabilities

### ✅ What Works Well with `act`

1. **Script Quality Validation**
   - Shellcheck validation
   - Bash syntax checking
   - File consistency verification
   - Code quality checks

2. **Matrix Configuration Testing**
   - Validates matrix strategy syntax
   - Tests matrix variable expansion
   - Verifies job configuration

3. **Shell Environment Setup**
   - Tests shell installation (bash, zsh, fish)
   - Validates config file creation
   - Verifies directory structure setup

4. **Install Script Logic**
   - Tests helper functions (tildify, update_shell_config)
   - Validates OS/architecture detection
   - Tests input validation logic

### ⚠️ Limitations

1. **Root User Restriction**
   - Docker containers run as root by default
   - FVM install script prevents root execution (security feature)
   - Cannot test actual FVM installation in `act`

2. **macOS Simulation**
   - `act` cannot truly simulate macOS runners
   - Uses `-self-hosted` mode (runs on actual host)
   - Limited to Ubuntu simulation for most tests

3. **Network Dependencies**
   - Some tests may fail due to network restrictions
   - GitHub API calls may behave differently

## Usage Examples

### Test Specific Workflow
```bash
# List all workflows
act --list

# Test specific workflow file
act -W .github/workflows/install-script-test.yml --list

# Test specific job
act -W .github/workflows/install-script-test.yml -j test-script-quality

# Dry run (validate without execution)
act -W .github/workflows/install-script-test.yml --dryrun
```

### Test Matrix Configurations
```bash
# Test specific matrix combination
act -W .github/workflows/install-script-test.yml -j test-multi-shell \
    --matrix os:ubuntu-latest --matrix shell:bash

# Test all matrix combinations (dry run)
act -W .github/workflows/install-script-test.yml -j test-multi-shell --dryrun
```

### Debug Workflow Issues
```bash
# Run with verbose output
act -W .github/workflows/install-script-test.yml -j test-script-quality --verbose

# Run without pulling images (use cached)
act -W .github/workflows/install-script-test.yml --pull=false

# Run with custom event
act push -e event.json
```

## Workflow Issues Identified and Fixed

### Issue 1: Matrix Configuration Error

**Problem**: Original matrix created Cartesian product but variables were undefined.

**Original (Broken)**:
```yaml
strategy:
  matrix:
    os: [ubuntu-latest, macos-latest]
    shell: [bash, zsh, fish]
    include:
      - os: ubuntu-latest
        shell: bash
        config_file: ~/.bashrc
```

**Fixed**:
```yaml
strategy:
  matrix:
    include:
      - os: ubuntu-latest
        shell: bash
        config_file: ~/.bashrc
      - os: ubuntu-latest
        shell: zsh
        config_file: ~/.zshrc
      # ... etc
```

### Issue 2: Shell Environment Setup

**Problem**: Directory creation failed for some shell config files.

**Solution**: Enhanced setup with proper directory creation:
```yaml
- name: Setup shell environment
  run: |
    config_file="${{ matrix.config_file }}"
    config_dir="$(dirname "$config_file")"
    mkdir -p "$config_dir"
    touch "$config_file"
```

## Testing Results

### ✅ Successful Tests
- **Script Quality**: Shellcheck, syntax, consistency ✅
- **Matrix Configuration**: All variables properly defined ✅
- **Shell Environment**: bash, zsh, fish installation ✅
- **Install Script Logic**: Helper functions work correctly ✅
- **OS/Architecture Detection**: Proper platform detection ✅

### ❌ Expected Limitations
- **Full Install Test**: Fails due to root user restriction (expected)
- **macOS Simulation**: Limited to self-hosted mode
- **Network Dependencies**: Some API calls may behave differently

## Best Practices

### 1. Use Dry Runs for Quick Validation
```bash
# Quick syntax and configuration check
act -W .github/workflows/install-script-test.yml --dryrun
```

### 2. Test Individual Components
```bash
# Test only quality checks (fast)
act -W .github/workflows/install-script-test.yml -j test-script-quality

# Test specific matrix combination
act --matrix os:ubuntu-latest --matrix shell:bash
```

### 3. Use Offline Mode for Speed
```bash
# Add to .actrc for faster testing
--action-offline-mode
```

### 4. Debug with Verbose Output
```bash
# Get detailed execution information
act --verbose
```

## Integration with Development Workflow

### Pre-commit Testing
```bash
#!/bin/bash
# .git/hooks/pre-commit
echo "Testing workflows with act..."
act -W .github/workflows/install-script-test.yml -j test-script-quality --quiet
```

### CI/CD Pipeline Validation
```bash
# Validate workflow changes before pushing
act --dryrun --quiet && echo "✅ Workflows valid" || echo "❌ Workflow issues found"
```

## Troubleshooting

### Common Issues

1. **Docker Permission Errors**
   ```bash
   # Add user to docker group
   sudo usermod -aG docker $USER
   # Restart shell or logout/login
   ```

2. **Image Pull Failures**
   ```bash
   # Use offline mode if images are cached
   act --action-offline-mode
   ```

3. **Matrix Variable Undefined**
   ```bash
   # Check matrix configuration syntax
   act --dryrun --verbose
   ```

### Debug Commands
```bash
# Check act configuration
act --help

# List available workflows
act --list

# Validate specific workflow
act -W path/to/workflow.yml --dryrun
```

## Conclusion

The `act` tool provides excellent local testing capabilities for GitHub Actions workflows, particularly for:
- Workflow syntax validation
- Matrix configuration testing  
- Shell environment setup verification
- Script logic validation

While it has limitations (root user restriction, macOS simulation), it significantly speeds up the development cycle by providing immediate feedback on workflow changes without requiring commits or consuming GitHub Actions minutes.

The install script improvements and workflow fixes identified through local testing ensure robust cross-platform compatibility when deployed to actual GitHub Actions runners.
