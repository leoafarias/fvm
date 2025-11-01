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
- [ ] Still reproducible
- [x] Already fixed
- [ ] Not applicable to v4.0.0
- [ ] Needs more information
- [ ] Cannot reproduce

## Resolution

PR #955 (“Improve cache version matching”, merged 2025-11-01) normalizes cache version comparisons:
- Strips a leading `v`, lowercases values, and compares semantic versions so tagged commits like `v1.15.17` stop triggering false positives.
- Keeps strict detection for genuine mismatches.
- Added regression tests covering prefixed, pre-release, and mismatched cases.

After the fix, `verifyCacheIntegrity` reports `CacheIntegrity.valid` for matching versions regardless of cosmetic differences.

## Recommendation
**Action**: closed  
**Reason**: Cache integrity check now semantically compares versions; false positives are resolved.

## Notes
- Regression tests live at `test/services/cache_service_issue_666_test.dart`.

---
**Validated by**: Code Agent  
**Date**: 2025-11-01
