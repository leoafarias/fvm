# Flutter Version Parsing Implementation

This document provides a detailed technical explanation of the version parsing logic used in FVM's `FlutterVersion` model.

## Overview

FVM's version parsing system is designed to handle multiple formats of Flutter versions, including:

1. Channel versions (stable, beta, dev, master)
2. Semantic versions (2.10.0, v2.10.0)
3. Git commit references (short and full hashes)
4. Versions with specific channels (2.10.0@beta)
5. Custom versions (custom_*)
6. Forked repositories with any of the above formats (myfork/stable, myfork/2.10.0@beta)

The central component of this system is the `FlutterVersion.parse` factory method, which processes a version string input and returns the appropriate `FlutterVersion` instance.

## Implementation

### Pattern Matching Approach

The core of the implementation uses a regex pattern to match the expected format:

```dart
final pattern = RegExp(r'^(?:(?<fork>[^/]+)/)?(?<version>[^@]+)(?:@(?<channel>\w+))?$');
```

This pattern breaks down as follows:

- `(?:(?<fork>[^/]+)/)?`: Optional named capture group for fork prefix
- `(?<version>[^@]+)`: Required named capture group for the version string
- `(?:@(?<channel>\w+))?`: Optional named capture group for channel suffix

This approach allows us to handle all version formats in a unified way, extracting the relevant components for further processing.

### Component Processing

After extracting the components, the implementation:

1. Handles custom versions first, validating they don't have fork or channel specifications
2. Processes channel versions (stable, beta, dev, master)
3. Manages versions with channel specifications
4. Validates semantic versions, preserving the 'v' prefix if present
5. Treats unmatched patterns as git commit references

### Handling the 'v' Prefix

A key aspect of the implementation is handling the 'v' prefix in semantic versions:

```dart
// Try to parse as semantic version
try {
  // Create a version to check for validation only
  String checkVersion = versionPart;
  if (versionPart.startsWith('v')) {
    // Strip 'v' only for validation check
    checkVersion = versionPart.substring(1);
  }

  // Validate it's a proper semver
  Version.parse(checkVersion);

  // Use the original version string (preserving v if present)
  return FlutterVersion.release(versionPart, fork: forkName);
} catch (e) {
  // Not a valid semver, treat as git reference
  return FlutterVersion.gitReference(versionPart, fork: forkName);
}
```

This approach:
1. Preserves the 'v' prefix in the `name` property for backward compatibility
2. Strips the 'v' only for validation purposes
3. Ensures the underlying version is a valid semantic version

## Version Type Classification

The implementation classifies versions into distinct types:

- `VersionType.channel`: For standard Flutter channels
- `VersionType.release`: For semantic versions
- `VersionType.unknownRef`: For git commits or references
- `VersionType.custom`: For custom versions

This classification is used throughout the application to determine how versions should be handled.

## Fork Support

Fork support is implemented by:

1. Detecting the fork prefix in the version string
2. Storing the fork name in the `fork` property
3. Providing the `fromFork` getter to easily identify forked versions
4. Preserving fork information when processing the version

## Error Handling

The implementation includes proper error handling for:

1. Invalid version formats
2. Invalid channel specifications
3. Validation rules specific to custom versions

## Version Comparison

The implementation also includes a `compareTo` method that allows for proper sorting of versions:

```dart
int compareTo(FlutterVersion other) {
  final otherVersion = assignVersionWeight(other.version);
  final versionWeight = assignVersionWeight(version);

  return compareSemver(versionWeight, otherVersion);
}
```

This ensures that versions are sorted in a logical manner, with releases properly ordered by version numbers.

## Best Practices and Design Decisions

The following best practices were applied in this implementation:

1. **Regular Expression for Parsing**: Using a regex for pattern matching provides a clean, unified approach to handling various formats.

2. **Separation of Concerns**: Each version type is handled by a specific constructor, maintaining clear separation of responsibilities.

3. **Backward Compatibility**: The 'v' prefix is preserved in the version name for compatibility with existing code and user expectations.

4. **Immutable Objects**: `FlutterVersion` instances are immutable, making them thread-safe and easier to reason about.

5. **Robust Error Handling**: Format exceptions provide clear error messages for invalid inputs.

6. **Clear Type System**: The use of enum types makes it easy to identify and handle different version types.

## Testing

The implementation is thoroughly tested through:

1. Unit tests for each format variant
2. Integration tests in installation commands
3. Edge case testing for special formats
4. Error case testing for invalid inputs

This ensures the parser correctly handles all expected version formats and provides appropriate error messages for invalid inputs. 