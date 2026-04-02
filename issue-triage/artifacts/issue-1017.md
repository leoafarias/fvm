# Issue #1017: [BUG] fvm use doesn't work

## Metadata
- **Reporter**: @TheCarpetMerchant
- **Created**: 2026-03-02
- **Reported Version**: 4.0.5 (Windows 11)
- **Issue Type**: bug report (likely environment/config mismatch)
- **URL**: https://github.com/leoafarias/fvm/issues/1017

## Problem Summary
Reporter expects `flutter --version` to switch immediately after `fvm use 3.19.0`, but diagnostics show PATH and IDE SDK paths still point to a global Flutter installation.

## Version Context
- Reported against: v4.0.5
- Current version: v4.0.0+
- Version-specific: no
- Reason: logs align with expected FVM behavior when shell/IDE PATH remains global.

## Validation Steps
1. Reviewed reporter-provided `fvm use --verbose` and `fvm doctor` excerpts.
2. Reviewed `UseVersionWorkflow` messaging for VS Code terminal restart behavior.
3. Reviewed docs for proxy command behavior and terminal rerouting expectations.

## Evidence
```text
Reporter logs
- `fvm use` ends with: "Running on VsCode, please restart the terminal to apply changes."
- `fvm doctor` shows PATH points to global Flutter and IDE paths do not match pinned version.

lib/src/workflows/use_version.workflow.dart:72-79
- Explicitly warns that VS Code terminal restart is required.

docs/pages/documentation/guides/running-flutter.mdx:37-45
- Recommends `fvm flutter`/`fvm dart`; direct `flutter` depends on PATH/reroute setup.
```

**Files/Code References:**
- [lib/src/workflows/use_version.workflow.dart:72](../lib/src/workflows/use_version.workflow.dart#L72) - VS Code terminal restart guidance.
- [lib/src/commands/doctor_command.dart:83](../lib/src/commands/doctor_command.dart#L83) - IDE/path mismatch diagnostics.
- [docs/pages/documentation/guides/running-flutter.mdx:37](../docs/pages/documentation/guides/running-flutter.mdx#L37) - Command resolution guidance.

## Current Status in v4.0.0
- [ ] Still reproducible
- [ ] Already fixed
- [ ] Not applicable to v4.0.0
- [x] Needs more information
- [x] Cannot reproduce

## Troubleshooting/Implementation Plan

### Root Cause Analysis
Available evidence points to environment/path configuration, not a confirmed failure in `fvm use` itself. FVM pins the project version, but unqualified `flutter` continues to resolve global binaries when terminal/IDE path injection is not active.

### Proposed Solution
1. Request a minimal reproducible sequence with exact commands and shell context:
   - `fvm flutter --version`
   - `flutter --version` in a **new** VS Code terminal
   - `where flutter` (Windows)
2. Confirm Dart Code extension settings and version (`dart.addSdkToTerminalPath`).
3. If mismatch persists with fresh terminal and correct extension settings, collect `fvm doctor` + PATH + workspace settings.json for deeper investigation.
4. Add a docs troubleshooting snippet for Windows VS Code terminal PATH order if needed.

### Alternative Approaches (if applicable)
- If repeated reports match this pattern, add an explicit post-`fvm use` doctor hint when global `flutter` remains ahead in PATH.

### Dependencies & Risks
- Requires reporter follow-up; current evidence is insufficient to mark as core regression.

### Related Code Locations
- [docs/pages/documentation/guides/vscode.mdx:31](../docs/pages/documentation/guides/vscode.mdx#L31) - VS Code integration behavior.
- [docs/pages/documentation/getting-started/faq.md:57](../docs/pages/documentation/getting-started/faq.md#L57) - Windows path-order troubleshooting context.

## Recommendation
**Action**: needs-info

**Reason**: Report lacks a minimal confirmed reproduction of a core FVM bug; diagnostics currently point to environment configuration.

## Notes
- Candidate duplicate pattern of earlier IDE/path reports; keep open pending reporter confirmation.

---
**Validated by**: Code Agent  
**Date**: 2026-03-03
