# Issue #1009: Custom fork issues

## Metadata
- **Reporter**: @patrick-billingsley
- **Created**: 2026-01-02
- **Reported Version**: Not specified (recent v4 usage)
- **Issue Type**: fork workflow support / docs
- **URL**: https://github.com/leoafarias/fvm/issues/1009

## Problem Summary
Using a forked Flutter ref like `my-fork/3.35.6-patch` installs, but `fvm list` shows `0.0.0-unknown` for Flutter version. Reporter needs a team-shareable fork workflow for patched builds.

## Version Context
- Reported against: v4.x
- Current version: v4.0.0+
- Version-specific: no
- Reason: behavior depends on how fork refs map to Flutter's internal version metadata and how list output displays it.

## Validation Steps
1. Reviewed version parser behavior for non-semver fork refs.
2. Reviewed list output source for Flutter version field.
3. Reviewed custom fork documentation and known workaround in issue comments.

## Evidence
```text
lib/src/models/flutter_version_model.dart:121-139
- Non-semver refs are parsed as git references.

lib/src/services/cache_service.dart:64-83
- Fork directories are discovered and parsed as `fork/version`.

lib/src/commands/list_command.dart:64-80
- `fvm list` displays value from SDK `version` file (can appear as unknown for custom refs).

docs/pages/documentation/advanced/custom-version.mdx:53-61
- Docs call out `custom_` flow and full clone requirements for non-standard versions.
```

**Files/Code References:**
- [lib/src/models/flutter_version_model.dart:121](../lib/src/models/flutter_version_model.dart#L121) - Version classification fallback.
- [lib/src/commands/list_command.dart:64](../lib/src/commands/list_command.dart#L64) - Displayed Flutter version source.
- [docs/pages/documentation/advanced/custom-version.mdx:53](../docs/pages/documentation/advanced/custom-version.mdx#L53) - Custom version guidance.

## Current Status in v4.0.0
- [ ] Still reproducible
- [ ] Already fixed
- [ ] Not applicable to v4.0.0
- [ ] Needs more information
- [x] Cannot reproduce

## Troubleshooting/Implementation Plan

### Root Cause Analysis
The issue appears to be mostly about fork naming/version metadata expectations. Non-standard fork tags may not produce a standard Flutter version string, so list output can show unknown metadata even when checkout works.

### Proposed Solution
1. Improve docs for fork refs with patches:
   - Prefer semver-like tags where possible.
   - Document `custom_*` approach for truly custom snapshots.
2. Improve `fvm list` UX for fork refs when SDK version is unknown (show reference + fork context, not just unknown value).
3. Add a dedicated troubleshooting section for forked repos requiring team-wide reproducibility.
4. Ask reporter for a minimal fork repo example if behavior persists with recommended naming.

### Alternative Approaches (if applicable)
- Keep behavior as-is and provide support-only guidance in issue comments.

### Dependencies & Risks
- Any list formatting change must avoid breaking scripts parsing current table output.
- Fork metadata is partially controlled by Flutter tooling behavior.

### Related Code Locations
- [docs/pages/documentation/guides/basic-commands.mdx:351](../docs/pages/documentation/guides/basic-commands.mdx#L351) - Fork command docs.
- [lib/src/services/flutter_service.dart:212](../lib/src/services/flutter_service.dart#L212) - Checkout/reset behavior for non-channel refs.

## Recommendation
**Action**: validate-p3

**Reason**: Primarily docs/UX quality issue with a reported workaround; not a broad runtime blocker.

## Notes
- Existing workaround comment suggests semver-like ref (`my-fork/3.35.7`) avoided the unknown version display.

---
**Validated by**: Code Agent  
**Date**: 2026-03-03
