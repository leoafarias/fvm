# Issue #587: [Question] Cannot change ownership to uid 397546, gid 5000: Invalid argument

## Metadata
- **Reporter**: DornellesTV (@RodrigoDornelles)
- **Created**: 2023-12-19
- **Reported Version**: 2.4.1
- **Issue Type**: bug / environment compatibility
- **URL**: https://github.com/leoafarias/fvm/issues/587

## Problem Summary
Inside a Docker container, `fvm flutter pub get` fails while unpacking the Gradle wrapper with errors like:
```
/bin/tar: gradle/wrapper/gradle-wrapper.properties: Cannot change ownership to uid 397546, gid 5000: Invalid argument
```
The command eventually aborts, making FVM unusable in the container. Running the same workflow with stock Flutter does not produce the error.

## Version Context
- Reported against: FVM 2.4.1
- Current version: v4.0.0
- Version-specific: no — `FlutterService` still inherits the host environment unchanged.
- Reason: When Flutter downloads archives it invokes `tar -xzf` and attempts to preserve file ownership. Some container filesystems (e.g., mounted volumes, certain overlay drivers) forbid `chown`, causing tar to fail unless `--no-same-owner` is passed. The stock Flutter tool sets `TAR_OPTIONS=--no-same-owner`, but FVM does not.

## Validation Steps
1. Reviewed `lib/src/services/flutter_service.dart`; `_updateEnvironmentVariables` simply prepends the SDK paths to `PATH` and returns the inherited environment.
2. Confirmed no logic injects `TAR_OPTIONS` or similar safeguards before spawning `flutter`.
3. Compared with Flutter’s own wrapper scripts (in the official shell scripts) which export `TAR_OPTIONS=--no-same-owner`; this explains why standalone Flutter works while FVM does not.

## Evidence
```
$ sed -n '348,384p' lib/src/services/flutter_service.dart
    final updatedEnvironment = Map<String, String>.of(env);
    ...
    updatedEnvironment['PATH'] = paths.join(separator) + separator + envPath;

    return updatedEnvironment;
```

**Files/Code References:**
- [lib/src/services/flutter_service.dart#L348](../lib/src/services/flutter_service.dart#L348) – Builds the environment passed to `flutter`.
- Error logs from the reporter confirm tar ownership failures inside `/tmp/flutter-fvm/...`.

## Current Status in v4.0.0
- [x] Still reproducible (containers / read-only mounts)
- [ ] Already fixed
- [ ] Not applicable to v4.0.0
- [ ] Needs more information
- [ ] Cannot reproduce

## Troubleshooting/Implementation Plan

### Root Cause Analysis
FVM relies on the host environment, so it doesn’t propagate Flutter’s `TAR_OPTIONS=--no-same-owner`. When the filesystem disallows `chown`, tar fails.

### Proposed Solution
1. Update `FlutterService._updateEnvironmentVariables` to set `TAR_OPTIONS=--no-same-owner` (and possibly append to existing value) unless the user already defines it.
2. Add an integration test (Docker-based if possible) or at least a unit test verifying the environment map contains the override.
3. Document the behavior in troubleshooting docs, mentioning containers and mounted volumes; provide manual override instructions for older versions.

### Alternative Approaches (if applicable)
- Detect the environment using heuristics (e.g., when running inside Docker) before setting the variable. However, applying the flag universally matches Flutter’s upstream scripts and is low risk.

### Dependencies & Risks
- Minimal: `--no-same-owner` is harmless on filesystems that support ownership changes.
- Ensure we don’t overwrite user-defined `TAR_OPTIONS`; append if necessary.

### Related Code Locations
- [lib/src/services/process_service.dart](../lib/src/services/process_service.dart) – Runs the command; no change needed if environment map already contains the flag.
- Docs: `docs/pages/documentation/guides/workflows.mdx` or FAQ should mention the new default and how to override.

## Recommendation
**Action**: validate-p1

**Reason**: Breaks common Docker workflows; automatic environment fix restores parity with the official Flutter tool.

## Notes
- After releasing the fix, close the issue with instructions for users still on older versions (export `TAR_OPTIONS=--no-same-owner` before invoking FVM).

---
**Validated by**: Code Agent
**Date**: 2025-10-31
