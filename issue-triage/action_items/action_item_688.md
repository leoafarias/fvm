# Action Item: Issue #688 - Archive Installs for Storage Mirrors

**Priority**: P1 (the only current P1)

**Revalidated**: 2026-08-11 against FVM 4.1.2, fetched `origin/main`, and live PR #1013

**Issue**: https://github.com/conceptadev/fvm/issues/688

**Implementation PR**: https://github.com/conceptadev/fvm/pull/1013

## Outcome Required

Allow official Flutter releases to be installed from SDK archives whose
metadata and payload URLs honor `FLUTTER_RELEASES_URL` and
`FLUTTER_STORAGE_BASE_URL`. A restricted-network user must not need GitHub
clone access, and every archive must be checksum-validated before becoming an
active cache entry.

## Current Evidence

- `origin/main` v4.1.2 still installs SDKs through the Git-based path.
- Release metadata already exposes `archiveUrl` and `sha256`, but the install
  workflow does not consume them.
- `FLUTTER_GIT_URL` supports a mirrored Git repository, not organizations that
  mirror precompiled SDK/custom-engine archives.
- PR #1013 implements an explicit `--archive` path, staging/backup recovery,
  timeouts, TLS diagnostics, checksum validation, and cross-platform tests.
- PR #1013 is still open and GitHub reports it as unstable. Its Linux `Test` check
  fails in the `fvm_mcp` format gate; macOS, Windows, and migration checks pass.
- The PR was last updated on 2026-06-22, while `main` has advanced through
  2026-08-06 and the PR has no review decision.

## Immediate Next Actions

1. Rebase or merge current `main` into PR #1013 and keep the diff scoped to
   archive installation. Pay particular attention to the generated mapper
   churn and unrelated `fvm_mcp`/workflow changes in the existing PR diff.
2. Run formatting in `fvm_mcp` and commit only the required formatting changes
   so the failing Linux `Test` job can rerun.
3. Review the public behavior before merge:
   - archive mode is explicit and preserved through install/use retry paths;
   - custom mirror metadata bypasses unavailable public endpoints;
   - forks, commits, and unsupported refs fail with actionable guidance;
   - channel qualifiers resolve to the intended platform/architecture asset.
4. Review failure safety:
   - verify SHA-256 before finalization;
   - never replace a valid cached SDK with a partial download/extraction;
   - recover interrupted staging/backup state;
   - clean temporary data without masking the original error;
   - handle HTTP timeout, TLS, disk-space, and extraction failures.
5. Rerun the complete required verification after the rebase and fixes.

## Required Verification

```bash
dart run build_runner build --delete-conflicting-outputs
dart analyze --fatal-infos
dcm analyze lib
dart test
cd fvm_mcp && dart format --output=none --set-exit-if-changed . && dart test
```

Because this change affects `FlutterService`, `EnsureCacheWorkflow`, and
install/use behavior, also run the isolated manual branch smoke test in
`docs/pages/documentation/guides/manual-smoke-test.md`. Add or retain focused
tests for checksum mismatch, interrupted-finalization recovery, channel
qualifiers, platform extraction, mirror URL construction, cache preservation,
and `useArchive` propagation.

## Closure Gate

Do not close #688 when CI merely turns green. Close it only after:

1. PR #1013 (or a replacement with equivalent scope) is reviewed and merged.
2. Archive installation is exercised with a custom metadata URL and storage
   base URL without GitHub clone access.
3. The behavior is documented, released, and the released version is named in
   the issue closure comment.

## Risks to Call Out in Review

- PR #1013 is large and old enough to contain merge drift or regenerated files
  unrelated to the feature.
- Platform extraction permissions and archive root layouts differ across
  Windows, macOS, and Linux.
- Mirror metadata can be internally consistent yet point to a missing archive;
  error messages must identify the resolved URL without exposing credentials.
- Archive-installed SDKs do not have Git history, so commands that assume a Git
  checkout must be tested or explicitly unsupported.
