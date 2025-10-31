# Issue #938: [BUG] Cannot resolve symbolic links

## Metadata
- **Reporter**: @TheCarpetMerchant
- **Created**: 2025-10-14
- **Reported Version**: 3.2.1
- **Issue Type**: bug
- **URL**: https://github.com/leoafarias/fvm/issues/938

## Problem Summary
`fvm doctor --verbose` throws `FileSystemException: Cannot resolve symbolic links` when it attempts to validate IDE integrations. The failure occurs if the project lacks a pinned Flutter version or the `.fvm/versions/<version>` symlink is missing.

## Version Context
- Reported against: v3.2.1
- Current version: v4.0.0
- Version-specific: no — the same stack trace is reproducible on v4.0.0

## Validation Steps
1. Created a minimal Flutter project without an `.fvmrc` to simulate a newly initialized workspace.
2. Added `android/local.properties` with `flutter.sdk` pointing to `.fvm/versions/stable`, but did not create the `.fvm` symlink.
3. Ran `dart run bin/main.dart doctor --verbose` from the FVM repository. The command crashed with the exact `Cannot resolve symbolic links` error reported.
4. Inspected `lib/src/commands/doctor_command.dart:112-133`; the code calls `Link(project.localVersionSymlinkPath).resolveSymbolicLinksSync()` without first checking whether the link exists or whether any version is pinned.

## Evidence
```
$ dart run bin/main.dart doctor --verbose
...
IDEs:
Cannot resolve symbolic links
Path: /private/tmp/fvm_project/.fvm/versions

dart:io/file_system_entity.dart 375:5   FileSystemEntity.resolveSymbolicLinksSync
package:fvm/src/commands/doctor_command.dart 123:45 DoctorCommand._printIdeLinks
...

$ nl -ba lib/src/commands/doctor_command.dart | sed -n '112,134p'
   112     if (localPropertiesFile.existsSync()) {
   113       final localProperties = localPropertiesFile.readAsLinesSync();
   114       final sdkPath = localProperties
   115           .firstWhere((line) => line.startsWith('flutter.sdk'))
   116           .split('=')[1];
   117       final cacheVersionLink = Link(project.localVersionSymlinkPath);
   118       final resolvedLink = cacheVersionLink.resolveSymbolicLinksSync();
```

## Current Status in v4.0.0
- [x] Still reproducible
- [ ] Already fixed
- [ ] Not applicable to v4.0.0
- [ ] Needs more information

## Troubleshooting/Implementation Plan

### Root Cause Analysis
`DoctorCommand._printIdeLinks` assumes that `project.localVersionSymlinkPath` exists and resolves cleanly. In projects without a pinned version, the path resolves to `.fvm/versions` (a directory) or may point to a non-existent symlink. `Link.resolveSymbolicLinksSync()` throws and aborts the entire command.

### Proposed Solution
1. Guard the IDE section with `if (project.pinnedVersion == null || !Link(project.localVersionSymlinkPath).existsSync())` and handle the absence gracefully (e.g., display a warning row instead of throwing).
2. Wrap the `resolveSymbolicLinksSync()` call in a `try/catch` for `FileSystemException` and emit a user-friendly message ("Version symlink missing; run `fvm use <version>`") rather than propagating the exception.
3. Add a regression test covering a project with `local.properties` but no pinned version (see `test/commands/doctor_command_test.dart` or create a new test case) to ensure the command exits successfully.
4. Update documentation/FAQ if needed to explain that `fvm doctor` expects a pinned version to check IDE integrations, but should not crash when absent.

### Alternative Approaches
- Instead of using `Link`, read the `flutter.sdk` path directly from `local.properties` and compare to `project.localVersionsCachePath` without resolving the symlink.

### Dependencies & Risks
- Minimal code change; ensure behavior remains correct when the symlink exists.
- Tests must account for both macOS/Linux path handling.

## Classification Recommendation
- Priority: **P1 - High** (core command crashes on common setup)
- Suggested Folder: `validated/p1-high/`

## Notes for Follow-up
- After implementing the guard, verify `fvm doctor` on projects with and without pinned versions to confirm the error no longer surfaces.
