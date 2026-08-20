# Issue #759: [Feature Request]: Set as global the Flutter version in .fvmrc file

## Metadata
- **Reporter**: @yannatk
- **Created**: 2024-08-07
- **Issue Type**: needs info
- **URL**: https://github.com/conceptadev/fvm/issues/759

## Problem Summary
VSCode launch fails when global Flutter is old and project uses newer `.fvmrc` version. Need more information (VSCode settings, `fvm doctor --verbose`).

## Validation Steps
1. Confirmed current FVM writes a project-specific `dart.flutterSdkPath` when VS Code settings management is enabled.
2. Confirmed the live issue has no `settings.json`, launch configuration, doctor output, or exact failure.
3. Could not determine whether VS Code is using the global SDK, a stale version-specific path, or a workspace override.

## Evidence
```text
lib/src/workflows/update_vscode_settings.workflow.dart writes dart.flutterSdkPath.
Issue supplies reproduction prose but no configuration or error output.
```

## Troubleshooting/Implementation Plan
Request `settings.json`, `.fvmrc`, and exact error.
Also request workspace settings, `fvm doctor --verbose`, and Dart-Code extension version; compare the SDK used by VS Code with `fvm flutter --version`.

## Recommendation
- Folder: `needs_info/`
