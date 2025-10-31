# Issue #421: [Feature Request] fvm install 2: infer the latest minor/patch version when supplying the major version

## Metadata
- **Reporter**: Thor Galle (@th0rgall)
- **Created**: 2022-05-19
- **Reported Version**: 2.x
- **Issue Type**: enhancement
- **URL**: https://github.com/leoafarias/fvm/issues/421

## Problem Summary
Users expect `fvm install 2` or `fvm install 2.10` to install the most recent release matching that prefix (similar to Node Version Manager). Today FVM treats `2` or `2.10` as literal git references, which fail because there are no branches with those names.

## Version Context
- Reported against: 2.x
- Current version: v4.0.0
- Version-specific: no — partial semver strings still throw errors.

## Validation Steps
1. `FlutterVersion.parse('2')` throws because it expects full semver (`x.y.z`).
2. `ValidateFlutterVersionWorkflow` directly calls `FlutterVersion.parse`, so commands reject partial versions early.
3. Release metadata (`FlutterReleaseClient`) already contains all releases; we can resolve the latest matching version in any channel.

## Evidence
```
$ fvm install 2
fatal: Remote branch 2 not found in upstream origin

$ sed -n '1,40p' lib/src/workflows/validate_flutter_version.workflow.dart
  FlutterVersion call(String version) {
    final flutterVersion = FlutterVersion.parse(version);
```

**Files/Code References:**
- [lib/src/workflows/validate_flutter_version.workflow.dart#L9](../lib/src/workflows/validate_flutter_version.workflow.dart#L9) – Immediately parses user input.
- [lib/src/services/releases_service/releases_client.dart](../lib/src/services/releases_service/releases_client.dart) – Provides release metadata for resolution.

## Current Status in v4.0.0
- [x] Still reproducible
- [ ] Already fixed
- [ ] Not applicable to v4.0.0
- [ ] Needs more information
- [ ] Cannot reproduce

## Troubleshooting/Implementation Plan

### Proposed Solution
1. Enhance version validation to detect partial semver input before parsing.
2. Implement a resolver that:
   - Accepts strings like `2`, `2@beta`, `2.10`, `2.10@stable`.
   - Uses `FlutterReleaseClient` to fetch releases and filter by channel (default to stable when omitted).
   - Picks the highest release matching the prefix.
3. Update `ValidateFlutterVersionWorkflow` (or add a new `ResolveVersionWorkflow`) to call this resolver first, then pass the concrete version to `FlutterVersion.parse`.
4. Surface clear messages when no release matches the prefix.
5. Add unit/integration tests covering major-only and major-minor inputs.
6. Document the behavior in the installation guide.

### Alternative Approaches
- Introduce `fvm install --latest 2` instead of implicit inference. Simpler, but the intuitive `fvm install 2` UX is preferable if we clearly document it.

### Dependencies & Risks
- Need to cache release metadata to avoid repeated downloads.
- Ensure we respect mirrors (`FLUTTER_STORAGE_BASE_URL`, etc.) when resolving.

### Related Code Locations
- [lib/src/workflows/ensure_cache.workflow.dart](../lib/src/workflows/ensure_cache.workflow.dart) – Already installs concrete versions once resolved.
- [docs/pages/documentation/guides/basic-commands.mdx](../docs/pages/documentation/guides/basic-commands.mdx) – Update command examples.

## Recommendation
**Action**: validate-p2

**Reason**: Improves UX by aligning with other version managers; moderate implementation effort using existing release metadata.

## Notes
- Combine with issue #577 so both constraints and partial versions share the same resolver utility.

---
**Validated by**: Code Agent
**Date**: 2025-10-31
