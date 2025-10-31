# Issue #688: Support a custom FLUTTER_STORAGE_BASE_URL as the source for Flutter package downloads

## Metadata
- **Reporter**: Jim Cook (@oravecz)
- **Created**: 2024-03-09
- **Reported Version**: 3.0.x
- **Issue Type**: enhancement
- **URL**: https://github.com/leoafarias/fvm/issues/688

## Problem Summary
Organizations that mirror Flutter SDK archives internally set `FLUTTER_STORAGE_BASE_URL` so the official `flutter` tool downloads engines and releases from their own origin. FVM, however, still clones Flutter from GitHub and fetches metadata from external domains, so installs fail in locked-down environments without GitHub/Google access. Users need FVM to honor their mirrored storage for the actual SDK payloads, not just metadata.

## Version Context
- Reported against: FVM 3.0.13
- Current version: v4.0.0
- Version-specific: no — v4 still clones from GitHub regardless of storage override.
- Reason: The install workflow is still Git-only; archive downloads via `FLUTTER_STORAGE_BASE_URL` are unsupported.

## Validation Steps
1. Reviewed `lib/src/services/flutter_service.dart` — `install()` always performs a `git clone` from `context.flutterUrl` (default `https://github.com/flutter/flutter.git`), with no branch for archive downloads.
2. Checked `lib/src/services/releases_service/releases_client.dart` and `models/version_model.dart`; while `FLUTTER_STORAGE_BASE_URL` is used to build metadata/`archiveUrl`, that data is never consumed during installs.
3. Grepped the codebase for `archiveUrl` usage and confirmed it is only exposed for presentation; no extraction workflow exists.
4. Verified documentation in `docs/pages/documentation/getting-started/configuration.mdx` — no guidance for mirrored storage or archive-based installs.

## Evidence
```
$ sed -n '140,220p' lib/src/services/flutter_service.dart
    try {
      final result = await _cloneWithFallback(
        repoUrl: repoUrl,
        versionDir: versionDir,
        version: version,
        channel: channel,
      );
      ...
    }

$ sed -n '1,60p' lib/src/services/releases_service/models/version_model.dart
  String get archiveUrl {
    return '${FlutterReleaseClient.storageUrl}/flutter_infra_release/releases/$archive';
  }
```

**Files/Code References:**
- [lib/src/services/flutter_service.dart#L167](../lib/src/services/flutter_service.dart#L167) – Git clone is the only installation mechanism.
- [lib/src/services/releases_service/models/version_model.dart#L54](../lib/src/services/releases_service/models/version_model.dart#L54) – Archive URL respects `FLUTTER_STORAGE_BASE_URL` but is unused.
- [lib/src/services/releases_service/releases_client.dart#L24](../lib/src/services/releases_service/releases_client.dart#L24) – Metadata download still attempts GitHub before mirrored storage, causing failures behind firewalls.

## Current Status in v4.0.0
- [x] Still reproducible
- [ ] Already fixed
- [ ] Not applicable to v4.0.0
- [ ] Needs more information
- [ ] Cannot reproduce

## Troubleshooting/Implementation Plan

### Root Cause Analysis
FVM’s cache strategy is Git-centric. Even though the release metadata exposes archive URLs that incorporate `FLUTTER_STORAGE_BASE_URL`, FVM never consumes them. Consequently, users without GitHub access cannot seed the cache via their mirrored storage, unlike the official `flutter` tool.

### Proposed Solution
1. Introduce an “archive” installation strategy:
   - Detect when `FLUTTER_STORAGE_BASE_URL` (or a new config flag) is set and there is no Git connectivity.
   - Fetch release metadata via `FlutterReleaseClient` (respecting `FLUTTER_RELEASES_URL` override) and download the `archive` tarball from the mirrored storage.
   - Extract the archive into the version cache directory, ensuring parity with the structure produced by Git clones.
2. Refactor `CacheService.ensureCache` / `FlutterService.install` to dispatch between Git and archive workflows based on config (`installStrategy: git|archive`), with fallback order configurable.
3. Add checksum validation using the mirrored `sha256` values to avoid corrupt archives.
4. Support air-gapped mirrors that only expose metadata by allowing the GitHub fetch step to be skipped when `FLUTTER_RELEASES_URL` or `FLUTTER_STORAGE_BASE_URL` are provided.
5. Update CLI config (`fvm config`) and documentation to describe:
   - New strategy flag/environment variable.
   - Required mirror layout (matching `flutter_infra_release/releases`).
   - Migration steps for existing caches.
6. Add integration tests (can mock HTTP responses) to confirm archive installs work cross-platform and honor custom storage URLs.

### Alternative Approaches (if applicable)
- Allow specifying a custom Git remote (`FVM_FLUTTER_URL` already exists). This helps if organizations mirror Git, but the reporter explicitly cannot use Git, so archive support is still needed.
- Provide a manual import command (`fvm cache import <path>`). Useful as stop-gap but still requires archive extraction support; keeping it as a complementary feature.

### Dependencies & Risks
- Archive extraction must replicate Flutter’s layout precisely; missing submodules or hooks could break SDK integrity.
- Need to ensure subsequent `fvm flutter` commands run `flutter precache` as needed, since archive installs skip the Git-based setup.
- Downloading large archives requires progress reporting and retry logic; reuse existing HTTP utilities with streaming.
- Documentation must caution about keeping mirrored metadata in sync with archives to avoid checksum mismatches.

### Related Code Locations
- [lib/src/services/cache_service.dart#L198](../lib/src/services/cache_service.dart#L198) – Determines cache directories; extend to accommodate archive installs.
- [lib/src/services/releases_service/releases_client.dart#L41](../lib/src/services/releases_service/releases_client.dart#L41) – Add option to bypass GitHub cache when custom URLs are provided.
- [docs/pages/documentation/getting-started/configuration.mdx#L70](../docs/pages/documentation/getting-started/configuration.mdx#L70) – Document new storage settings and strategies.

## Recommendation
**Action**: validate-p1

**Reason**: For enterprises behind restricted networks, FVM is unusable without archive installations. Supporting `FLUTTER_STORAGE_BASE_URL` is a high-impact enhancement that unblocks entire user segments.

## Notes
- Coordinate with #821 (`getFlutterSdkCommand`) so IDE integrations understand archives vs. git installs.
- Consider exposing a `fvm doctor` warning when `FLUTTER_STORAGE_BASE_URL` is set but the archive strategy is disabled.

---
**Validated by**: Code Agent
**Date**: 2025-10-31
