# Issue #1043: [BUG] Forced recreation of git cache on Mac everytime

## Metadata
- **Reporter**: @LahaLuhem
- **Created**: 2026-06-25T12:33:24Z
- **Reported Version**: FVM 4.1.1
- **Issue Type**: bug (git cache validation)
- **URL**: https://github.com/conceptadev/fvm/issues/1043
- **State**: CLOSED as completed (2026-06-25T16:28:33Z)

## Problem Summary
On macOS, FVM repeatedly failed git-cache `fsck` and recreated the local git cache from scratch on each version switch. Root cause: Finder `.DS_Store` files inside `refs/` invalidated `git fsck --connectivity-only`.

## Validation Steps
1. Confirmed the issue's supplied error names `refs/.DS_Store` as both `badRefName` and `badRefContent`.
2. Confirmed current `origin/main` contains commit `e21f48ab` (`fix: purge OS metadata files from git cache refs before fsck (#1043)`).
3. Confirmed the fix landed before the v4.1.2 release commit `6365c437`.
4. Confirmed GitHub closed the issue as completed on 2026-06-25.

## Evidence
```text
origin/main commit e21f48ab
  fix: purge OS metadata files from git cache refs before fsck (#1043)

GitHub issue state: CLOSED / COMPLETED
closedAt: 2026-06-25T16:28:33Z
```

Related code and tests are in:
- `lib/src/services/git_service.dart` - removes known OS metadata before `git fsck`.
- `test/services/git_service_test.dart` - regression coverage for metadata files while preserving detection of real corruption.

## Resolution
Maintainer confirmed and fixed the failure in `e21f48ab`: git cache validation removes `.DS_Store`, `Thumbs.db`, and `desktop.ini` from refs before `git fsck`, while genuine object corruption remains an error. The fix shipped in v4.1.2.

## Recommendation
**Action**: closed  
**Reason**: Fixed upstream; no further triage action.

## Notes
- Archived for bookkeeping after live GitHub sync (never had an open active JSON summary in this workspace).
