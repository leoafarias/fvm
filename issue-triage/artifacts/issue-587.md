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
- [ ] Still reproducible
- [ ] Already fixed
- [x] Not applicable to v4.0.0 (upstream tooling limitation)
- [ ] Needs more information
- [ ] Cannot reproduce

## Resolution
On 2025-11-01 the maintainer closed the issue as “not planned,” noting that the same ownership errors appear when running the upstream Flutter tool directly. Because FVM simply launches Flutter with the caller’s environment, no additional change will be made in FVM. Recommended workaround: set `TAR_OPTIONS=--no-same-owner` (for example `ENV TAR_OPTIONS="--no-same-owner"` in Docker) before invoking Flutter/FVM.

## Recommendation
**Action**: closed (working as intended)

**Reason**: Behavior matches the upstream Flutter tool; users should configure `TAR_OPTIONS` when their filesystem disallows `chown`.

## Notes
- Documentation could still mention the workaround, but no code change is planned.

---
**Validated by**: Code Agent
**Date**: 2025-10-31
