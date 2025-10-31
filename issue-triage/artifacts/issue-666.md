# Issue #666: [BUG] False positive: "Version mismatch detected" for non-numeric flutter versions

## Metadata
- **Reporter**: Andreas Mattsson (@AndreasMattsson)
- **Created**: 2024-02-28
- **Reported Version**: 3.0.12
- **Issue Type**: bug
- **URL**: https://github.com/leoafarias/fvm/issues/666

## Problem Summary
When a project pins versions that include a leading `v` (e.g. `v1.15.17`) or pre-release suffixes (`1.17.0-dev.3.1`), FVM repeatedly warns about a "Version mismatch" and prompts for repair—even though the cache is actually correct. The detection logic expects the cache’s `version` file to match the exact string used in `.fvmrc`, so any cosmetic difference is treated as corruption.

## Version Context
- Reported against: FVM 3.0.12
- Current version: v4.0.0
- Version-specific: no — `_verifyVersionMatch` still compares strings verbatim.
- Reason: Versions read from the cached SDK strip prefixes/suffixes (e.g., `1.15.17`) while the configured name may preserve them (`v1.15.17`).

## Validation Steps
1. Reviewed `CacheService._verifyVersionMatch` (`lib/src/services/cache_service.dart:27-37`); it returns false unless `version.flutterSdkVersion == version.version`.
2. Confirmed `FlutterVersion.version` preserves the leading `v` and any pre-release suffix present in `.fvmrc`.
3. Observed that `flutterSdkVersion` comes from the cached SDK’s `version` file, which typically omits prefixes and sometimes pre-release metadata.
4. Reproduced the mismatch scenario mentally: expected string `v1.15.17` vs cached file `1.15.17` → false negative, triggering the warning.

## Evidence
```
$ sed -n '20,45p' lib/src/services/cache_service.dart
  bool _verifyVersionMatch(CacheFlutterVersion version) {
    if (version.isChannel) return true;
    if (version.flutterSdkVersion == null) return true;

    return version.flutterSdkVersion == version.version;
  }
```

**Files/Code References:**
- [lib/src/services/cache_service.dart#L20](../lib/src/services/cache_service.dart#L20) – Exact string comparison.
- [lib/src/models/flutter_version_model.dart#L167](../lib/src/models/flutter_version_model.dart#L167) – `version` getter retains “v” prefix and pre-release suffixes.

## Current Status in v4.0.0
- [x] Still reproducible
- [ ] Already fixed
- [ ] Not applicable to v4.0.0
- [ ] Needs more information
- [ ] Cannot reproduce

## Troubleshooting/Implementation Plan

### Root Cause Analysis
Version mismatch detection is overly strict; it performs literal comparison instead of semantic comparison, so it flags harmless formatting differences.

### Proposed Solution
1. Normalize both strings before comparison:
   - Strip a leading `v` (case-insensitive).
   - Compare lower-cased values.
   - When either string contains pre-release/build suffixes, compare both the full value and base semver (split on `-`). If the base numbers match (`1.17.0` == `1.17.0`), treat as a match.
2. Extend `_verifyVersionMatch` to fall back to semantic comparison via `Version.parse`, handling pre-release metadata safely. If parsing fails (e.g., custom tags or commits), skip the mismatch check entirely.
3. Keep the existing mismatch warning for true divergences (e.g., cache `3.16.3` vs expected `3.19.0`).
4. Add unit tests covering:
   - `'v1.15.17'` vs `'1.15.17'`
   - `'1.17.0-dev.3.1'` vs `'1.17.0'` (should not trigger warning)
   - Actual mismatch (`3.16.0` vs `3.19.0`) still detected.
5. Update documentation/changelog to mention the improved detection and let users know the warning should only appear for genuinely mismatched caches.

### Alternative Approaches (if applicable)
- Disable mismatch detection for all non-strict semver strings. Simpler but would miss real regressions involving dev/beta releases.
- Store the original requested version alongside the cache (e.g., in a metadata file) and compare to that instead of the SDK’s `version` file.

### Dependencies & Risks
- Ensure new normalization doesn’t mask true mismatches for custom builds. For values we can’t parse, the current plan is to skip detection, which aligns with user expectations (custom versions shouldn’t warn).
- Must keep fallback behavior for CI/non-interactive mode unchanged (auto reinstall when genuine mismatch occurs).

### Related Code Locations
- [lib/src/models/cache_flutter_version_model.dart#L74](../lib/src/models/cache_flutter_version_model.dart#L74) – Source of `flutterSdkVersion` value.
- [lib/src/workflows/ensure_cache.workflow.dart#L28](../lib/src/workflows/ensure_cache.workflow.dart#L28) – Warning emitted when mismatch detected; adjust messaging if normalization applied.

## Recommendation
**Action**: validate-p1

**Reason**: False positives block normal workflows (users are prompted to repair valid caches on every command). Needs prompt fix to avoid repeated prompts.

## Notes
- Consider adding a debug log summarizing normalized values when mismatch is detected to assist future debugging.

---
**Validated by**: Code Agent
**Date**: 2025-10-31
