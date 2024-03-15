---
title: Use Command
---

# Use

Sets a specific Flutter SDK version for a project, ensuring environment consistency or meeting project-specific SDK needs.

## Usage

```bash
> fvm use [version] [options]
```

`version`: Desired Flutter SDK version (e.g., `2.2.3`) or channel (e.g., `stable`).

## Options

- `-f, --force`:  Bypasses Flutter project checks, assuming version compatibility.

- `-p, --pin`: Pins the latest release of a specified channel.

- `--flavor`: Specifies the SDK version for a particular project flavor in multi-flavored projects.

- `-s,--skip-setup`:  Omits Flutter setup post-installation for expedited process.

- `--skip-pub-get`: Skip resolving dependencies (`flutter pub get`) after switching Flutter SDK.

## Examples

**Setting a Specific Version**:  
To set your project to use Flutter version `2.2.3`, you would run:

```bash
fvm use 2.2.3
```

**Using a Channel**:  
To use the latest stable channel version, you can run:

```bash
fvm use stable
```

If you want to pin this channel to its current latest release, use the `--pin` flag:

```bash
fvm use stable -p
```

**Using a commit hash**:

You are able to install and bind a specific framework revision by providing the git commit or short hash.

```bash
# Short hash
fvm use fa345b1
# Long hash
fvm use 476ad8a917e64e345f05e4147e573e2a42b379f9
```

**Forcing a Version**:  
If you need to set a version without performing the usual project checks, use the `--force` flag:

```bash
fvm use 2.2.3 --force
```

**Setting a Version for a Specific Flavor**:  
For a project with multiple flavors, set a version for a specific flavor like this:

```bash
fvm use 2.2.3 --flavor production
```

**Using a Flavor**
To switch to a specific flavor, you can use the `use` command with the name of the flavor:

```bash
fvm use production
```
