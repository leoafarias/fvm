---
title: Install Command
---

# Install

Installs a specified Flutter SDK version to your machine and caches it for future use. 

## Usage

```bash
> fvm install [version]
```

Without `[version]`, installs the version specified in the project's FVM settings.

## Options

- `-s, --setup`: Builds the SDK post-installation for immediate readiness.

## Examples

**Installing a Specific Version**:  
To install Flutter SDK version `2.5.0`, you would use:

```bash
fvm install 2.5.0
```

**Installing with Automatic Setup**:  
If you want FVM to perform setup tasks after installation (like downloading dependencies), use the `--setup` flag:

```bash
fvm install 2.5.0 --setup
```

**Installing from Project Configuration**:  
If you run `fvm install` within a Flutter project that already has an FVM configuration, it will install the version specified in that configuration:

```bash
fvm install
```
