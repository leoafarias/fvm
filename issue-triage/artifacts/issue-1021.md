# Issue #1021: Bump pub_updater to ^0.5.0

## Metadata
- **Reporter**: vladimir-ionita
- **Created**: 2026-03-10
- **Reported Version**: 4.0.5
- **Issue Type**: dependency maintenance
- **URL**: https://github.com/leoafarias/fvm/issues/1021

## Problem Summary
FVM currently depends on `pub_updater: ^0.4.0`, which conflicts with packages that require `pub_updater: ^0.5.0` in Dart pub workspaces where dependency resolution is shared.

## Version Context
- Reported against: v4.0.5
- Current version: v4.0.0 triage baseline; branch package version is 4.0.5
- Version-specific: no
- Reason: The dependency constraint is in the package manifest and affects consumers resolving FVM as a dependency.

## Validation Steps
1. Confirmed the direct dependency in `pubspec.yaml`.
2. Checked the lockfile to confirm the current locked version is `0.4.0`.
3. Checked GitHub PRs and found open PR #1022, which directly bumps the dependency and closes this issue.

## Evidence
```text
pubspec.yaml:23:  pub_updater: ^0.4.0
pubspec.lock:548-555: pub_updater locked at 0.4.0
gh pr list: #1022 OPEN chore: bump pub_updater to ^0.5.0
```

**Files/Code References:**
- [../../pubspec.yaml](../../pubspec.yaml) - direct `pub_updater` dependency.
- [../../pubspec.lock](../../pubspec.lock) - current resolved package version.
- [../../lib/src/runner.dart](../../lib/src/runner.dart) - uses `PubUpdater`.

## Current Status in v4.0.0
- [x] Still reproducible
- [ ] Already fixed
- [ ] Not applicable to v4.0.0
- [ ] Needs more information
- [ ] Cannot reproduce

## Troubleshooting/Implementation Plan

### Root Cause Analysis
The package manifest constrains `pub_updater` to `^0.4.0`. Projects that also depend on tooling requiring `^0.5.0` cannot resolve a single compatible version in shared pub workspaces.

### Proposed Solution
1. Review and merge PR #1022 if CI remains green.
2. Verify `pub_updater` API usage in [../../lib/src/runner.dart](../../lib/src/runner.dart) still compiles against `0.5.x`.
3. Run `dart pub get`, `dart analyze`, and the command/update-check tests.
4. Release a patch version so workspace users can resolve the dependency.

### Alternative Approaches
- Use a wider lower bound such as `>=0.4.0 <0.6.0` if both 0.4.x and 0.5.x APIs are compatible.

### Dependencies & Risks
- Update-check behavior depends on `PubUpdater.isUpToDate` and `getLatestVersion`; those methods must remain compatible.
- Lockfile refresh may update transitive packages.

### Related Code Locations
- [../../pubspec.yaml](../../pubspec.yaml) - dependency constraint.
- [../../lib/src/runner.dart](../../lib/src/runner.dart) - update-check integration.

## Recommendation
**Action**: validate-p2

**Reason**: Valid dependency compatibility issue with an open targeted PR, but not a runtime/install blocker for most users.

## Notes
PR #1022 was open and mergeable during the 2026-06-10 sync.

---
**Validated by**: Code Agent
**Date**: 2026-06-10
