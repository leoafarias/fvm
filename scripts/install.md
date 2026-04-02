# FVM Installation Guide

## Install on macOS and Linux

### Quick Install (Latest Version)

```bash
curl -fsSL https://fvm.app/install.sh | bash
```

Note: The installer cannot modify your current shell PATH when run as a separate
process (e.g., `curl | bash`). For CI or same-step usage, add:

```bash
export PATH="$HOME/fvm/bin:$PATH"
```

### Install Specific Version

```bash
curl -fsSL https://fvm.app/install.sh | bash -s 3.2.1
```

### Container/CI Installation

For Docker, Podman, or CI environments:

```bash
export FVM_ALLOW_ROOT=true
curl -fsSL https://fvm.app/install.sh | bash
```

For same-step usage, add:

```bash
export PATH="$HOME/fvm/bin:$PATH"
```

For later steps, persist PATH using your CI's env file mechanism
(e.g., `$GITHUB_PATH` on GitHub Actions, `$BASH_ENV` on CircleCI).

### Uninstall

```bash
curl -fsSL https://fvm.app/install.sh | bash -s -- --uninstall
```

## Install on Windows

### Chocolatey

```bash
choco install fvm
```

## Features

- **PATH instructions** for bash, zsh, and fish shells
- **Container support** with security safeguards
- **Version validation** and error handling
- **Unified install/uninstall** in a single script
- **Cross-platform** support (macOS, Linux, Windows)
