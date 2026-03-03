# Issue #1008: [BUG] versions not auto update

## Metadata
- **Reporter**: @jopmiddelkamp
- **Created**: 2025-12-31
- **Reported Version**: 4.0.5
- **Issue Type**: bug / monorepo integration gap
- **URL**: https://github.com/leoafarias/fvm/issues/1008

## Problem Summary
Running `fvm use 3.38.5` in a Melos workspace did not update the workspace `sdkPath` declaration (`melos.sdkPath` in root `pubspec.yaml`). Reporter also asked if `environment.sdk` / `environment.flutter` should be auto-updated.

## Version Context
- Reported against: v4.0.5
- Current version: v4.0.0+
- Version-specific: no
- Reason: current implementation updates only `melos.yaml` root `sdkPath`, not `pubspec.yaml` `melos.sdkPath`.

## Validation Steps
1. Reviewed Melos settings workflow logic and file discovery strategy.
2. Verified update target key/path and interactive confirmation behavior.
3. Reviewed monorepo docs describing `melos.yaml`-based configuration.

## Evidence
```text
lib/src/workflows/update_melos_settings.workflow.dart:24-35
- Searches only for `melos.yaml` (not pubspec-based Melos config).

lib/src/workflows/update_melos_settings.workflow.dart:82-101
- Reads/updates root `sdkPath` key in that file.

docs/pages/documentation/guides/monorepo.md:18-24
- Docs describe automatic management of `sdkPath` in `melos.yaml`.
```

**Files/Code References:**
- [lib/src/workflows/update_melos_settings.workflow.dart:24](../lib/src/workflows/update_melos_settings.workflow.dart#L24) - File discovery behavior.
- [lib/src/workflows/update_melos_settings.workflow.dart:82](../lib/src/workflows/update_melos_settings.workflow.dart#L82) - Existing update target.
- [docs/pages/documentation/guides/monorepo.md:18](../docs/pages/documentation/guides/monorepo.md#L18) - Documented behavior scope.

## Current Status in v4.0.0
- [x] Still reproducible
- [ ] Already fixed
- [ ] Not applicable to v4.0.0
- [ ] Needs more information
- [ ] Cannot reproduce

## Troubleshooting/Implementation Plan

### Root Cause Analysis
FVM currently assumes Melos configuration is expressed in `melos.yaml`. Workspaces using `melos` block inside `pubspec.yaml` are not detected/updated by the existing workflow.

### Proposed Solution
1. Extend `UpdateMelosSettingsWorkflow` to detect Melos config in root `pubspec.yaml` when `melos.yaml` is absent.
2. Update `melos.sdkPath` in `pubspec.yaml` using a comment-preserving YAML edit flow.
3. Keep current `melos.yaml` behavior as-is for backward compatibility.
4. Add tests for both config styles and nested monorepo relative path calculation.
5. Treat `environment.sdk` / `environment.flutter` update as separate feature scope (opt-in only, no silent mutation by default).

### Alternative Approaches (if applicable)
- Documentation-only approach: explicitly state only `melos.yaml` is auto-managed. Lower effort but leaves modern pubspec-based setups unsolved.

### Dependencies & Risks
- YAML editing must preserve user formatting/comments where possible.
- Must avoid rewriting unrelated `pubspec.yaml` sections.

### Related Code Locations
- [lib/src/workflows/use_version.workflow.dart:54](../lib/src/workflows/use_version.workflow.dart#L54) - Melos workflow invocation.
- [lib/src/models/project_model.dart:25](../lib/src/models/project_model.dart#L25) - Pubspec is already loaded and available for reuse.

## Recommendation
**Action**: validate-p2

**Reason**: Valid monorepo integration bug for active workflows; not a global install blocker but impacts teams relying on Melos workspace automation.

## Notes
- The `environment.sdk`/`environment.flutter` mutation request should be tracked as a separate enhancement due risk of unintended dependency constraint changes.

---
**Validated by**: Code Agent  
**Date**: 2026-03-03
