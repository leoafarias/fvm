# Issue #743: [Feature Request] Don't require specifying Flutter version in VS Code `dart.flutterSdkPath`

## Metadata
- **Reporter**: @zeshuaro
- **Created**: 2024-06-22
- **Issue Type**: feature request
- **URL**: https://github.com/leoafarias/fvm/issues/743

## Problem Summary
VS Code integration currently writes the specific version path (`.fvm/versions/<version>`). This breaks Renovate automation because an extra file (.vscode/settings.json) must be updated when the Flutter version changes.

## Proposed Solution
- Point `dart.flutterSdkPath` to `.fvm/flutter_sdk` (symlink) instead of version-specific path.
- Alternatively, adopt `dart.getFlutterSdkCommand` integration (see issue #821) so VS Code can dynamically resolve the path.

## Classification Recommendation
- Priority: **P2 - Medium**
- Suggested Folder: `validated/p2-medium/`
