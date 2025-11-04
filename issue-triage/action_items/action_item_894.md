# Action Item: Issue #894 – Support Shared Multi-User Cache

## Objective
Enable multiple users on the same machine to share the FVM cache without permission errors by providing a group-writable cache mode.

## Current State (v4.0.0)
- `FlutterService.install` clones Flutter repos without adjusting `core.sharedRepository`, so files inherit the installing user’s umask (typically 644/755).
- `CacheService` performs no chmod/chgrp after cloning or extracting archives.
- Documentation lacks guidance for shared environments; each user must maintain their own cache.

## Root Cause
Cache directories are created with user-only write permissions, preventing other users in a shared environment from updating or reusing the cache.

## Implementation Steps
1. Introduce a configuration flag (e.g., `fvm config --shared-cache group` or env `FVM_SHARED_CACHE=group`) to opt into shared cache behavior.
2. When shared mode is active:
   - Clone repositories with `git clone --config core.sharedRepository=group` (and ensure `--separate-git-dir` logic still works).
   - After clone/extraction, run `chmod -R g+rwX` on the version directory and mirror cache to make it group writable (skip on Windows).
   - If a cache group is specified (e.g., env `FVM_CACHE_GROUP`), run `chgrp -R <group>` on cache directories and ensure new directories inherit the group (`setgid` bit via `chmod g+s`).
3. Update `CacheService` helper methods to apply the same permission adjustments when moving or pruning caches.
4. Provide documentation outlining prerequisites (common user group, `umask 0002`, enabling the flag) and instructions for administrators.
5. Add integration tests in a Linux environment (can use Docker or CI runner) that simulate two users:
   - User A installs a Flutter version with shared mode enabled.
   - User B uses the cached version without permission errors.

## Files to Modify
- `lib/src/services/flutter_service.dart`
- `lib/src/services/cache_service.dart`
- Possibly `lib/src/runner/config/` (for new config option)
- `docs/pages/documentation/getting-started/configuration.mdx`
- `scripts/install.sh` (if it needs to mention/group-prepare the cache)

## Validation & Testing
- Run unit/integration tests covering the new config flow.
- Manual verification on a Linux machine with two distinct users.
- Ensure Windows behavior remains unchanged (guard permission logic with `!Platform.isWindows`).

## Completion Criteria
- Shared cache mode implemented with documentation and tests.
- Issue #894 updated with rollout notes and closed.

## References
- Planning artifact: `issue-triage/artifacts/issue-894.md`
- GitHub issue: https://github.com/leoafarias/fvm/issues/894
