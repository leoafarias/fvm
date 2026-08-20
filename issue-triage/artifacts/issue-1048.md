# Issue #1048: [BUG] Do not warn when VS Code settings management is disabled

## Metadata
- **Reporter**: woteska
- **Created**: 2026-07-16
- **Reported Version**: FVM 4.1.2
- **Issue Type**: bug (CLI UX / configuration)
- **URL**: https://github.com/conceptadev/fvm/issues/1048

## Problem Summary
Projects that intentionally set `"updateVscodeSettings": false` (and manage `.vscode/settings.json` themselves, e.g. `"dart.flutterSdkPath": ".fvm/flutter_sdk"`) still get a **WARN** on every `fvm use`:

```text
[WARN] You are using VSCode, but fvm is not managing VSCode settings for this project.
Please remove "updateVscodeSettings: false" from .fvmrc
```

That message treats deliberate opt-out as misconfiguration and creates noise in local terminals and CI.

## Version Context
- Reported against: FVM 4.1.2
- Current package version on branch: 4.1.1+
- Version-specific: no
- Reason: Behavior is in current VS Code workflow; flag exists by design.

## Validation Steps
1. Confirmed `ProjectConfig.updateVscodeSettings` is a first-class config field.
2. Read `UpdateVsCodeSettingsWorkflow.call`: when `updateVscodeSettings` is false, it correctly skips writing settings, then **warns** if VS Code is detected via env or project files.
3. Confirmed test `should not update VS Code settings when config disables it` only asserts settings are not written — it does **not** assert absence of the warning.
4. `isVsCode()` is true when `TERM_PROGRAM == vscode`; `_hasVsCodeFiles` is true when `.vscode` exists — both common in intentional dual-IDE repos.

## Evidence
```dart
// lib/src/workflows/update_vscode_settings.workflow.dart:271-285
if (!updateVscodeSettings) {
  logger.debug('...does not manage VSCode settings...');
  if (isVsCode() || _hasVsCodeFiles(project) || _findWorkspaceFile(project) != null) {
    logger.warn(
      'You are using $kVsCode, but $kPackageName is '
      'not managing $kVsCode settings for this project. '
      'Please remove "updateVscodeSettings: false" from $kFvmConfigFileName',
    );
  }
  return null;
}
```

**Files/Code References:**
- [lib/src/workflows/update_vscode_settings.workflow.dart:271](../../lib/src/workflows/update_vscode_settings.workflow.dart#L271) – warn on intentional disable
- [lib/src/utils/helpers.dart:75](../../lib/src/utils/helpers.dart#L75) – `isVsCode()`
- [test/src/workflows/update_vscode_settings.workflow_test.dart:110](../../test/src/workflows/update_vscode_settings.workflow_test.dart#L110) – disable path (no warn assertion)
- [lib/src/models/config_model.dart](../../lib/src/models/config_model.dart) – `updateVscodeSettings` field

## Current Status in v4.0.0 / 4.1.x
- [x] Still reproducible
- [ ] Already fixed
- [ ] Not applicable to v4.0.0
- [ ] Needs more information
- [ ] Cannot reproduce

## Troubleshooting/Implementation Plan
**IMPORTANT**: Research and plan only — do not implement during triage.

### Root Cause Analysis
The flag means “do not manage VS Code settings.” Detection of VS Code / `.vscode` then emits a warn that tells users to **remove** the flag — the opposite of supporting intentional opt-out. Debug log alone is appropriate; warn is incorrect for explicit configuration.

### Proposed Solution
1. **Primary fix (recommended):** When `updateVscodeSettings == false` **explicitly** in project config, skip the warn entirely; keep `logger.debug` only.
2. **Do not add** `warnOnUnmanagedVscodeSettings` unless product wants an opt-in warn for accidental disables — YAGNI given explicit false already expresses intent.
3. **Optional nuance:** If the flag is unset (default true) and settings update fails, keep existing failure messaging; only silence intentional false.
4. **Tests:** Extend `update_vscode_settings.workflow_test.dart` to capture logger output and assert **no warn** when `updateVscodeSettings: false` and `.vscode` exists.
5. **Docs:** Note that `updateVscodeSettings: false` is supported for teams that commit their own `dart.flutterSdkPath` (e.g. `.fvm/flutter_sdk`).

### Alternative Approaches
- Downgrade warn → info: still noisy in CI.
- Only warn when settings path is missing / wrong: more complex, higher value long-term; not required for this bug.

### Dependencies & Risks
- Low risk: pure messaging change; behavior of skipping writes stays the same.
- Users who set false by accident lose the nudge — acceptable; docs cover correct default.

### Related Code Locations
- [lib/src/workflows/update_vscode_settings.workflow.dart](../../lib/src/workflows/update_vscode_settings.workflow.dart)
- [lib/src/workflows/use_version.workflow.dart](../../lib/src/workflows/use_version.workflow.dart) – calls IDE update flows

## Recommendation
**Action**: validate-p3  
**Reason**: Valid, easy UX bug. Not a functional failure (settings are correctly left alone); noisy warning contradicts documented config. Small, safe fix.

## Notes
- Good first issue / quick win.
- Reporter’s expected config (pin + self-managed `.vscode` + `updateVscodeSettings: false`) is a legitimate dual-IDE monorepo setup.
