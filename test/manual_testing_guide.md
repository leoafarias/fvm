# FVM Manual Testing Guide

This guide provides a step-by-step approach for manually testing Flutter version format handling and fork functionality in FVM. Follow these steps to verify that the application correctly processes all supported version formats.

## Setup

1. Ensure you have FVM installed.
2. Clone this repository and navigate to the project directory.
3. Run `dart pub get` to install dependencies.

## Test Scenarios

### 1. Channel Installation Tests

Run these commands and verify that each successfully installs the specified channel:

```bash
# Install stable channel
fvm install stable

# Install beta channel
fvm install beta

# Install dev channel
fvm install dev

# Install master channel
fvm install master

# List installed versions to verify
fvm list
```

### 2. Semantic Version Tests

Test installing specific versions with and without the 'v' prefix:

```bash
# Install specific version (choose a recent Flutter version)
fvm install 2.10.0

# Install version with 'v' prefix 
fvm install v2.10.0

# Install pre-release version
fvm install 2.10.0-beta.1

# Install pre-release with 'v' prefix
fvm install v2.10.0-beta.1

# List installed versions to verify
fvm list
```

### 3. Version with Channel Tests

Test installing versions from specific channels:

```bash
# Install version from beta channel
fvm install 2.10.0@beta

# Install version from dev channel
fvm install 2.10.0@dev

# Install version with 'v' prefix from beta channel
fvm install v2.10.0@beta

# List installed versions to verify
fvm list
```

### 4. Git Commit Tests

Test installing from specific git commits:

```bash
# Install from short git commit (use a valid commit hash)
fvm install f4c74a6ec3

# Install from full git commit (use a valid commit hash)
fvm install de25def7784a2e63a9e7d5cc50dff84db8f69298

# List installed versions to verify
fvm list
```

### 5. Custom Version Tests

Test creating and using custom versions:

```bash
# Create a custom version (this will duplicate an existing version)
# create custom_test_ver in cache versions directory

# List installed versions to verify
fvm list
```

### 6. Fork Tests

Test fork functionality:

```bash
# Add a fork
fvm fork add flock https://github.com/join-the-flock/flock

# List forks to verify
fvm fork list

# Install from fork with stable channel
fvm install flock/stable

# Install from fork with specific version
fvm install flock/2.10.0

# Install from fork with version and channel
fvm install flock/2.10.0@beta

# Install from fork with git commit
fvm install flock/f4c74a6ec3

# Remove the fork
fvm fork remove flock

# Verify fork was removed
fvm fork list
```

### 7. Error Cases

Test that the application properly handles error cases:

```bash
# Invalid channel
fvm install 2.10.0@invalid

# Custom version with fork (should fail)
fvm fork add flock https://github.com/join-the-flock/flock
fvm install flock/custom_build
fvm fork remove flock

# Custom version with channel (should fail)
fvm install custom_build@beta

# Non-existent fork
fvm install unknown-fork/stable
```

## Expected Results

For each test case, verify:

1. **Success cases:** The command completes without errors and the version is correctly installed and listed.
2. **Error cases:** The application displays an appropriate error message explaining why the command failed.
3. **Version properties:** When a version is installed, check that it appears correctly in `fvm list` output and has the expected properties.

## Verification

After running these tests, you should have verified that:

1. All standard version formats are correctly parsed and installed
2. Fork functionality works as expected
3. Error handling provides clear and helpful messages
4. The application maintains backward compatibility with older version formats

Document any issues encountered during testing and report them with clear steps to reproduce.

## Cleanup

After testing, you can clean up by removing test installations:

```bash
# Remove test versions
fvm remove stable
fvm remove beta
fvm remove dev
fvm remove master
# ... and any other versions you installed
``` 