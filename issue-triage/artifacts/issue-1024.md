# Issue #1024: [Feature Request] Allow fvm use/install to function on windows without admin privileges

## Metadata
- **Reporter**: TDuffinNTU
- **Created**: 2026-03-13
- **Reported Version**: Not specified
- **Issue Type**: feature/platform usability
- **URL**: https://github.com/leoafarias/fvm/issues/1024

## Problem Summary
Windows users without administrator rights can be blocked by project symlink creation during `fvm use` or project install flows. The reporter requests a no-admin path that works by default or degrades gracefully.

## Version Context
- Reported against: current FVM 4.x Windows behavior
- Current version: v4.0.0 triage baseline; branch package version is 4.0.5
- Version-specific: no
- Reason: The behavior comes from project reference creation and Windows symlink privilege requirements.

## Validation Steps
1. Checked project reference creation and found symlink creation is gated by `context.privilegedAccess`.
2. Confirmed `privilegedAccess` is configurable and documented.
3. Checked tests that already cover privileged and non-privileged reference behavior.
4. Confirmed docs do not make the Windows no-admin workflow prominent, and the default remains privileged.

## Evidence
```text
lib/src/workflows/update_project_references.workflow.dart:61-65: skips local version symlink when privilegedAccess is false.
lib/src/workflows/update_project_references.workflow.dart:105-109: skips flutter_sdk symlink when privilegedAccess is false.
docs/pages/documentation/getting-started/configuration.mdx:39: privilegedAccess is documented.
test/src/workflows/update_project_references.workflow_test.dart:300-340: non-privileged mode creates version files but no symlinks.
```

**Files/Code References:**
- [../../lib/src/workflows/update_project_references.workflow.dart](../../lib/src/workflows/update_project_references.workflow.dart) - symlink creation and privileged fallback.
- [../../lib/src/workflows/update_vscode_settings.workflow.dart](../../lib/src/workflows/update_vscode_settings.workflow.dart) - absolute SDK path behavior when privileged access is disabled.
- [../../docs/pages/documentation/getting-started/configuration.mdx](../../docs/pages/documentation/getting-started/configuration.mdx) - config option list.
- [../../test/src/workflows/update_project_references.workflow_test.dart](../../test/src/workflows/update_project_references.workflow_test.dart) - current test coverage.

## Current Status in v4.0.0
- [x] Still reproducible
- [ ] Already fixed
- [ ] Not applicable to v4.0.0
- [ ] Needs more information
- [ ] Cannot reproduce

## Troubleshooting/Implementation Plan

### Root Cause Analysis
FVM already has a non-privileged mode, but it is not automatic and is not sufficiently discoverable for Windows users. The default path still attempts symlink creation, then the global error handler tells users to run with admin rights or enable Developer Mode.

### Proposed Solution
1. Add Windows-specific fallback in [../../lib/src/workflows/update_project_references.workflow.dart](../../lib/src/workflows/update_project_references.workflow.dart): if symlink creation fails with a privilege error, continue in non-privileged mode for that run and emit a clear warning.
2. Consider a first-run prompt or config write that sets `privilegedAccess: false` for users who choose no-admin mode.
3. Update Windows troubleshooting/docs to show `privilegedAccess: false`, expected `.fvm` contents, and IDE consequences.
4. Add tests that simulate `FileSystemException` from symlink creation and assert FVM does not fail the entire `use` workflow.

### Alternative Approaches
- Use Windows junctions (`mklink /J`) where possible for directory references.
- Use Windows unprivileged symlink flags when Developer Mode is enabled.
- Avoid symlinks entirely and configure tools with absolute cached SDK paths.

### Dependencies & Risks
- Android Studio workflows that depend on `.fvm/flutter_sdk` may still need an IDE-specific path strategy.
- Junctions and symlinks behave differently on deletion and path resolution.
- Silent fallback must be visible enough that users understand why project references differ.

### Related Code Locations
- [../../lib/src/runner.dart](../../lib/src/runner.dart) - current privilege error message.
- [../../lib/src/utils/context.dart](../../lib/src/utils/context.dart) - `privilegedAccess` config.
- [../../docs/pages/documentation/troubleshooting/git-safe-directory-windows.md](../../docs/pages/documentation/troubleshooting/git-safe-directory-windows.md) - existing Windows troubleshooting area.

## Recommendation
**Action**: validate-p2

**Reason**: Valid Windows usability/security request with an existing manual workaround. Prioritize as a platform improvement, not a new P1 outage, because `privilegedAccess: false` already provides a partial path.

## Notes
This is related to the older Windows setup/safe-directory cluster but is specifically about local project references and symlink privileges.

---
**Validated by**: Code Agent
**Date**: 2026-06-10
