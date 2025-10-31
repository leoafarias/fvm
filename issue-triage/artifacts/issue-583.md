# Issue #583: [Feature Request] Replace current version by upgrading it

## Metadata
- **Reporter**: J.C.Ködel (@JCKodel)
- **Created**: 2023-12-07
- **Reported Version**: 3.0.x
- **Issue Type**: enhancement
- **URL**: https://github.com/leoafarias/fvm/issues/583

## Problem Summary
Upgrading Flutter via FVM today requires several manual steps:
```
fvm remove <old>
fvm install <new>
fvm global <new>
```
There is no `fvm upgrade` helper or even a `--force` flag to skip prompts when removing versions. Users want a one-shot command (especially for the global SDK) that fetches the latest release and optionally removes the previous one.

## Version Context
- Reported against: 3.0.x
- Current version: v4.0.0
- Version-specific: no — the CLI still lacks upgrade ergonomics.

## Validation Steps
1. Reviewed `lib/src/commands` — no upgrade command exists; `global` and `remove` require manual interaction.
2. Checked `CacheService`/`FlutterReleaseClient` — we can already fetch the latest channel release, so implementing upgrade logic is feasible.
3. Confirmed `remove` command lacks `--force`; users must confirm interactively.

## Evidence
```
$ fvm --help | grep upgrade
# no entry

$ sed -n '1,80p' lib/src/commands/remove_command.dart
# interactive prompt, no --force
```

**Files/Code References:**
- [lib/src/commands/global_command.dart](../lib/src/commands/global_command.dart) – Handles global version selection today.
- [lib/src/services/releases_service/releases_client.dart](../lib/src/services/releases_service/releases_client.dart) – Provides latest channel releases.
- [lib/src/commands/remove_command.dart](../lib/src/commands/remove_command.dart) – Interactive removal only.

## Current Status in v4.0.0
- [x] Still reproducible (feature missing)
- [ ] Already fixed
- [ ] Not applicable to v4.0.0
- [ ] Needs more information
- [ ] Cannot reproduce

## Troubleshooting/Implementation Plan

### Proposed Solution
1. Add a new `upgrade` command (or extend `global` with an `--upgrade` flag):
   - Default behavior: upgrade the current global version to the latest release on the same channel (e.g., global “stable” → latest stable).
   - Optional argument to target a specific channel (`fvm upgrade beta`) or explicit version (`fvm upgrade 3.16.3`).
2. Workflow:
   - Determine the current global version; if none, prompt to set one first.
   - Resolve the target release (using `FlutterReleaseClient`).
   - Ensure the target is installed via `EnsureCacheWorkflow`; set it as global.
   - Offer `--remove-old` (with `--force`) to delete the previous global version automatically.
3. Add `--force` to `fvm remove` for parity and reuse inside the upgrade workflow.
4. Update docs and help output with examples (`fvm upgrade`, `fvm upgrade beta --remove-old --force`).

### Alternative Approaches
- Implement `fvm upgrade` as a thin alias that calls `fvm global <latest>` without removal. Users could then run `fvm cleanup`. Full solution above is more ergonomic.

### Dependencies & Risks
- Need to handle channel vs release logic carefully (e.g., upgrading from a pinned release vs channel alias).
- Ensure we don’t remove the old version unless explicitly requested.
- Provide clear messaging when already up to date.

### Related Code Locations
- [lib/src/workflows/ensure_cache.workflow.dart](../lib/src/workflows/ensure_cache.workflow.dart) – Already handles installs.
- [lib/src/services/cache_service.dart](../lib/src/services/cache_service.dart) – Used to remove versions.

## Recommendation
**Action**: validate-p2

**Reason**: UX improvement that saves common repetitive steps; not critical but high value for day-to-day usage.

## Notes
- Consider integrating with issue #688 (archived installs) to ensure upgrade works for mirror environments.
- Could also add a `fvm upgrade --all` for future multi-project support.

---
**Validated by**: Code Agent
**Date**: 2025-10-31
