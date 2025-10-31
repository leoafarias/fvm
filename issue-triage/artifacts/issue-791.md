# Issue #791: [Feature Request] Namespace versions and branches for Flutter forks

## Metadata
- **Reporter**: @leoafarias
- **Created**: 2024-11-04
- **Reported Version**: n/a (enhancement)
- **Issue Type**: enhancement
- **URL**: https://github.com/leoafarias/fvm/issues/791

## Problem Summary
The request asked for forked Flutter versions to be namespaced so that different forks (e.g., `shorebird/stable`) do not collide in the cache or CLI. FVM v4 already organizes cached SDKs by `~/.fvm/versions/<fork>/<version>` and allows referencing them via `alias/version`.

## Version Context
- Reported against: v3.x
- Current version: v4.0.0
- Version-specific: no
- Reason: Fork namespacing has existed since v3 and continues in v4.

## Validation Steps
1. Reviewed `CacheService.getVersionCacheDir` confirming forked versions are stored under `<fork>/<version>` (lines 140-148).
2. Verified `moveToSdkVersionDirectory` preserves the fork prefix when normalizing versions (lines 223-246).
3. Checked `FlutterVersion` model—`fromFork` and `name` parsing treat `fork/version` as distinct entries (lines 142-170).

## Evidence
```
lib/src/services/cache_service.dart:140-148  // Forked versions create nested directories
lib/src/services/cache_service.dart:223-246  // Maintains fork prefix when moving cache entries
lib/src/models/flutter_version_model.dart:142-170  // Parses fork prefix and exposes helper getters
```

**Files/Code References:**
- [lib/src/services/cache_service.dart:140](../lib/src/services/cache_service.dart#L140) – Cache directory layout for forks.
- [lib/src/services/cache_service.dart:223](../lib/src/services/cache_service.dart#L223) – Preserves fork metadata.
- [lib/src/models/flutter_version_model.dart:142](../lib/src/models/flutter_version_model.dart#L142) – Fork-aware parsing helpers.

## Current Status in v4.0.0
- [ ] Still reproducible
- [x] Already fixed
- [ ] Not applicable to v4.0.0
- [ ] Needs more information
- [ ] Cannot reproduce

## Troubleshooting/Implementation Plan

### Root Cause Analysis
Feature already exists; the issue stemmed from uncertainty about how to address forks in CLI UX.

### Proposed Solution
1. Close the issue explaining the existing `alias/version` workflow and cache layout.
2. Link to docs covering custom forks (`fvm fork`, `--flutter-url`) for clarity.

### Alternative Approaches
- None needed; existing behavior satisfies the request.

### Dependencies & Risks
- Documentation clarity only.

### Related Code Locations
- [docs/pages/documentation/advanced/custom-version.mdx](../docs/pages/documentation/advanced/custom-version.mdx) – Shows fork commands users can follow.

## Recommendation
**Action**: resolved  
**Reason**: Fork namespacing is implemented; communicating the workflow is sufficient.

## Draft Reply
```
Thanks for the suggestion! FVM already namespaces forked SDKs.

- Cached directory layout: `~/.fvm/versions/<fork>/<version>`
- CLI usage: `fvm fork add shorebird https://github.com/shorebirdtech/shorebird.git`, then `fvm use shorebird/stable`

Because the behavior you requested is already in place I’m going to close this issue, but feel free to reach out if you spot any gaps in the fork workflow.
```

## Notes
- Consider adding a quick “Cache layout for forks” blurb to the custom-version docs for extra clarity.

---
**Validated by**: Code Agent  
**Date**: 2025-10-31
