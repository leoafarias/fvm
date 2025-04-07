# Flutter Version Manager (FVM) - User Input Testing Guide

This document provides a comprehensive guide to the various version formats supported by FVM, with examples and expected behaviors. This information is useful for both user testing and to understand what version formats are valid when using the tool.

## Basic Version Formats

FVM supports several version formats that can be used with commands like `fvm install`.

### 1. Channel Versions

Flutter's official release channels can be installed directly by name:

| Input Format | Example       | Description                         | Usage                      |
|--------------|---------------|-------------------------------------|----------------------------|
| `<channel>`  | `stable`      | Official stable channel             | `fvm install stable`       |
| `<channel>`  | `beta`        | Official beta channel               | `fvm install beta`         |
| `<channel>`  | `dev`         | Official dev channel                | `fvm install dev`          |
| `<channel>`  | `master`      | Official master channel             | `fvm install master`       |

### 2. Semantic Versions

FVM supports standard semantic versioning:

| Input Format | Example       | Description                         | Usage                      |
|--------------|---------------|-------------------------------------|----------------------------|
| `<version>`  | `2.10.0`      | Specific Flutter version            | `fvm install 2.10.0`       |
| `v<version>` | `v2.10.0`     | Version with 'v' prefix             | `fvm install v2.10.0`      |
| `<version>-<pre>` | `2.10.0-beta.1` | Pre-release version          | `fvm install 2.10.0-beta.1`|
| `v<version>-<pre>` | `v2.10.0-beta.1` | Pre-release with 'v' prefix | `fvm install v2.10.0-beta.1` |

### 3. Git References

FVM can install from specific git commits:

| Input Format | Example       | Description                         | Usage                      |
|--------------|---------------|-------------------------------------|----------------------------|
| `<commit>`   | `f4c74a6ec3`  | Short git commit hash               | `fvm install f4c74a6ec3`   |
| `<full-commit>` | `de25def7784a2e63a9e7d5cc50dff84db8f69298` | Full git commit hash | `fvm install de25def7784a2e63a9e7d5cc50dff84db8f69298` |

### 4. Version with Channel

You can specify a version to be installed from a specific channel:

| Input Format | Example       | Description                         | Usage                      |
|--------------|---------------|-------------------------------------|----------------------------|
| `<version>@<channel>` | `2.10.0@beta` | Version from beta channel  | `fvm install 2.10.0@beta`  |
| `<version>@<channel>` | `2.10.0@dev`  | Version from dev channel   | `fvm install 2.10.0@dev`   |
| `v<version>@<channel>` | `v2.10.0@beta` | Version with 'v' from beta | `fvm install v2.10.0@beta` |

### 5. Custom Versions

FVM allows for custom named versions:

| Input Format | Example       | Description                         | Usage                      |
|--------------|---------------|-------------------------------------|----------------------------|
| `custom_<name>` | `custom_my_build` | Custom named version        | `fvm install custom_my_build` |

## Forked Flutter Repositories

FVM supports installation from forked Flutter repositories. Forks must be configured first using the `fvm fork` command.

### 1. Setting Up Forks

| Command Format | Example       | Description                         | 
|--------------|---------------|-------------------------------------|
| `fvm fork add <name> <url>` | `fvm fork add my-fork https://github.com/username/flutter.git` | Adds a fork |
| `fvm fork list` | `fvm fork list` | Lists all configured forks |
| `fvm fork remove <name>` | `fvm fork remove my-fork` | Removes a fork |

### 2. Installing from Forks

After setting up a fork, you can use it with any of the version patterns:

| Input Format | Example       | Description                         | Usage                      |
|--------------|---------------|-------------------------------------|----------------------------|
| `<fork>/<channel>` | `my-fork/stable` | Fork's stable channel      | `fvm install my-fork/stable` |
| `<fork>/<version>` | `my-fork/2.10.0` | Specific version from fork | `fvm install my-fork/2.10.0` |
| `<fork>/<commit>` | `my-fork/f4c74a6ec3` | Specific commit from fork | `fvm install my-fork/f4c74a6ec3` |
| `<fork>/<version>@<channel>` | `my-fork/2.10.0@beta` | Version from fork's beta channel | `fvm install my-fork/2.10.0@beta` |

## Error Cases and Validation

FVM validates the input formats and will return appropriate error messages for invalid inputs:

| Invalid Input | Example       | Error Message                      |
|--------------|---------------|-------------------------------------|
| Invalid format | `2.10.0@invalid` | "Invalid channel: invalid"    |
| Invalid custom version | `my-fork/custom_build` | "Custom versions cannot have fork or channel specifications" |
| Non-existent fork | `unknown-fork/stable` | "Fork 'unknown-fork' not found in configuration" |

## Testing Scenarios

When testing FVM, users should try these specific scenarios to verify the application handles all formats correctly:

1. **Basic channel installation**: Install each of the official channels (stable, beta, dev, master)
2. **Specific version installation**: Install versions with and without the 'v' prefix
3. **Version with channel**: Install a specific version from a specific channel
4. **Git commit installation**: Install from short and full commit hashes
5. **Custom version creation**: Create and use a custom named version
6. **Fork operations**: Add, list, and remove forks
7. **Fork installation**: Install various version formats from a configured fork
8. **Error handling**: Attempt to use invalid formats and verify error messages

## Version Properties and Behaviors

After installing a version, verify these properties are correctly identified:

| Property | Expected Behavior |
|----------|-------------------|
| `isChannel` | True for channel versions (stable, beta, dev, master) |
| `isRelease` | True for semantic versions (e.g., 2.10.0, v2.10.0) |
| `isUnknownRef` | True for git commit references |
| `isCustom` | True for custom versions (custom_*) |
| `isMain` | True only for 'master' channel |
| `fromFork` | True for any version installed from a fork |
| `version` | Returns the pure version part without channel or fork information |

## Complete Test Matrix

For thorough testing, users should verify each of these combinations:

1. All 4 channels (stable, beta, dev, master)
2. Semantic versions (with and without 'v' prefix)
3. Pre-release versions
4. Git commit references (short and full)
5. Versions with channel specifications
6. Custom versions
7. Fork installations with all of the above

This ensures all parsing edge cases are covered and the functionality works as expected. 