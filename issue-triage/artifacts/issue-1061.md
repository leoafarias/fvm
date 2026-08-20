# Issue #1061: [BUG] fvm flutter / fvm dart add ~4s per invocation (git fsck --connectivity-only on cache.git)

## Metadata
- **Reporter**: jlafazia-figure
- **Created**: 2026-08-18
- **Reported Version**: 4.1.2 (macOS, Homebrew)
- **Issue Type**: bug
- **URL**: https://github.com/leoafarias/fvm/issues/1061

## Problem Summary
Every `fvm flutter` / `fvm dart` invocation pays ~4s of wrapper overhead before the SDK
starts, even when the pinned SDK is already installed and no fetch is required. Running the
same command through the project symlink (`.fvm/flutter_sdk/bin/flutter`) takes ~0.4s. The
reporter traced the cost to `git fsck --connectivity-only` running against a 512MB
`~/fvm/cache.git`, which alone takes ~3.1s on their machine. Scripts that shell out to
`fvm flutter` repeatedly (for example `gen-l10n` across 17 localization folders) pay the cost
per process, totalling 70-90s of pure overhead.

The reporter also notes `FVM_USE_GIT_CACHE=false` does not remove the cost (~3.8s remains).

## Version Context
- Reported against: v4.1.2
- Current version: v4.1.4
- Version-specific: no
- Reason: The offending call path is unchanged on current `origin/main` (verified at merge
  commit `e23bcf2c`, which includes #1060 and the v4.1.3/v4.1.4 release commits).

## Validation Steps
1. Traced the per-command entry point: every command that resolves a version goes through
   `EnsureCacheWorkflow.call`.
2. Confirmed `ensureBareCacheIfPresent()` is invoked unconditionally there for any non-fork
   version, *before* the cache-miss guard and *regardless of* `context.gitCache`.
3. Followed `ensureBareCacheIfPresent` -> `_determineCacheState` -> `_withConnectivityCheckedState`
   -> `_validateGitCache` -> `git fsck --connectivity-only`.
4. Compared against `updateLocalMirror`, which deliberately skips the same connectivity check
   when the shape state is already `ready`.
5. Checked what `ensureBareCacheIfPresent` actually does with the connectivity result.

## Evidence

Hot path, runs for every non-fork version before any cache-miss check, and ignores
`context.gitCache`:

```dart
// lib/src/workflows/ensure_cache.workflow.dart:135
final useGitCache = context.gitCache;
var useGitCacheForInstall = useGitCache;
if (!version.fromFork) {
  try {
    await gitService.ensureBareCacheIfPresent();   // <-- unconditional
    cacheVersion = cacheService.getVersion(version);
    if (useGitCache && cacheVersion == null) {
      await gitService.updateLocalMirror();
    }
```

This confirms the reporter's observation that `FVM_USE_GIT_CACHE=false` does not help:
`context.gitCache` only gates `updateLocalMirror`, not `ensureBareCacheIfPresent`.

The connectivity check is unconditional in `_determineCacheState`:

```dart
// lib/src/services/git_service.dart:769
Future<_GitCacheState> _determineCacheState(Directory gitCacheDir) async {
  final cacheState = await _determineCacheShapeState(gitCacheDir);

  return _withConnectivityCheckedState(gitCacheDir, cacheState);   // <-- always
}
```

...and `_withConnectivityCheckedState` runs full-object-graph verification for exactly the
two states that are most common in normal use (`ready`, `overbroad`):

```dart
// lib/src/services/git_service.dart:334
Future<void> _validateGitCache(Directory directory) async {
  await _purgeOsMetadataFromRefs(directory);
  await get<ProcessService>().run(
    'git',
    args: ['fsck', '--connectivity-only'],
    workingDirectory: directory.path,
  );
}
```

The decisive finding: `ensureBareCacheIfPresent` cannot act on the fsck result at all.
`ready`, `missing`, and `invalid` all fall through to the same no-op, and the two states that
do trigger work (`overbroad`, `legacy`) are decided by the *shape* check, which needs no fsck:

```dart
// lib/src/services/git_service.dart:1266
final cacheState = await _determineCacheState(gitCacheDir);
switch (cacheState) {
  case _GitCacheState.ready:
  case _GitCacheState.missing:
    break;                                    // no-op
  case _GitCacheState.overbroad:
    await _rebuildHeadsTagsGitCache(gitCacheDir, updateRemote: false);
  case _GitCacheState.legacy:
    await _migrateCacheCloneToGitCache(gitCacheDir, updateRemote: false);
  case _GitCacheState.invalid:
    // Defer handling to install/update workflows to avoid heavy work here.
    logger.debug('Git cache is invalid; skipping migration. ...');
    break;                                    // no-op
}
```

So a ~3s full-repository integrity scan runs on every single command in order to distinguish
`ready` from `invalid` — two branches with identical behavior.

By contrast, the install/update path already treats the check as expensive and guards it:

```dart
// lib/src/services/git_service.dart:1229
var cacheState = await _determineCacheShapeState(gitCacheDir);
if (cacheState != _GitCacheState.ready) {
  cacheState = await _withConnectivityCheckedState(gitCacheDir, cacheState);
}
```

**Files/Code References:**
- [lib/src/workflows/ensure_cache.workflow.dart:135](../../lib/src/workflows/ensure_cache.workflow.dart#L135) - unconditional hot-path call, not gated by `context.gitCache`
- [lib/src/services/git_service.dart:1261](../../lib/src/services/git_service.dart#L1261) - `ensureBareCacheIfPresent`
- [lib/src/services/git_service.dart:769](../../lib/src/services/git_service.dart#L769) - `_determineCacheState` always adds the connectivity check
- [lib/src/services/git_service.dart:775](../../lib/src/services/git_service.dart#L775) - `_withConnectivityCheckedState`
- [lib/src/services/git_service.dart:334](../../lib/src/services/git_service.dart#L334) - `_validateGitCache` runs `git fsck --connectivity-only`
- [lib/src/services/git_service.dart:1229](../../lib/src/services/git_service.dart#L1229) - `updateLocalMirror` already guards the same check

## Current Status in v4.1.4
- [x] Still reproducible
- [ ] Already fixed
- [ ] Not applicable
- [ ] Needs more information
- [ ] Cannot reproduce

## Troubleshooting/Implementation Plan
**IMPORTANT**: Plan only. Do not implement during triage.

### Root Cause Analysis
`ensureBareCacheIfPresent` calls `_determineCacheState`, which always appends a
`git fsck --connectivity-only` pass over the entire bare cache. Cost scales with cache size
(~3.1s at 512MB) and is paid once per FVM process. The result is then discarded: the `invalid`
branch is an explicit no-op that defers to install/update workflows. The migration decision
this method actually makes depends only on `_determineCacheShapeState`.

The 4.1.0 work (#1018) removed fsck from the *mirror refresh* hot path but left this second
per-command path in place, which is why the reporter sees the cost on 4.1.2.

### Proposed Solution
1. In [git_service.dart:1266](../../lib/src/services/git_service.dart#L1266), call
   `_determineCacheShapeState(gitCacheDir)` instead of `_determineCacheState(gitCacheDir)`.
   The `invalid` case becomes unreachable from shape detection alone and the existing no-op
   branch can stay as a defensive default.
2. Leave `updateLocalMirror` unchanged; it already guards the connectivity check and is the
   correct place to detect corruption, since it is the path that will rebuild.
3. Consider narrowing `_determineCacheState` itself, or deleting it if
   `ensureBareCacheIfPresent` was its only remaining caller — verify with a grep before
   removing.
4. Add a regression test asserting `ensureBareCacheIfPresent` issues no `fsck` for a healthy
   heads/tags cache, using the `ProcessService` fake to record invoked git argument lists.
   `test/services/git_service_test.dart` gained process-level assertions in #1060 and is the
   natural home.
5. Verify with `dart test -x "sdk || network || git || integration || migration"`, then time
   `fvm flutter --version` against a large `cache.git` before and after.

### Alternative Approaches
- Cache the fsck result on disk with a TTL/mtime stamp. Rejected: adds state and staleness
  for a check whose result this call site cannot use.
- Run fsck only when `--verbose`/`doctor` asks. Reasonable as a follow-up, but orthogonal;
  the primary defect is that the hot path computes a value it discards.
- Gate `ensureBareCacheIfPresent` behind `context.gitCache`. This would fix the
  `FVM_USE_GIT_CACHE=false` half of the report but would leave the default configuration slow,
  and would skip legacy-cache migration for users who disabled the cache.

### Dependencies & Risks
- Touches `GitService` and `EnsureCacheWorkflow`, so the manual branch smoke test in
  `docs/pages/documentation/guides/manual-smoke-test.md` applies before handoff.
- Corruption detection is not lost: `updateLocalMirror` still fsck's before rebuild, and
  install/clone failures still fall back to a remote clone.
- Edge case worth covering: a cache that is shape-`ready` but object-corrupt will now be
  detected at install time rather than at command time. That matches the existing
  "defer handling to install/update workflows" comment.

### Related Code Locations
- [lib/src/services/git_service.dart:291](../../lib/src/services/git_service.dart#L291) - `_purgeOsMetadataFromRefs`, related to #1043 (`refs/.DS_Store`)
- [lib/src/workflows/ensure_cache.workflow.dart:154](../../lib/src/workflows/ensure_cache.workflow.dart#L154) - cache integrity verification after this call

## Recommendation
**Action**: validate-p1

**Reason**: Confirmed by code inspection, affects every command on the default configuration,
scales with cache size, has no user-side workaround (`FVM_USE_GIT_CACHE=false` does not help),
and the expensive work provably cannot change the outcome at that call site.

## Notes
- Reporter's cross-references check out: #1043 is the related `refs/.DS_Store` cache-recreate
  report, #370 is the older Windows `fvm flutter` slowness report.
- The reporter's link points at `_refreshExistingMirror`/`_refreshExistingGitCache` from the
  4.1.0 work; the surviving path is the separate `ensureBareCacheIfPresent` call, so the fix
  is not a revert of that change.

---
**Validated by**: Code Agent
**Date**: 2026-08-19
