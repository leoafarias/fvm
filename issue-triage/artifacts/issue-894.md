# Issue #894: [Feature Request] multi-user fvm cache

## Metadata
- **Reporter**: @byron-hawkins
- **Created**: 2025-07-16
- **Reported Version**: FVM 3.x (Linux shared hosts)
- **Issue Type**: feature
- **URL**: https://github.com/leoafarias/fvm/issues/894

## Problem Summary
Multiple users on the same Linux machine cannot share the FVM cache because cloned Flutter directories are owned by the installing user with 644/755 permissions. Subsequent users lack write access, so FVM can’t update the cache and the safe option is to maintain separate copies (wasting disk space).

## Version Context
- Reported against: v3.x
- Current version: v4.0.0
- Version-specific: no — behavior unchanged

## Validation Steps
1. Examined `FlutterService.install`: we invoke `git clone` without any `core.sharedRepository` configuration, so Git writes files with the invoking user’s umask.
2. Checked `CacheService` helpers—no post-clone chmod/chgrp logic exists.
3. Verified there’s no documentation describing how to configure a shared cache.

## Evidence
```
lib/src/services/flutter_service.dart:196-205  // git clone without extra config
Cache files inherit default 644/755 permissions, preventing cross-user writes.
```

## Current Status in v4.0.0
- [x] Still reproducible
- [ ] Already fixed
- [ ] Not applicable to v4.0.0
- [ ] Needs more information

## Troubleshooting/Implementation Plan

### Root Cause Analysis
The cache is cloned with default Git permissions that mirror the invoking user’s umask. No post-clone permission adjustments or shared repository settings exist, so subsequent users lack write access and the cache cannot be reused across accounts.

### Proposed Solution
1. **Config option**: introduce `fvm config --shared-cache <mode>` (or env `FVM_SHARED_CACHE=group`) enabling group-writable behavior.
2. **Git clone adjustments**: when shared mode is enabled, clone with `git clone --config core.sharedRepository=group` (and/or `--config receive.denyCurrentBranch=ignore`). For archives downloaded from storage, run `chmod -R g+rwX` after extraction.
3. **Directory creation**: use `Directory.createSync` then immediately set POSIX permissions via `Process.run('chmod', ...)` or `FileStat.statSync` + `setPosixPermissions` (with `dart:ffi`/`posix` package) to ensure 775/664.
4. **Group ownership**: optionally allow configuring a cache group (e.g., via env `FVM_CACHE_GROUP`). If set, run `chgrp -R` on cache root after writes.
5. **Documentation**: add a “Shared cache” section covering prerequisites (common group, `umask 0002`, enabling the new config).
6. **Testing**: add integration test that simulates two users (via `su` in CI container or using `fakeroot`) to ensure the second user can reuse the cache without permission errors.

### Alternative Approaches
- Keep cache read-only and rely on git fetch with `--reference`; this still requires write access for updates. Another option is to mount cache on a group-writable filesystem where umask already handled—documenting that could be minimal fix if code change complex.

### Dependencies & Risks
- Need to ensure Windows behavior unaffected (skip chmod). Use `Platform.isWindows` guards.
- Setting permissions programmatically requires invoking `chmod`/`chgrp` (POSIX only); ensure failures degrade gracefully.

## Classification Recommendation
- Priority: **P2 - Medium** (enhancement improving multi-user environments)
- Suggested Folder: `validated/p2-medium/`

## Notes for Follow-up
- If we add group support, update `install.sh` to mention new flag and avoid assuming per-user ownership.
