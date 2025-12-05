# Issue #982 - Deep Research Analysis

## Issue Details
- **Number**: #982
- **Title**: `fvm run` adds a newline character to the start of the output
- **Created**: November 28, 2025
- **Author**: @blanchardglen
- **Status**: CLOSED
- **Resolved**: PR #988 (Dec 5, 2025)
- **Priority**: P1 - Breaks tooling
- **Platform**: Windows (FVM 4.0.1)
- **Has PR**: #988 (MERGED Dec 5, 2025)

## Problem Summary

Running `fvm dart run` or `fvm flutter` adds an extra newline at the start of stdout output:

```bash
# fvm dart run helloworld.dart
\n                              # ← extra newline
Hello World

# dart run helloworld.dart
Hello World                     # ← correct, no extra newline
```

This breaks tools that parse stdout (protobuf code generation, build scripts, etc.)

## Root Cause Analysis

### The Bug Location

**File**: `lib/src/workflows/run_configured_flutter.workflow.dart`
**Line**: 42

```dart
// Execute using the selected version if available.
if (selectedVersion != null) {
  logger.info();  // ← BUG: This prints an empty newline to stdout!

  return get<FlutterService>().run(cmd, args, selectedVersion);
}
```

### Why It Happens

1. `logger.info()` with no arguments defaults to an empty string (`''`)
2. `logger.info('')` calls `_logger.info(message)` from `mason_logger`
3. `mason_logger.info()` prints the message followed by a newline
4. Result: an empty line is printed before the command output

### Code Trace

```
DartCommand.run()
  → RunConfiguredFlutterWorkflow.call('dart', args)
    → logger.info()  // ← prints \n here
    → FlutterService.run(cmd, args, version)
      → Process output
```

## The Fix

### Option 1: Remove the line (Recommended)
```dart
// Execute using the selected version if available.
if (selectedVersion != null) {
  // logger.info();  ← DELETE THIS LINE
  return get<FlutterService>().run(cmd, args, selectedVersion);
}
```

### Option 2: Change to debug (only shows in verbose mode)
```dart
if (selectedVersion != null) {
  logger.debug();  // Only shows with --verbose flag
  return get<FlutterService>().run(cmd, args, selectedVersion);
}
```

**Recommended: Option 1** - The empty line serves no purpose and corrupts stdout.

## Impact

- **Severity**: High for tooling users
- **Type**: Output corruption
- **Users Affected**: Anyone piping fvm output to other tools
- **Use Cases Broken**:
  - Protobuf code generation (`fvm dart run build_runner`)
  - Build scripts that parse output
  - Any stdout piping: `fvm dart run script.dart | other_tool`

## Testing

### Manual Test
```bash
# Before fix:
fvm dart run helloworld.dart | head -c 1 | xxd
# Shows: 0a (newline character)

# After fix:
fvm dart run helloworld.dart | head -c 1 | xxd
# Shows: 48 (H character)
```

### Unit Test to Add
```dart
test('flutter command does not add leading newline to stdout', () async {
  // Run a simple dart script and verify no leading newline
  final result = await runConfiguredFlutterWorkflow('dart', args: ['--version']);
  // Verify stdout doesn't start with newline
});
```

## Related

- **PR #745** (MERGED) - Different issue: "fvm has one newline too much" - was about cosmetic output
- **Issue #982** - This specific stdout corruption bug

## Action Items

- [x] Remove `logger.info();` on line 42 of `run_configured_flutter.workflow.dart`
- [x] Add test to verify no leading newline
- [x] Release in next patch version

## Timeline

- **Nov 28, 2025**: Issue reported
- **Dec 5, 2025**: PR #988 created and merged, released in v4.0.3

## Commit Message
```
fix: remove leading newline from fvm dart/flutter output

Fixes #982

The logger.info() call before running flutter/dart commands was adding
an unwanted newline to stdout, breaking tools that parse the output.
```
