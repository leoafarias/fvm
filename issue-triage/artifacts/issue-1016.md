# Issue #1016: [Feature Request] support installing the latest patch for a stable version without taking latest stable

## Metadata
- **Reporter**: @scopendo
- **Created**: 2026-02-19
- **Reported Version**: N/A (feature request)
- **Issue Type**: enhancement
- **URL**: https://github.com/leoafarias/fvm/issues/1016

## Problem Summary
User wants `fvm install 3.38` to resolve to latest `3.38.x` while keeping minor version pinned (instead of moving to current `stable` minor).

## Version Context
- Reported against: v4.x behavior
- Current version: v4.0.0+
- Version-specific: no
- Reason: current parser expects full semver for releases and treats partial versions as git refs.

## Validation Steps
1. Reviewed version parsing behavior for partial versions.
2. Reviewed install command docs for accepted version formats.
3. Reviewed release lookup flow for full-version resolution.

## Evidence
```text
lib/src/models/flutter_version_model.dart:121-139
- Non-semver values (e.g., 3.38) are parsed as git references.

lib/src/services/flutter_service.dart:158-169
- Release-channel inference uses exact release lookup by version string.

docs/pages/documentation/guides/basic-commands.mdx:79
- Install docs currently describe explicit version input, not minor-line wildcard resolution.
```

**Files/Code References:**
- [lib/src/models/flutter_version_model.dart:121](../lib/src/models/flutter_version_model.dart#L121) - Semver validation behavior.
- [lib/src/services/flutter_service.dart:158](../lib/src/services/flutter_service.dart#L158) - Release-channel lookup with exact version.
- [docs/pages/documentation/guides/basic-commands.mdx:79](../docs/pages/documentation/guides/basic-commands.mdx#L79) - Current install argument documentation.

## Current Status in v4.0.0
- [x] Still reproducible
- [ ] Already fixed
- [ ] Not applicable to v4.0.0
- [ ] Needs more information
- [ ] Cannot reproduce

## Troubleshooting/Implementation Plan

### Root Cause Analysis
Current parser and install flow are designed for full semantic versions/channels/refs. Minor-only constraints are not resolved via release metadata.

### Proposed Solution
1. Add a "partial version" resolver before normal parse/install flow.
2. When input matches `major.minor` pattern, fetch releases and pick newest patch in that minor line.
3. Surface resolved version in CLI output (`3.38 -> 3.38.10`) for transparency.
4. Add tests for:
   - valid partials,
   - no matching releases,
   - channel override interactions.
5. Document behavior and edge-cases in `basic-commands` and quick-reference.

### Alternative Approaches (if applicable)
- Add explicit flag (`--latest-patch`) to avoid changing interpretation of partial refs.

### Dependencies & Risks
- Potential ambiguity with branch names matching `x.y` patterns in custom forks.
- Must avoid breaking existing workflows that rely on git-ref interpretation.

### Related Code Locations
- [lib/src/workflows/validate_flutter_version.workflow.dart:9](../lib/src/workflows/validate_flutter_version.workflow.dart#L9) - Entry point for version validation.
- [lib/src/services/releases_service/releases_client.dart:95](../lib/src/services/releases_service/releases_client.dart#L95) - Release retrieval API.

## Recommendation
**Action**: validate-p3

**Reason**: Useful enhancement for version-management ergonomics; not a blocking defect.

## Notes
- Could be introduced behind a flag first to minimize behavior surprises.

---
**Validated by**: Code Agent  
**Date**: 2026-03-03
