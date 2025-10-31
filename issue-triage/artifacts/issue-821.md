# Issue #821: Support Dart VSCode getFlutterSdkCommand

## Metadata
- **Reporter**: @danilofuchs
- **Created**: 2025-02-13
- **Reported Version**: FVM 3.x
- **Issue Type**: feature request
- **URL**: https://github.com/leoafarias/fvm/issues/821

## Problem Summary
The VS Code Dart extension added `getFlutterSdkCommand`/`getDartSdkCommand` hooks. FVM currently rewrites `dart.flutterSdkPath` directly, forcing path updates after every Flutter switch. Integrating with the command-based API could eliminate manual edits.

## Version Context
- Current version: v4.0.0
- Behavior unchanged from v3.x.

## Validation Steps
1. Confirmed `UpdateVsCodeSettingsWorkflow` writes `dart.flutterSdkPath` (string) with no support for command settings.
2. Reviewed Dart-Code change (commit b1f79dbd0d66128059cac40ff0dca01d4dd5dca7) describing the new command contract.

## Proposed Implementation Plan
1. Introduce a lightweight CLI command, e.g., `fvm path --json`, returning the current project's Flutter/Dart SDK paths.
2. When updating VS Code settings, optionally configure:
   ```json
   {
     "dart.getFlutterSdkCommand": ["fvm", "path", "--json", "flutter"],
     "dart.getDartSdkCommand": ["fvm", "path", "--json", "dart"]
   }
   ```
   The command should output `{ "sdkPath": "<path>" }` as required by Dart-Code.
3. Provide opt-in via `.fvmrc` (e.g., `useGetFlutterSdkCommand: true`) to avoid breaking existing setups.
4. Update docs explaining VS Code integration and fallback to path-based configuration.
5. Add tests ensuring the workflow writes the new settings when enabled.

## Classification Recommendation
- Priority: **P2 - Medium** (improves IDE integration)
- Suggested Folder: `validated/p2-medium/`

## Notes for Follow-up
- Verify new command works on Windows/macOS/Linux and respects `privilegedAccess` logic.
