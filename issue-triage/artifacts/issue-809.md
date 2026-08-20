# Issue #809: [BUG]: cannot update to newer flutter version (sidekick related)

## Metadata
- **Reporter**: @Ahmadre
- **Created**: 2024-12-29
- **Reported Version**: FVM 3.2.1
- **Issue Type**: bug (needs reproduction)
- **URL**: https://github.com/conceptadev/fvm/issues/809

## Problem Summary
Reporter references Sidekick issue #280 where Sidekick warns about local changes preventing upgrade. Believes underlying problem lies in FVM. No logs or reproduction steps provided.

## Validation Steps
- Without logs or steps, we cannot confirm behavior. `EnsureCacheWorkflow` already performs `git reset --hard` and `clean -fd` before fetching (see `ensure_cache.workflow.dart`), so need more info to diagnose.

## Evidence
```text
Reported version: FVM 3.2.1
Reporter explicitly says reliable reproduction steps are unavailable.
No verbose FVM CLI log or current 4.1.2 reproduction is attached.
The observed message originates from a Sidekick workflow.
```

## Troubleshooting/Implementation Plan
1. Request the reporter to provide `fvm install <version> --verbose` output and contents of `.fvm` cache directory when the warning occurs.
2. Confirm whether the issue only appears via Sidekick or also using CLI.
3. Reproduce on FVM 4.1.2 before changing current cache-reset behavior.
4. If CLI succeeds and only Sidekick fails, move the issue to the Sidekick integration tracker.

## Recommendation
- Folder: `needs_info/`
