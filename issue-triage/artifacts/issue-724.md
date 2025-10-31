# Issue #724: SDK Path does not point to the project directory. "fvm use" will not make IntelliJ (Android Studio, ...) switch Flutter version. Please consult documentation.

## Metadata
- **Reporter**: @Haidar0096
- **Created**: 2024-05-18
- **Reported Version**: stable channel (3.22.0)
- **Issue Type**: support
- **URL**: https://github.com/leoafarias/fvm/issues/724

## Problem Summary
`fvm doctor` shows `SDK Path does not point to the project directory…` for Android Studio. The IDE keeps using a hard-coded Flutter SDK path (e.g., `/Users/.../fvm/versions/stable`) even after running `fvm use stable`, so the IDE does not follow the `.fvm/flutter_sdk` symlink that FVM maintains.

## Version Context
- Reported against: v3.19.x (stable channel)
- Current version: v4.0.0
- Version-specific: no
- Reason: Android Studio still relies on a single Flutter SDK path; the workflow is unchanged in v4.0.0.

## Validation Steps
1. Reproduced `fvm doctor` output locally showing the warning when `.idea/libraries/Dart_SDK.xml` points to a fixed SDK path.
2. Confirmed `fvm doctor` continues to emit the same warning in v4.0.0 via `lib/src/commands/doctor_command.dart:138-160`.
3. Verified documentation now instructs users to point Android Studio at `.fvm/flutter_sdk` (see `docs/pages/documentation/guides/workflows.mdx:195-199`).

## Evidence
```
lib/src/commands/doctor_command.dart:138-160  // Warns when IntelliJ SDK path is not in the project .fvm directory
docs/pages/documentation/guides/workflows.mdx:195-199  // Step-by-step instructions for Android Studio configuration
```

**Files/Code References:**
- [lib/src/commands/doctor_command.dart:138](../lib/src/commands/doctor_command.dart#L138) – Logic emitting the warning seen in the issue.
- [docs/pages/documentation/guides/workflows.mdx:195](../docs/pages/documentation/guides/workflows.mdx#L195) – Updated docs describing the correct IDE path.

## Current Status in v4.0.0
- [ ] Still reproducible
- [x] Already fixed
- [ ] Not applicable to v4.0.0
- [ ] Needs more information
- [ ] Cannot reproduce

## Troubleshooting/Implementation Plan

### Root Cause Analysis
Android Studio stores the Flutter SDK location as a single path; pointing it at a specific cached SDK prevents `fvm use` from switching versions. FVM already surfaces the issue via `doctor` and provides the necessary symlink.

### Proposed Solution
1. Close the issue with instructions to update Android Studio’s Flutter SDK path to `<project>/.fvm/flutter_sdk`.
2. Reference the updated workflow documentation in the reply.
3. Consider adding a screenshot or short FAQ entry in the docs (tracked separately in the Android Studio research artifact).

### Alternative Approaches
- Long term: implement `fvm ide android-studio --sync` to update `.idea` XML automatically (tracked outside this issue).

### Dependencies & Risks
- Documentation only; no code change required.

### Related Code Locations
- [lib/src/services/cache_service.dart:171](../lib/src/services/cache_service.dart#L171) – Shows `fvm global` manages `~/.fvm/default`, reinforcing the symlink approach.

## Recommendation
**Action**: resolved  
**Reason**: The warning reflects expected IDE configuration; documentation and `fvm doctor` now guide users to the fix.

## Draft Reply
```
Thanks for the report! FVM keeps `.fvm/flutter_sdk` in sync with the version you select, but Android Studio still stores a single Flutter SDK path per project. If the IDE is pointed at `/Users/.../fvm/versions/stable`, it won’t follow `fvm use`.

Please open **File → Project Structure → Flutter** and set the SDK path to `<project>/.fvm/flutter_sdk` (or `~/.fvm/default` for the global workflow). After applying the change the IDE will follow whatever version you select with `fvm use`.

We’ve called this out in the workspace workflow docs and `fvm doctor` now links to the same guidance, so I’m marking the issue resolved. Let us know if anything still looks off after updating the SDK path.
```

## Notes
- Fold this closure message into the Android Studio troubleshooting doc update.

---
**Validated by**: Code Agent  
**Date**: 2025-10-31
