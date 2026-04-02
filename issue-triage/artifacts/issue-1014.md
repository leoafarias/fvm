# Issue #1014: [BUG] Installing a flutter SDK failing

## Metadata
- **Reporter**: @coups-cs
- **Created**: 2026-02-13
- **Reported Version**: 4.0.5
- **Issue Type**: bug
- **URL**: https://github.com/leoafarias/fvm/issues/1014

## Problem Summary
`fvm install` fails on first install with clone/validation errors (`Unknown error` or `Flutter SDK is not a valid git repository after clone`). Manual clone using the same command can succeed, indicating a fragile post-clone validation/retry path.

## Version Context
- Reported against: v4.0.5
- Current version: v4.0.0+
- Version-specific: no
- Reason: failure path is in shared install/clone validation logic.

## Validation Steps
1. Reviewed clone + post-clone validation logic in `FlutterService.install`.
2. Reviewed process error mapping in `ProcessService` (where "Unknown error" is emitted).
3. Reviewed issue thread workaround confirming manual clone recovers the install.

## Evidence
```text
lib/src/services/flutter_service.dart:195-209
- After clone, FVM requires GitDir.isGitDir(path) == true or throws explicit AppException.

lib/src/services/flutter_service.dart:275-317
- On failures, cache is removed and exceptions are rethrown; no targeted retry after git-dir validation failure.

lib/src/services/process_service.dart:21-24
- If command fails without stdout/stderr, error message is collapsed to "Unknown error".
```

**Files/Code References:**
- [lib/src/services/flutter_service.dart:195](../lib/src/services/flutter_service.dart#L195) - Clone and git-dir validation branch.
- [lib/src/services/flutter_service.dart:206](../lib/src/services/flutter_service.dart#L206) - "not a valid git repository" throw site.
- [lib/src/services/process_service.dart:21](../lib/src/services/process_service.dart#L21) - "Unknown error" mapping.

## Current Status in v4.0.0
- [x] Still reproducible
- [ ] Already fixed
- [ ] Not applicable to v4.0.0
- [ ] Needs more information
- [ ] Cannot reproduce

## Troubleshooting/Implementation Plan

### Root Cause Analysis
The install flow has limited diagnostics for clone edge-cases and no recovery path when clone exits but repository validation fails. The resulting errors are generic and hard to action.

### Proposed Solution
1. Add structured diagnostics before throwing at git-dir validation:
   - whether target exists,
   - whether `.git` exists and is file/dir,
   - `git -C <dir> rev-parse --is-inside-work-tree` output.
2. If clone used `--reference` and validation fails, auto-clean and retry once without `--reference`.
3. Improve error surfacing for clone/setup failures by preserving stderr context where available.
4. Add integration tests mocking:
   - clone success + invalid git dir,
   - reference clone edge-case + fallback success.

### Alternative Approaches (if applicable)
- Keep behavior and document manual clone workaround. Not preferred due poor UX and recurring support cost.

### Dependencies & Risks
- Retry logic must avoid masking real repository corruption.
- Additional diagnostics should be verbose-mode friendly and not overwhelm default output.

### Related Code Locations
- [lib/src/workflows/ensure_cache.workflow.dart:168](../lib/src/workflows/ensure_cache.workflow.dart#L168) - Install progress + failure wrapping.
- [lib/src/services/flutter_service.dart:17](../lib/src/services/flutter_service.dart#L17) - `_cloneWithFallback` logic.

## Recommendation
**Action**: validate-p1

**Reason**: Core installation flow regression/blocker; high user impact and clear need for resilient fallback + diagnostics.

## Notes
- Issue comments report cross-machine occurrence, increasing confidence this is not a single-user environment anomaly.

---
**Validated by**: Code Agent  
**Date**: 2026-03-03
