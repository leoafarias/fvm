---
title: Global Command
---

## Global

The `global` command in FVM (Flutter Version Management) is used to set a specific Flutter SDK version as the global version on your machine. This command is essential for defining a default Flutter SDK version for use across all Flutter projects that do not have a project-specific version set through FVM.

## Usage

```bash
> fvm global [version]
```

`[version]`: Flutter SDK version you want to set as the global version.


## Examples

**Setting a Global Version**:  
To set Flutter SDK version `2.5.0` as your global version, you would run:

```bash
fvm global 2.5.0
```

**Unlinking the Global Version**:
To unlink the global version, you can run:

```bash
fvm global --unlink
```
