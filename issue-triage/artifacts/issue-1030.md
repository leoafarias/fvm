# Issue #1030: [BUG] version mismatch prompt compares pubspec version against .fvmrc SDK and blocks non-interactive callers

## Metadata
- **Reporter**: rignaneseleo
- **Created**: 2026-05-12
- **Reported Version**: 4.1.0
- **Issue Type**: bug
- **URL**: https://github.com/leoafarias/fvm/issues/1030

## Resolution Update
- **Closed**: 2026-06-15
- **Resolution**: completed by PR #1033, "fix: avoid false cache version mismatches from git describe tags"
- **Related PR**: https://github.com/leoafarias/fvm/pull/1033
- **Triage action**: moved from `validated/p1-high/` to `closed/` during the 2026-06-16 sync.

## Problem Summary
In a git worktree with pre-commit hooks, FVM reports a version mismatch using the app `pubspec.yaml` version as the cached SDK version, then opens an interactive prompt that blocks non-interactive commit workflows. A follow-up comment reports orphaned `dartaotruntime` processes consuming CPU for days.

## Version Context
- Reported against: v4.1.0
- Current version: v4.0.0 triage baseline; branch package version is 4.0.5
- Version-specific: partially
- Reason: The current branch includes some CI/skip-input mitigation, but not full non-TTY detection and not clear validation for the pubspec-version misread path.

## Validation Steps
1. Reviewed current cache metadata loading and version mismatch handling.
2. Confirmed the prompt is skipped only when `context.skipInput` is true, which is currently driven by CI env vars or `--fvm-skip-input`.
3. Confirmed `Logger.select` exits in skip-input mode without a default selection unless callers handle it directly.
4. Checked tests and found CI/skip-input mismatch coverage exists, but no test for `!stdin.hasTerminal` pre-commit hooks or app `pubspec.yaml` version contamination.

## Evidence
```text
lib/src/workflows/ensure_cache.workflow.dart:50-90: mismatch prompt and skip-input auto-select path.
lib/src/utils/context.dart:169-174: skipInput only checks known CI env vars or explicit skip flag.
lib/src/models/cache_flutter_version_model.dart:92-116: cached SDK version loads from Flutter root metadata/version/git describe.
test/src/workflows/ensure_cache_ci_test.dart:20-84: CI and --fvm-skip-input tests exist.
```

**Files/Code References:**
- [../../lib/src/workflows/ensure_cache.workflow.dart](../../lib/src/workflows/ensure_cache.workflow.dart) - mismatch handling.
- [../../lib/src/utils/context.dart](../../lib/src/utils/context.dart) - skip-input detection.
- [../../lib/src/services/logger_service.dart](../../lib/src/services/logger_service.dart) - interactive select behavior.
- [../../lib/src/models/cache_flutter_version_model.dart](../../lib/src/models/cache_flutter_version_model.dart) - cached SDK metadata source.
- [../../test/src/workflows/ensure_cache_ci_test.dart](../../test/src/workflows/ensure_cache_ci_test.dart) - existing partial coverage.

## Current Status in v4.0.0
- [ ] Still reproducible
- [x] Already fixed
- [ ] Not applicable to v4.0.0
- [ ] Needs more information
- [ ] Cannot reproduce

## Troubleshooting/Implementation Plan

### Root Cause Analysis
The branch has mitigation for CI and explicit skip-input runs, but ordinary non-TTY callers such as git hooks are not necessarily detected as non-interactive. The reported app-version comparison also needs a regression test to prove cache metadata is never read from the project `pubspec.yaml` or a project `.fvm` metadata file by mistake.

### Proposed Solution
1. Extend [../../lib/src/utils/context.dart](../../lib/src/utils/context.dart) or [../../lib/src/services/logger_service.dart](../../lib/src/services/logger_service.dart) to treat `!stdin.hasTerminal` as non-interactive.
2. Make `Logger.select` support a safe default selection in skip-input mode rather than exiting unless every caller special-cases it.
3. Add a regression test with a project `pubspec.yaml` `version: 4.260508.0+0` and `.fvmrc` Flutter `3.38.3`, then assert FVM does not treat the app version as SDK metadata.
4. Add a non-TTY/pre-commit style test for `ensureCache` that asserts the command auto-selects a safe remediation and exits.
5. Investigate child process cleanup for killed parent commands and add explicit cleanup where FVM owns the child process.

### Alternative Approaches
- Require users to set `CI=true` or pass `--fvm-skip-input` in hooks. This is a workaround, not a sufficient default for agent/CI hooks.
- Remove automatic remediation prompts entirely and require explicit repair commands.

### Dependencies & Risks
- Auto-removing a mismatched cache in non-interactive mode is safer than hanging, but it can delete a locally modified SDK checkout.
- Broad `!stdin.hasTerminal` detection may affect users piping commands intentionally.
- Child process lifecycle cleanup differs by platform and may need platform-specific handling.

### Related Code Locations
- [../../lib/src/workflows/ensure_cache.workflow.dart](../../lib/src/workflows/ensure_cache.workflow.dart) - remediation selection.
- [../../lib/src/services/process_service.dart](../../lib/src/services/process_service.dart) - owned process execution and potential child cleanup.
- [../../lib/src/models/project_model.dart](../../lib/src/models/project_model.dart) - project pubspec parsing.

## Recommendation
**Action**: closed

**Reason**: GitHub issue #1030 is closed as completed, with PR #1033 removing the `git describe --tags` fallback that caused false cache version mismatches from app/pubspec tags. PR #1036 also addressed the non-TTY prompt hang path.

## Notes
The follow-up comment on 2026-05-19 strengthens priority because it reports multi-day orphaned `dartaotruntime` CPU use after the blocked prompt.

The original P1 priority was correct while open. It should no longer appear in the active P1 tracker.

---
**Validated by**: Code Agent
**Date**: 2026-06-10
