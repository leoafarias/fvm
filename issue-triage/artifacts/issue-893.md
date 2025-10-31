# Issue #893: [BUG] Visual Studio Code terminal is not using the configured Flutter version

## Metadata
- **Reporter**: @lukaszciastko
- **Created**: 2025-07-16
- **Reported Version**: FVM 3.12.9 (macOS)
- **Issue Type**: bug (IDE integration)
- **URL**: https://github.com/leoafarias/fvm/issues/893

## Problem Summary
After running `fvm use stable`, VS Code updates `dart.flutterSdkPath` to `.fvm/versions/stable`, but the integrated terminal continues to run the globally installed Flutter. Restarting VS Code or the terminal doesn’t switch the CLI.

## Version Context
- Reported against: v3.x
- Current version: v4.0.0
- Version-specific: no — workflow still only touches VS Code settings.json

## Validation Steps
1. Reviewed `update_vscode_settings.workflow.dart`; it writes `dart.flutterSdkPath` for folders/workspaces but does nothing for VS Code terminal environment variables.
2. Confirmed docs lack instructions for updating the integrated terminal PATH.
3. Reproduced locally by running `fvm use stable` in a test project: `.vscode/settings.json` contains `.fvm/versions/stable`, but `flutter --version` in VS Code terminal still resolves to the global installation.

## Evidence
```
lib/src/workflows/update_vscode_settings.workflow.dart:178-190
  currentSettings["dart.flutterSdkPath"] = _resolveSdkPath(project);
  vscodeSettingsFile.writeAsStringSync(...)
# No handling for terminal.integrated.env.*
```

## Current Status in v4.0.0
- [x] Still reproducible
- [ ] Already fixed
- [ ] Not applicable to v4.0.0
- [ ] Needs more information

## Troubleshooting/Implementation Plan

### Root Cause Analysis
We only configure VS Code’s Dart extension; the integrated terminal inherits the user’s PATH, which still points to the globally installed Flutter. Without PATH adjustments (or a shim), `flutter` resolves to the wrong binary.

### Proposed Solution
1. Extend `update_vscode_settings.workflow.dart` to optionally manage `terminal.integrated.env.{os}`. When `updateVscodeSettings` is true:
   - Prepend `${workspaceFolder}/.fvm/flutter_sdk/bin` (or absolute path when `privilegedAccess` is false) to `PATH` in `terminal.integrated.env.*`.
   - Preserve existing values by merging with user-defined env maps and avoiding duplication.
2. Provide project/global config flag (e.g., `updateVscodeTerminal`) to opt out if users prefer manual control.
3. Handle macOS, Linux, and Windows separately (`terminal.integrated.env.osx/linux/windows`). Ensure Windows paths are POSIX-to-Windows converted.
4. After updating configs, prompt users to “Reload Terminal” (document in CLI output).
5. Add regression tests (unit test on workflow using temp JSON fixtures) to verify PATH merging and opt-out.
6. Update docs (VS Code section) explaining how the terminal PATH is managed and how to disable/override it.

### Alternative Approaches
- Instead of editing PATH, create a VS Code task/alias to run `fvm flutter` and document usage. Less automatic but lower risk.

### Dependencies & Risks
- Overwriting existing user PATH customizations could be disruptive; must merge carefully and warn when conflicts arise.
- Windows PATH length limits—ensure we append rather than overwrite and use semicolon separators.

## Classification Recommendation
- Priority: **P1 - High** (core IDE workflow broken without manual steps)
- Suggested Folder: `validated/p1-high/`

## Notes for Follow-up
- Reach out to the reporter with instructions to temporarily run `fvm flutter` or add `.fvm/flutter_sdk/bin` manually until automation lands.
