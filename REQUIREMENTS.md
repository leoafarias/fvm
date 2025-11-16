# FVM Installation Requirements

## Overview
This document outlines the requirements for installing FVM (Flutter Version Management) from GitHub releases.

## Version Information
- **Current Latest Version**: 4.0.0 (or later)
- **Version Parameter**: Can be passed as argument (e.g., `3.2.1`, `4.0.0`)
- **Version Format**: Accepts `x.y.z` or `vx.y.z` format (normalized to `x.y.z`)
- **Release Location**: https://github.com/leoafarias/fvm/releases

## Download Information

### Binary URL Pattern
```
https://github.com/leoafarias/fvm/releases/download/{VERSION}/fvm-{VERSION}-{OS}-{ARCH}{LIBC_VARIANT}.tar.gz
```

### Supported Operating Systems
- **Linux** (`linux`)
- **macOS** (`macos`)

### Supported Architectures
- **x64** (x86_64) - Intel/AMD 64-bit processors
- **arm64** (aarch64) - ARM 64-bit processors (Apple Silicon, modern ARM devices)
- **arm** (armv7l, armv6l) - 32-bit ARM processors
- **riscv64** (riscv64gc) - RISC-V 64-bit processors

### Linux libc Variants
- **glibc** (default, no suffix) - Standard Linux
- **musl** (`-musl` suffix) - Alpine Linux and musl-based distributions

### Example Download URLs
```
# macOS ARM64 (Apple Silicon)
https://github.com/leoafarias/fvm/releases/download/4.0.0/fvm-4.0.0-macos-arm64.tar.gz

# macOS x64 (Intel)
https://github.com/leoafarias/fvm/releases/download/4.0.0/fvm-4.0.0-macos-x64.tar.gz

# Linux x64 (glibc)
https://github.com/leoafarias/fvm/releases/download/4.0.0/fvm-4.0.0-linux-x64.tar.gz

# Linux x64 (musl/Alpine)
https://github.com/leoafarias/fvm/releases/download/4.0.0/fvm-4.0.0-linux-x64-musl.tar.gz

# Linux ARM64
https://github.com/leoafarias/fvm/releases/download/4.0.0/fvm-4.0.0-linux-arm64.tar.gz

# Linux ARM64 (musl/Alpine)
https://github.com/leoafarias/fvm/releases/download/4.0.0/fvm-4.0.0-linux-arm64-musl.tar.gz

# Linux ARM (32-bit)
https://github.com/leoafarias/fvm/releases/download/4.0.0/fvm-4.0.0-linux-arm.tar.gz

# Linux RISC-V 64
https://github.com/leoafarias/fvm/releases/download/4.0.0/fvm-4.0.0-linux-riscv64.tar.gz
```

## Installation Directory Structure

### Primary Installation Directory
```
$HOME/.fvm_flutter/
├── bin/
│   ├── fvm                    # Main FVM binary
│   └── [other dependencies]   # Additional files from tarball
└── temp_extract/              # Temporary extraction directory (removed after install)
```

### Binary Location
- **User Installation**: `$HOME/.fvm_flutter/bin/fvm`
- **System Installation** (optional, requires sudo): `/usr/local/bin/fvm`

### Shell Configuration
The installer modifies shell configuration files to add FVM to PATH:
- **Bash**: `~/.bashrc` or `~/.bash_profile`
- **Zsh**: `~/.zshrc`
- **Fish**: `~/.config/fish/config.fish`

PATH addition:
```bash
export PATH="$HOME/.fvm_flutter/bin:$PATH"
```

## Tarball Structure

The downloaded `.tar.gz` file can have two possible structures:

### New Structure (Preferred)
```
fvm/
├── fvm              # Binary
└── [dependencies]   # Additional files
```

### Legacy Structure
```
fvm                  # Binary at root
```

## Installation Process (High-Level)

1. **Detect** OS and architecture
2. **Determine** version (latest or specified)
3. **Construct** download URL
4. **Download** tarball from GitHub releases
5. **Validate** tarball integrity
6. **Extract** to temporary directory
7. **Move** contents to `$HOME/.fvm_flutter/bin/`
8. **Configure** shell PATH (optional)
9. **Install** system-wide copy (optional, requires sudo)

## System Requirements

### Required Tools
- `curl` - For downloading binaries
- `tar` - For extracting archives
- `bash` - For running installer

### Optional Tools
- `sudo` or `doas` - For system-wide installation (--system flag)

## Installation Modes

### User Installation (Default)
- Installs to `$HOME/.fvm_flutter/bin/`
- Requires PATH configuration
- No elevated privileges needed

### System Installation (--system flag)
- Copies binary to `/usr/local/bin/fvm`
- Requires sudo/doas
- Available system-wide without PATH modification

## Notes

- The installer does NOT create symlinks (legacy behavior removed)
- The installer copies the binary for system installation
- Root execution is blocked except in containers/CI (requires `FVM_ALLOW_ROOT=true`)
- Version lookup uses GitHub redirect to avoid API rate limits
- The installer handles read-only shell configuration files gracefully
