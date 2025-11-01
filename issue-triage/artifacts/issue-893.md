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
1. Reviewed `update_vscode_settings.workflow.dart`; it writes `dart.flutterSdkPath` for folders/workspaces.
2. Investigated Dart Code extension behavior—it has `dart.addSdkToTerminalPath` (default: `true`) which automatically injects SDK bin path into terminal PATH.
3. Checked FVM v4 improvements—significant VS Code integration and workflow enhancements.
4. Reviewed Dart Code extension documentation confirming terminal PATH injection should work automatically.
5. Confirmed GitHub issue closed by maintainer on 2025-10-31 with guidance to upgrade to FVM 4.0.0+ and recent Dart Code extension versions.

## Evidence
The Dart Code extension (v3.60.0+) includes automatic terminal PATH injection:
- Setting: `dart.addSdkToTerminalPath` (default: `true`)
- Behavior: "Whether to add your selected Dart/Flutter SDK path to the PATH environment variable for the embedded terminal"
- Implementation: When `dart.flutterSdkPath` is updated, the extension automatically injects the SDK bin path into new terminal sessions

FVM correctly sets `dart.flutterSdkPath`, and the Dart Code extension should handle terminal PATH injection automatically.

## Current Status in v4.0.0
- [ ] Still reproducible
- [x] Already fixed
- [ ] Not applicable to v4.0.0
- [ ] Needs more information

## Root Cause Analysis
The issue reported was with FVM v3.12.9. The terminal PATH injection is handled by the Dart Code extension, not FVM itself. FVM's responsibility is to correctly update `dart.flutterSdkPath`, which it does.

Possible causes for the original issue:
1. Dart Code extension version <v3.60.0 (PATH injection feature added March 2023)
2. Global FVM path appearing before project path in PATH precedence
3. Terminal session not refreshed after SDK switch
4. `dart.addSdkToTerminalPath` setting disabled in user configuration

FVM v4 includes significant VS Code integration improvements that should make this more reliable.

## Proposed Response

This functionality is already handled by the Dart Code extension for VS Code through the `dart.addSdkToTerminalPath` setting (enabled by default since v3.60.0). When FVM updates `dart.flutterSdkPath` in your VS Code settings, the Dart Code extension automatically injects the correct Flutter SDK bin path into the integrated terminal's PATH.

With FVM v4.0.0, the VS Code integration has been significantly improved and this workflow should now work reliably. Please ensure:

1. You're using FVM v4.0.0+
2. Your Dart Code extension is v3.60.0 or later
3. The `dart.addSdkToTerminalPath` setting is enabled (it's enabled by default)
4. You create a new terminal session after running `fvm use`

If issues persist after upgrading to FVM v4, please reopen with:
- FVM version (`fvm --version`)
- Dart Code extension version
- Output of `echo $PATH` in the VS Code terminal
- Value of `dart.addSdkToTerminalPath` in your settings

Closing as this is working as intended with current versions (maintainer comment on 2025-10-31).

## Classification Recommendation
- Priority: **P3 - Low** (resolved by external tooling + v4 improvements)
- Suggested Folder: `closed/`
- Action: Closed on GitHub with upgrade guidance

## Notes
The confusion likely stems from FVM v3.x documentation suggesting terminal integration when it was actually the Dart Code extension's responsibility. The issue should be resolved with FVM v4 + modern Dart Code extension versions.
