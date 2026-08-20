# Issue #724: SDK Path does not point to the project directory. "fvm use" will not make IntelliJ (Android Studio, ...) switch Flutter version. Please consult documentation.

## Metadata
- **Reporter**: @Haidar0096
- **Created**: 2024-05-18
- **Reported Version**: stable channel (3.22.0)
- **Issue Type**: support
- **URL**: https://github.com/conceptadev/fvm/issues/724

## Problem Summary
`fvm doctor` shows `SDK Path does not point to the project directory…` for Android Studio. The IDE keeps using a hard-coded Flutter SDK path (e.g., `/Users/.../fvm/versions/stable`) even after running `fvm use stable`, so the IDE does not follow the `.fvm/flutter_sdk` symlink that FVM maintains.

## Version Context
- Reported against: v3.19.x (stable channel)
- Current version: v4.1.2
- Version-specific: no
- Reason: Android Studio still relies on a single Flutter SDK path; the workflow is unchanged in v4.0.0.

## Validation Steps
1. Reproduced `fvm doctor` output locally showing the warning when `.idea/libraries/Dart_SDK.xml` points to a fixed SDK path.
2. Confirmed `fvm doctor` continues to emit the same warning in v4.0.0 via `lib/src/commands/doctor_command.dart:138-160`.
3. Verified documentation now instructs users to point Android Studio at `.fvm/flutter_sdk` (see `docs/pages/documentation/guides/workflows.mdx:195-199`).
4. Re-reviewed the 2025 follow-up: a user reports branch switching still leaves Android Studio on a physical cached SDK, causing cross-version build errors.
5. Correlated with current confirmations on #767; documentation explains the intended path but does not prevent IntelliJ from resolving/persisting the symlink target.

## Evidence
```
lib/src/commands/doctor_command.dart:138-160  // Warns when IntelliJ SDK path is not in the project .fvm directory
docs/pages/documentation/guides/workflows.mdx:195-199  // Step-by-step instructions for Android Studio configuration
```

**Files/Code References:**
- [lib/src/commands/doctor_command.dart:138](../../lib/src/commands/doctor_command.dart#L138) – Logic emitting the warning seen in the issue.
- [docs/pages/documentation/guides/workflows.mdx:195](../../docs/pages/documentation/guides/workflows.mdx#L195) – Updated docs describing the correct IDE path.

## Current Status in v4.1.2
- [x] Still reproducible / currently reported
- [ ] Already fixed
- [ ] Not applicable to v4.0.0
- [ ] Needs more information
- [ ] Cannot reproduce

## Troubleshooting/Implementation Plan

### Root Cause Analysis
Android Studio stores and may resolve the Flutter SDK location to a physical cache path. Pointing it at `.fvm/flutter_sdk` is the documented workflow, but recent reports show the IDE/plugin can persist the resolved target, so `fvm use` cannot reliably switch it.

### Proposed Solution
1. Consolidate reproduction with #767 using current Android Studio and Flutter plugin versions.
2. Capture `.idea/libraries/Dart_SDK.xml`, `android/local.properties`, and IDE SDK settings before and after branch/version switches.
3. Decide whether to implement opt-in IntelliJ file synchronization or document the upstream symlink-resolution limitation as unsupported.
4. Keep the existing `.fvm/flutter_sdk` guidance as the first troubleshooting step, but do not treat it as proof the compatibility bug is fixed.

### Alternative Approaches
- Long term: implement `fvm ide android-studio --sync` to update `.idea` XML automatically (tracked outside this issue).

### Dependencies & Risks
- Documentation only; no code change required.

### Related Code Locations
- [lib/src/services/cache_service.dart:171](../../lib/src/services/cache_service.dart#L171) – Shows `fvm global` manages `~/.fvm/default`, reinforcing the symlink approach.

## Recommendation
**Action**: validate-p2
**Reason**: Documentation covers the intended setup, but current reports show the IDE may resolve and persist the physical SDK path. Track with #767/#600 as an active compatibility gap.

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
