# Action Item: Issue #1030 - Non-Interactive Version Mismatch Handling

> Archived 2026-06-16: GitHub issue #1030 is closed as completed. PR #1036 addressed non-TTY prompt handling and PR #1033 closed the issue by removing the false `git describe --tags` cache-version path. Keep this file as historical context only.

## Objective
Ensure version-mismatch remediation never blocks hooks, CI-like callers, or other non-interactive environments, and add regression coverage for the reported project `pubspec.yaml` version contamination path.

## Current Evidence
- `EnsureCacheWorkflow._handleVersionMismatch` prompts unless `context.skipInput` is true.
- `FvmContext.skipInput` currently means CI environment or explicit `--fvm-skip-input`.
- There is no current `stdin.hasTerminal` check in `FvmContext`.
- Existing tests cover CI and explicit skip-input behavior, but not ordinary non-TTY hook execution.
- `CacheFlutterVersion` loads SDK metadata from Flutter cache files/git metadata; the report needs a regression test proving project app `pubspec.yaml` `version:` cannot leak into that value.

## Work Plan
1. Add a testable interactivity decision, either in `FvmContext` or `Logger`, that treats non-TTY stdin as non-interactive.
2. Update `Logger.select` or `EnsureCacheWorkflow._handleVersionMismatch` so non-interactive mode always picks a safe default and never opens a prompt.
3. Keep the current safe default for mismatch remediation: remove the incorrect SDK cache and reinstall the requested version.
4. Add a non-TTY/pre-commit style test for mismatch handling. Prefer dependency injection over hard-coding global `stdin` in tests.
5. Add a regression fixture with a project `pubspec.yaml` such as `version: 4.260508.0+0` and `.fvmrc` Flutter `3.38.3`; assert the project version is never reported as the cached Flutter SDK version.
6. Investigate FVM-owned child process cleanup for interrupted parent commands and document whether a code change is needed.

## Acceptance Criteria
- `fvm use` and `fvm install` do not block on mismatch prompts when stdin is non-TTY.
- CI, explicit `--fvm-skip-input`, and non-TTY callers share the same predictable non-interactive path.
- The app package `version:` in project `pubspec.yaml` cannot be mistaken for `CacheFlutterVersion.flutterSdkVersion`.
- Tests cover the exact failure class before the issue is closed.

## Verification
```bash
dart test test/src/workflows/ensure_cache_ci_test.dart test/src/services/logger_service_test.dart
dart test test/src/models/cache_flutter_version_model_test.dart test/src/services/project_service_test.dart
dart analyze --fatal-infos
```

## Notes
Avoid requiring users to set `CI=true` in hooks as the primary solution. That remains a workaround, not a robust default for non-interactive callers.
