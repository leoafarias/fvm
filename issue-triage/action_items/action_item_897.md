# Action Item: Issue #897 – Handle Read-Only Shell Profiles (Nix/Home Manager)

> **UPDATE 2025-12-09**: Previous analysis was incorrect. The error comes from the **Dart CLI** (`cli_completion` package), NOT the install script. See `issue-triage/artifacts/issue-897-fix-plan.md` for the correct fix.

## Objective
Stop the `cli_completion` package from auto-installing shell completions (which accesses read-only shell configs in Nix/Home Manager environments).

## Corrected Root Cause Analysis

The `PathAccessException` is thrown by the `cli_completion` Dart package, not `scripts/install.sh`.

### Call Flow
1. User runs any FVM command (e.g., `fvm doctor`)
2. `FvmCommandRunner` extends `CompletionCommandRunner` from `cli_completion`
3. `CompletionCommandRunner.runCommand()` checks `enableAutoInstall` (defaults to `true`)
4. Calls `tryInstallCompletionFiles()` which reads/writes shell config files
5. In Nix/Home Manager: shell configs are symlinks to read-only Nix store → `PathAccessException`

### Evidence
Reproduced locally:
```bash
chmod 000 ~/.zshrc ~/.bash_profile
fvm doctor  # Throws PathAccessException
```

## Correct Fix

**File**: `lib/src/runner.dart`

**Change**: Add override to disable auto-install of shell completions:

```dart
class FvmCommandRunner extends CompletionCommandRunner<int> {
  /// Disable auto-install of shell completions to avoid PathAccessException
  /// in managed environments (Nix/Home Manager) where shell configs are read-only.
  /// Users can still manually install completions via `fvm completion install`.
  @override
  bool get enableAutoInstall => false;

  // ... rest of class unchanged
}
```

## Full Implementation Plan

See: `issue-triage/artifacts/issue-897-fix-plan.md`

## Issues to Close After Merge
- #897 - How to avoid warning of access .bash_profile?
- #799 - PathAccessException: Cannot open ~/.zshrc

## Note on PR #967
PR #967 (install script v2) does **NOT** fix this issue. It only removes shell config writes from the bash install script, but the Dart CLI still uses `cli_completion` which causes the error.
