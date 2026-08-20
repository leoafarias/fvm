# Issue #743: [Feature Request] Don't require specifying Flutter version in VS Code `dart.flutterSdkPath`

## Metadata
- **Reporter**: @zeshuaro
- **Created**: 2024-06-22
- **Issue Type**: feature request
- **URL**: https://github.com/conceptadev/fvm/issues/743

## Problem Summary
VS Code integration currently writes the specific version path (`.fvm/versions/<version>`). This breaks Renovate automation because an extra file (.vscode/settings.json) must be updated when the Flutter version changes.

## Validation Steps
1. Inspected current `UpdateVsCodeSettingsWorkflow` on `origin/main`.
2. Confirmed `_resolveSdkPath` still resolves `project.localVersionSymlinkPath`.
3. Confirmed `Project.localVersionSymlinkPath` contains the pinned version name.
4. Searched current commands for `getFlutterSdkCommand` support or an SDK path command; none exists.

## Evidence
```text
lib/src/workflows/update_vscode_settings.workflow.dart:_resolveSdkPath
  uses project.localVersionSymlinkPath

lib/src/models/project_model.dart:localVersionSymlinkPath
  joins .fvm/versions/<pinned-version>

No getFlutterSdkCommand/getDartSdkCommand implementation exists on origin/main.
```

## Current Status in v4.1.2
- [x] Still reproducible by code inspection
- [ ] Already fixed
- [ ] Needs more information

## Troubleshooting/Implementation Plan
- Point `dart.flutterSdkPath` to `.fvm/flutter_sdk` (symlink) instead of version-specific path.
- Alternatively, adopt `dart.getFlutterSdkCommand` integration (see issue #821) so VS Code can dynamically resolve the path.
- Add folder/workspace tests proving a Flutter version change does not require a version-specific settings edit.

## Recommendation
- Priority: **P2 - Medium**
- Suggested Folder: `validated/p2-medium/`
