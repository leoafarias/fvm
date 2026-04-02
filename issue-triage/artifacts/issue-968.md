# Issue #968: [BUG] Fail agressively when SDK setup fails (e.g. missing dependencies)

## Metadata
- **Reporter**: @vhaudiquet
- **Created**: 2025-11-12
- **Reported Version**: 4.0.1
- **Issue Type**: bug
- **URL**: https://github.com/leoafarias/fvm/issues/968

## Problem Summary
On systems missing required tools (example: `unzip`), `fvm install` reports setup success and then emits a warning that the SDK is not setup. The mixed success/warn messages are confusing and make failures look successful.

## Version Context
- Reported against: v4.0.1
- Current version: v4.0.0+
- Version-specific: no
- Reason: setup success is based on command exit status, while setup completeness is derived from presence of the SDK `version` file.

## Validation Steps
1. Reviewed setup workflow behavior after `flutter --version`.
2. Reviewed how setup state is computed (`isSetup`/`isNotSetup`).
3. Reviewed dependency-resolution flow that warns when setup is incomplete.

## Evidence
```text
lib/src/workflows/setup_flutter.workflow.dart:16-21
- Runs FlutterService.setup(version) then logs success immediately.

lib/src/models/cache_flutter_version_model.dart:76-94
- Setup state is derived from <cache>/version file existence.

lib/src/workflows/resolve_project_deps.workflow.dart:18-21
- If version.isNotSetup => warns "Flutter SDK is not setup, skipping resolve dependencies."
```

**Files/Code References:**
- [lib/src/workflows/setup_flutter.workflow.dart:16](../lib/src/workflows/setup_flutter.workflow.dart#L16) - Setup success logging path.
- [lib/src/models/cache_flutter_version_model.dart:76](../lib/src/models/cache_flutter_version_model.dart#L76) - Setup completeness check.
- [lib/src/workflows/resolve_project_deps.workflow.dart:18](../lib/src/workflows/resolve_project_deps.workflow.dart#L18) - Follow-up warning behavior.

## Current Status in v4.0.0
- [x] Still reproducible
- [ ] Already fixed
- [ ] Not applicable to v4.0.0
- [ ] Needs more information
- [ ] Cannot reproduce

## Troubleshooting/Implementation Plan

### Root Cause Analysis
`SetupFlutterWorkflow` treats a successful `flutter --version` process as equivalent to completed setup. On missing host dependencies, Flutter can still return output while setup remains incomplete, so FVM prints success and only later detects `isNotSetup`.

### Proposed Solution
1. In [lib/src/workflows/setup_flutter.workflow.dart](../lib/src/workflows/setup_flutter.workflow.dart), re-read cache metadata after setup and verify `isSetup`.
2. If setup is incomplete, throw an `AppException` with actionable instructions (for example, install `unzip` on Linux).
3. Add a focused test covering "setup command returns but version file missing" and assert failure messaging.
4. Keep existing dependency warning as secondary guard, but avoid reporting setup success first.

### Alternative Approaches (if applicable)
- Add explicit preflight checks for `unzip`, `tar`, `xz` before setup. This gives earlier feedback but is platform/toolchain specific.

### Dependencies & Risks
- Different Flutter versions may emit different setup outputs; avoid brittle output parsing.
- Keep non-interactive/CI behavior deterministic (fail fast with explicit message).

### Related Code Locations
- [lib/src/services/flutter_service.dart:126](../lib/src/services/flutter_service.dart#L126) - Setup command invocation.
- [lib/src/commands/list_command.dart:118](../lib/src/commands/list_command.dart#L118) - Existing "Need setup" warning surfaced in list output.

## Recommendation
**Action**: validate-p2

**Reason**: Real UX/diagnostic bug that affects install reliability messaging; not a total blocker but causes misleading success states.

## Notes
- The reporter confirmed setup succeeds after installing `unzip`, reinforcing this as setup validation/message quality rather than version resolution logic.

---
**Validated by**: Code Agent  
**Date**: 2026-03-03
