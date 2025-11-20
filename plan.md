# Git Cache Auto-Migration Plan

## Goals
- Turn the git cache into a true bandwidth-optimization mirror so end-user SDK caches never depend on it for object storage.
- Auto-migrate every existing installation without manual steps, so users simply upgrade FVM and benefit from the safer layout.
- Keep the UX identical (fast installs, single cache path) while ensuring the cache can be deleted, moved, or pruned without breaking SDK installs.

## Current Issues (Why We Must Change)
1. The cache is created with `git clone` plus `--reference`, which wires every installed SDK’s `.git/objects/info/alternates` back to the cache. Removing or pruning the cache corrupts SDK clones, so the cache is more than a bandwidth helper.
2. The cache directory is a working tree instead of a bare mirror, so fetches waste disk, and it is easy to leave the repo dirty, forcing full re-clones.
3. Existing SDK caches may already contain alternates; they continue to be brittle even after we fix future installs unless we proactively detach them.
4. Tests/docs describe the cache as safe to delete, which is currently false, leading to confusing support cases.

## Proposed Changes & Rationale

### 1. Rebuild cache creation as a bare mirror
- **Change:** Update `GitService._createLocalMirror` to clone into a temporary directory via `git clone --mirror --progress <flutterUrl> <gitCachePath>.tmp` (keep `core.longpaths=true` on Windows), run `git fsck --strict --no-dangling` to validate, then atomically swap the directories (e.g., rename old cache to `.legacy` and rename `.tmp` into place). Keep using `git remote update --prune origin` for refreshes.
- **Reason:** Cloning to a temp dir plus `fsck --strict` ensures we never replace the cache with a corrupt mirror. Pruning maintains a true mirror while minimizing churn.

### 2. Auto-migrate legacy caches
- **Change:** When `updateLocalMirror` runs, detect whether `gitCachePath` is missing, non-git, or a non-bare repo. If so, move it to `<path>.legacy-<timestamp>` (leave it in place until SDK detachment is complete), clone/validate a new mirror in a temp dir, and only then swap it in. Provide Windows-specific delete helpers that retry on sharing violations when finally removing `.legacy`.
- **Reason:** Leaving the legacy cache available prevents breakage while SDKs still reference it, and retry deletes keep Windows users from being blocked by locked files.

### 3. Detach existing SDK clones from the cache
- **Change:** When migration is triggered, iterate through ALL installed SDK versions looking for `.git/objects/info/alternates`. For each version with alternates: backup the file, run `git repack -ad --quiet`, verify with `git fsck --connectivity-only`, then delete alternates + backup. On failure, restore the backup and surface an actionable warning. All versions must be detached before the cache is removed and recreated.
- **Reason:** Detaching all versions upfront ensures no version depends on the cache when it's removed. The backup provides a quick rollback path if repack fails (e.g., disk full). Using `--connectivity-only` for verification is 20x faster than full fsck while still ensuring refs are valid.

### 4. Rework FlutterService cloning flow
- **Change:** When git cache is enabled and the version is not from a fork, clone directly from the local mirror path (e.g., `git clone --progress <gitCachePath> <versionDir>` with `-b channel` if needed). Immediately run `git remote set-url origin <context.flutterUrl>` so subsequent fetches go to the real remote. Keep the existing fallback path (clone from remote) for forks or when the mirror is unavailable.
- **Reason:** Cloning from a local mirror copies objects (hard-links on POSIX) without alternates, fulfilling the “single path” requirement while keeping installs fast.

### 5. Improve robustness & observability
- **Change:** Before updating or reusing the mirror, run `git fsck --strict --no-dangling`; on failures recreate the mirror automatically. When detaching SDKs, log concise progress (e.g., “Detaching cache for 3.13.0…done”). Wrap deletions in a Windows-aware retry helper to handle locked files gracefully.
- **Reason:** Stronger validation avoids silent corruption, and lightweight progress logs set user expectations without introducing a separate migration command.

### 6. Update docs, config help, and tests
- **Change:**
  - Rewrite docs (configuration, workflows, troubleshooting) to explain that the git cache is a mirror, can be deleted safely, and how to disable it.
  - Add release notes describing the auto-migration behavior and the one-time overhead when upgrading.
  - Extend tests (`git_clone_fallback_test.dart`, `flutter_service_test.dart`) to verify: mirror creation, auto-migration of non-bare repos, remote URL rewriting, and alternates cleanup.
- **Reason:** Documentation and automated coverage ensure future contributors keep the cache behavior aligned with the new guarantees.

## Rollout & Risk Mitigation

### Migration Execution Order

When `updateLocalMirror` runs:

1. **Check if migration is needed**
   - Detect if `gitCachePath` is missing, non-git, or a non-bare repo
   - If already a bare mirror, skip migration

2. **Detach ALL existing SDK versions first**
   - Find all versions with `.git/objects/info/alternates`
   - For each version:
     - Backup alternates file
     - Run `git repack -ad --quiet`
     - Verify with `git fsck --connectivity-only`
     - Remove alternates file
   - If any repack fails, restore backup and warn user

3. **Confirm all versions are detached**
   - Verify no version has alternates pointing to the cache
   - All versions must be self-contained before proceeding

4. **Remove the old cache**
   - Only after all versions are confirmed detached
   - Use Windows-aware retry helper for locked files

5. **Recreate cache as bare mirror**
   - Clone into temp directory: `git clone --mirror --progress <flutterUrl> <gitCachePath>.tmp`
   - Validate with `git fsck --strict --no-dangling`
   - Atomically swap into place

### Why This Order

- **Safety**: All versions become independent BEFORE touching the cache
- **Atomicity**: No partial state where some versions depend on a deleted cache
- **Recoverability**: If any repack fails, the old cache is still intact

## Migration Strategy (Finalized Decisions)
1. **No opt-out switch:** Auto-migration always runs; we intentionally avoid flags/env overrides so every machine converges on the safe layout without configuration drift.
2. **Git-only remediation:** Detaching alternates and mirror recreation only execute Git commands (plus small helper logs/backups). We never rerun `flutter` commands or other SDK tooling during migration, ensuring we do not mutate cached binaries or user data beyond Git metadata fixes.

## Performance Optimizations (Empirical Findings)

### Verification Speed
Use `git fsck --connectivity-only` instead of full fsck for **20x faster verification**:

| Method | Time | Safety Level |
|--------|------|--------------|
| `git fsck --no-dangling` | ~53s | Maximum (checks every object) |
| `git fsck --connectivity-only` | ~2.6s | Good (verifies all refs reachable) |
| Quick sanity check (rev-parse) | ~0.02s | Minimal (just verifies HEAD) |

**Recommendation:** Use `--connectivity-only` for detachment verification. It's sufficient to confirm repack succeeded.

### Repack Command
```bash
git repack -ad
```
- **Time:** 7-10 seconds per version
- **Size:** ~450MB per version (full Flutter history)
- **Compatibility:** Full (preserves all refs, tags, branches)

### Empirical Test Results

Tested on actual FVM installation with 7 versions:

| Version | Before | After | Repack Time |
|---------|--------|-------|-------------|
| 3.19.0 | 4K (fully dependent) | 437M | 7.3s |
| 3.32.4 | 4K (fully dependent) | 446M | 9.6s |
| stable | 24M (14 fragmented packs) | 446M (1 consolidated pack) | 8.6s |

**Total migration estimate for 7 versions:**
- Time: ~70 seconds (repack) + ~20 seconds (verification) = ~90 seconds
- Disk space: +2.8 GB (can reclaim ~500MB by deleting cache afterward)

### Updated Detachment Procedure

```bash
# 1. Backup alternates
cp .git/objects/info/alternates .git/objects/info/alternates.backup

# 2. Repack (copies all objects locally)
git repack -ad --quiet

# 3. Fast verification
git fsck --connectivity-only

# 4. Remove alternates
rm .git/objects/info/alternates
rm .git/objects/info/alternates.backup
```
