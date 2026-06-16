# Action Item: Issue #1028 - Long-Running Install/Use Appears Frozen

> Revalidation note 2026-06-16: PR #1037 merged substantial git-cache changes but did not close #1028. Before implementing this action item, pull latest `main` and re-check whether the remaining hang is setup-only, mirror-update-only, or both.

## Objective
Make `fvm install` and `fvm use` visibly progress, diagnose stalls, and fail with actionable guidance when local mirror refresh or Flutter setup takes too long.

## Current Evidence
- `_syncMirrorWithRemote` in `lib/src/services/git_service.dart` runs `git remote update --prune origin` through `ProcessService.run`.
- `ProcessService.run` uses `Process.run` by default when `echoOutput` is false, so output is captured silently until the process exits.
- Initial mirror clone streams progress, but mirror update does not.
- `FlutterService.setup` runs `flutter --version`, which can trigger Flutter/Dart bootstrap work that may also appear frozen.

## Work Plan
1. Add an explicit progress phase before local mirror refresh starts, including the cache path and remote URL in verbose/debug output.
2. Introduce a long-running process helper in `ProcessService` or `GitService` that can stream selected output, emit a heartbeat, and report elapsed time.
3. Use that helper for `git remote update --prune origin` and any Flutter setup calls that are known to bootstrap dependencies.
4. Add a stall timeout or soft warning threshold that does not kill legitimate slow work too early, but tells users how to recover.
5. Include recovery guidance: rerun with `--verbose`, try `FVM_USE_GIT_CACHE=false`, run manual `git fetch --verbose --prune origin` in the cache, or clear/rebuild the FVM cache.
6. Add tests with a fake or injectable process runner proving that a long-running command produces progress/heartbeat output and that failures preserve stderr.

## Acceptance Criteria
- A user can tell whether FVM is updating the local mirror, running Flutter setup, or waiting on another long-running command.
- Quiet long-running process execution no longer leaves the terminal with no meaningful update.
- Mirror update failures include the command, cache path, remote URL, exit code, and recovery guidance.
- Existing command output remains concise in normal fast-path installs.

## Verification
```bash
dart test test/services/git_service_test.dart test/services/flutter_service_test.dart
dart test test/src/workflows/ensure_cache_ci_test.dart
dart analyze --fatal-infos
```

## Notes
Do not fix this by disabling the git cache globally without a separate compatibility decision. The goal is to keep the cache useful while making long-running work observable and bounded.
