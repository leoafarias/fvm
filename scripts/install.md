# FVM Installation Guide

## Install on macOS and Linux

### Quick Install (Latest Version)

```bash
curl -fsSL https://fvm.app/install | bash
```

### Install Specific Version

```bash
curl -fsSL https://fvm.app/install | bash -s 3.2.1
```

### Container/CI Installation

For Docker, Podman, or CI environments:

```bash
export FVM_ALLOW_ROOT=true
curl -fsSL https://fvm.app/install | bash
```

### Uninstall

```bash
curl -fsSL https://fvm.app/install | bash -s -- --uninstall
```

## Install on Windows

### Chocolatey

```bash
choco install fvm
```

## Features

- **Automatic PATH configuration** for bash, zsh, and fish shells
- **Container support** with security safeguards
- **Version validation** and error handling
- **Unified install/uninstall** in a single script
- **Cross-platform** support (macOS, Linux, Windows)
