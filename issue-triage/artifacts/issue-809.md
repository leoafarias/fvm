# Issue #809: [BUG]: cannot update to newer flutter version (sidekick related)

## Metadata
- **Reporter**: @Ahmadre
- **Created**: 2024-12-29
- **Reported Version**: FVM 3.2.1
- **Issue Type**: bug (needs reproduction)
- **URL**: https://github.com/leoafarias/fvm/issues/809

## Summary
Reporter references Sidekick issue #280 where Sidekick warns about local changes preventing upgrade. Believes underlying problem lies in FVM. No logs or reproduction steps provided.

## Validation
- Without logs or steps, we cannot confirm behavior. `EnsureCacheWorkflow` already performs `git reset --hard` and `clean -fd` before fetching (see `ensure_cache.workflow.dart`), so need more info to diagnose.

## Next Steps
1. Request the reporter to provide `fvm install <version> --verbose` output and contents of `.fvm` cache directory when the warning occurs.
2. Confirm whether the issue only appears via Sidekick or also using CLI.

## Classification Recommendation
- Folder: `needs_info/`
