# Fix Plan: Issue #897 - PathAccessException in Home Manager/Nix Environments

## Issue Summary

- **Issue**: [#897](https://github.com/leoafarias/fvm/issues/897)
- **Related**: [#799](https://github.com/leoafarias/fvm/issues/799) (same root cause)
- **Error**: `PathAccessException: Cannot open file, path = '/Users/me/.bash_profile' (OS Error: Permission denied, errno = 13)`
- **Environment**: Nix/Home Manager where shell configs (`.zshrc`, `.bash_profile`) are read-only symlinks

## Root Cause Analysis

The error comes from the `cli_completion` package (version 0.5.0), NOT the install script.

### Call Flow

1. User runs any FVM command (e.g., `fvm doctor`)
2. `FvmCommandRunner.runCommand()` is called
3. `CompletionCommandRunner.runCommand()` (parent class) executes
4. Parent class checks `enableAutoInstall` (defaults to `true`)
5. Calls `tryInstallCompletionFiles()` which tries to read/write shell config files
6. In Home Manager/Nix: shell configs are symlinks to read-only Nix store
7. `PathAccessException` is thrown

### Evidence

```dart
// cli_completion-0.5.0/lib/src/command_runner/completion_command_runner.dart
@override
Future<T?> runCommand(ArgResults topLevelResults) async {
  if (enableAutoInstall &&  // <-- This is true by default
      !_reservedCommands.contains(topLevelResults.command?.name)) {
    tryInstallCompletionFiles(Level.error);  // <-- Throws PathAccessException
  }
  return super.runCommand(topLevelResults);
}
```

## Fix Implementation

### File to Modify

`lib/src/runner.dart`

### Change Required

Add an override for `enableAutoInstall` in the `FvmCommandRunner` class to disable automatic shell completion installation.

### Exact Code Change

**Location**: After line 37 (class declaration), before the `context` field declaration

**Add the following getter override**:

```dart
/// Disable auto-install of shell completions to avoid PathAccessException
/// in managed environments (Nix/Home Manager) where shell configs are read-only.
/// Users can still manually install completions via `fvm completion install`.
@override
bool get enableAutoInstall => false;
```

### Before (current code)

```dart
/// Command Runner for FVM
class FvmCommandRunner extends CompletionCommandRunner<int> {
  final FvmContext context;
  final PubUpdater _pubUpdater;
```

### After (with fix)

```dart
/// Command Runner for FVM
class FvmCommandRunner extends CompletionCommandRunner<int> {
  /// Disable auto-install of shell completions to avoid PathAccessException
  /// in managed environments (Nix/Home Manager) where shell configs are read-only.
  /// Users can still manually install completions via `fvm completion install`.
  @override
  bool get enableAutoInstall => false;

  final FvmContext context;
  final PubUpdater _pubUpdater;
```

## Validation Steps

1. **Compile check**: Run `dart analyze lib/src/runner.dart` - should report no issues
2. **Unit test**: Verify `FvmCommandRunner` has `enableAutoInstall == false`
3. **Integration test**: Simulate read-only shell configs and verify no exception:
   ```bash
   TEMP_HOME=$(mktemp -d)
   touch "$TEMP_HOME/.zshrc" "$TEMP_HOME/.bash_profile"
   chmod 000 "$TEMP_HOME/.zshrc" "$TEMP_HOME/.bash_profile"
   HOME=$TEMP_HOME fvm doctor  # Should NOT throw PathAccessException
   rm -rf "$TEMP_HOME"
   ```

## User Impact

### Positive

- Users in Nix/Home Manager environments can use FVM without errors
- No more `PathAccessException` warnings on every command

### Considerations

- Shell completions will no longer auto-install for ANY user
- Users who want completions must run `fvm completion install` manually
- This is acceptable because:
  - Most users don't use shell completions
  - Manual install is a one-time operation
  - Avoids errors in managed environments

## Alternative Considered (Not Recommended)

Wrap `tryInstallCompletionFiles` in try/catch - rejected because:
- Still attempts file access (wastes cycles)
- Logs warnings that confuse users
- Cleaner to disable auto-install entirely

## Issues to Close After Merge

- [#897](https://github.com/leoafarias/fvm/issues/897) - How to avoid warning of access .bash_profile?
- [#799](https://github.com/leoafarias/fvm/issues/799) - PathAccessException: Cannot open ~/.zshrc

## PR Checklist

- [ ] Add override to `lib/src/runner.dart`
- [ ] Run `dart analyze` - no issues
- [ ] Run `dart test` - all tests pass
- [ ] Test with read-only shell configs
- [ ] Update CHANGELOG.md
- [ ] Reference issues #897 and #799 in PR description
