# AI Slop Issues - Pending Approval

**Repository:** FVM (Flutter Version Manager)
**Audit Date:** 2025-12-22
**Severity Score:** 290 points (CRITICAL - Major cleanup required)

---

## Summary

This document catalogs AI-generated slop code identified in the FVM codebase. Each issue includes location, severity, current problematic code, and proposed fix.

**Approval Required Before Proceeding.**

---

## Issue #1: Try-Catch/Fail Test Theater

**Severity:** CRITICAL (25 pts each)
**Files Affected:** `test/commands_test.dart`
**Instances:** 3

### Problem

Tests wrap assertions in try-catch blocks that call `fail()` on exception. This:
- Masks actual test failures
- Loses stack traces
- Provides misleading error messages

### Current Code

```dart
test('Use Channel', () async {
  try {
    await runner.runOrThrow(['fvm', 'use', channel]);
    final targetBin = Link(targetBinPath).targetSync();
    expect(targetBin == channelBin.path, true);  // Also tautological
    expect(linkExists, true);
  } on Exception catch (e) {
    fail('Exception thrown, $e');
  }
});
```

### Proposed Fix

```dart
test('Use Channel', () async {
  await runner.runOrThrow(['fvm', 'use', channel]);
  final targetBin = Link(targetBinPath).targetSync();
  expect(targetBin, channelBin.path);
  expect(linkExists, isTrue);
});
```

### Rationale

Let the test framework handle exceptions naturally. If `runOrThrow` throws, the test fails with full context.

---

## Issue #2: Tautological Boolean Assertions

**Severity:** MEDIUM (5 pts each)
**Files Affected:** 6 test files
**Instances:** 35

### Problem

Using `expect(expression, true)` instead of proper matchers produces poor failure messages.

### Current Code

| File | Line | Code |
|------|------|------|
| `flutter_version_model_test.dart` | 18 | `expect(master.isChannel, true)` |
| `flutter_version_model_test.dart` | 19 | `expect(beta.isChannel, true)` |
| `flutter_version_model_test.dart` | 20 | `expect(channelWithVersion.isChannel, false)` |
| `flutter_version_model_test.dart` | 44 | `expect(master.isMain, true)` |
| `flutter_version_model_test.dart` | 54-55 | `expect(channelWithVersion.isRelease, true)` |
| `flutter_version_model_test.dart` | 64-65 | `expect(gitCommit.isUnknownRef, true)` |
| `helpers_test.dart` | 30 | `expect(newEnvVar[envName]!.contains(fakePath), true)` |
| `helpers_test.dart` | 31 | `expect(newEnvVar[envName]!.contains('ANOTHER_FAKE_PATH'), true)` |
| `releases_api_test.dart` | 24 | `expect(versionsExists, true)` |
| `alias_command_test.dart` | 63 | `expect(runner.commands.containsKey('i'), true)` |
| `alias_command_test.dart` | 64 | `expect(runner.commands.containsKey('install'), true)` |
| `alias_command_test.dart` | 68-69 | `expect(runner.commands.containsKey('ls'), true)` |
| `enhanced_fork_test.dart` | 117 | `expect(hasTestFork, false)` |
| `fork_command_test.dart` | 137 | `expect(hasTestFork, false)` |

### Proposed Fix

```dart
// Boolean checks
expect(master.isChannel, isTrue);
expect(channelWithVersion.isChannel, isFalse);

// Contains checks
expect(newEnvVar[envName], contains(fakePath));
expect(runner.commands, contains('i'));
```

### Rationale

Proper matchers provide descriptive failure messages:
- Before: `Expected: true, Actual: false`
- After: `Expected: a value that isTrue, Actual: false`

---

## Issue #3: Silent Exception Discarding

**Severity:** HIGH (10 pts each)
**Files Affected:** 4 source files
**Instances:** 10

### Problem

Using `catch (_)` discards exception details, making production debugging impossible.

### Current Code

**File:** `lib/src/workflows/update_project_references.workflow.dart`

```dart
} on Exception catch (_) {
  logger.err('Failed to create local FVM path');
  rethrow;
}
```

**File:** `lib/src/runner.dart:115`

```dart
} catch (_) {
  return () {
    logger.debug("Failed to check for updates.");
  };
}
```

**File:** `lib/src/workflows/setup_flutter.workflow.dart:21`

```dart
} on Exception catch (_) {
  logger.err('Failed to setup Flutter SDK');
  rethrow;
}
```

**File:** `lib/src/utils/git_clone_progress_tracker.dart:47`

```dart
} catch (_) {
  // Ignore parsing errors - git clone continues
}
```

### Proposed Fix

```dart
// update_project_references.workflow.dart (7 instances)
} on Exception catch (e) {
  logger.err('Failed to create local FVM path: $e');
  rethrow;
}

// runner.dart
} catch (e) {
  return () {
    logger.debug("Failed to check for updates: $e");
  };
}

// setup_flutter.workflow.dart
} on Exception catch (e) {
  logger.err('Failed to setup Flutter SDK: $e');
  rethrow;
}

// git_clone_progress_tracker.dart
} catch (e) {
  // Don't interrupt clone for display parsing issues.
  _logger.debug('Progress parsing error: $e');
}
```

### Rationale

Exception details are essential for debugging. Even when rethrowing or ignoring, log the error for diagnostics.

---

## Issue #4: Dead Code - Commented Out

**Severity:** LOW (1 pt each)
**Files Affected:** 2 files
**Instances:** 2

### Current Code

**File:** `lib/src/utils/context.dart:43`
```dart
// Some commented out code line
```

**File:** `test/utils/releases_api_test.dart`
```dart
// test('Some test', () {
//   expect(true, true);  // Also a tautology
// });
```

### Proposed Fix

Delete the commented-out code entirely.

### Rationale

Version control preserves history. Commented code is noise.

---

## Issue #5: Unused Function

**Severity:** MEDIUM (5 pts)
**File:** `test/testing_helpers/prepare_test_environment.dart`
**Instances:** 1

### Current Code

```dart
Future<void> tearDownContext() async {
  // 15 lines of unused cleanup code
  ...
}
```

### Proposed Fix

Delete the `tearDownContext()` function.

### Rationale

Function is never called. Dead code adds maintenance burden.

---

## Issue #6: Stale Parameter Documentation

**Severity:** MEDIUM (5 pts)
**File:** `lib/src/services/project_service.dart:66-73`
**Instances:** 1

### Current Code

```dart
/// Update the project with new configurations
///
/// The [project] parameter is the project to be updated. The optional parameters are:
/// - [flavors]: A map of flavor configurations.
/// - [pinnedVersion]: The new pinned version of the Flutter SDK.
///
/// This method updates the project's configuration with the provided parameters. It creates
/// or updates the project's config file. The updated project is returned.
Project update(
  Project project, {
  Map<String, String>? flavors,
  String? flutterSdkVersion,    // <-- Doc says "pinnedVersion"
  bool? updateVscodeSettings,   // <-- Not documented at all
}) {
```

### Proposed Fix

```dart
/// Updates the project configuration and saves it to disk.
Project update(
  Project project, {
  Map<String, String>? flavors,
  String? flutterSdkVersion,
  bool? updateVscodeSettings,
}) {
```

### Rationale

Stale documentation is worse than no documentation - it misleads developers.

---

## Issue #7: Redundant Constructor Comments

**Severity:** LOW (1 pt each)
**Files Affected:** `lib/src/models/config_model.dart` and others
**Instances:** 10+

### Current Code

```dart
class SomeModel {
  /// Constructor
  SomeModel(this.field);
}
```

### Proposed Fix

```dart
class SomeModel {
  SomeModel(this.field);
}
```

### Rationale

Per Effective Dart: "It's better to say nothing than waste a reader's time."

---

## Issues NOT Recommended for Change

These `catch (_)` patterns are **intentional** and should remain:

| File | Line | Reason |
|------|------|--------|
| `test/version_format_workflow_test.dart` | 340 | Cleanup after test failure - errors should be ignored |
| `tool/release_tool/tool/grind.dart` | 174 | Detection pattern - only checks if exception is thrown |
| `lib/src/commands/doctor_command.dart` | 153 | Provides user-friendly message, exception type sufficient |

---

## Approval Checklist

- [ ] **Issue #1:** Remove try-catch/fail() from 3 tests
- [ ] **Issue #2:** Replace 35 tautological assertions with proper matchers
- [ ] **Issue #3:** Add exception details to 10 error log messages
- [ ] **Issue #4:** Remove 2 blocks of commented-out code
- [ ] **Issue #5:** Delete unused `tearDownContext()` function
- [ ] **Issue #6:** Fix stale parameter documentation
- [ ] **Issue #7:** Remove redundant `/// Constructor` comments

---

## Risk Assessment

| Change | Risk | Mitigation |
|--------|------|------------|
| Test refactoring | Low | Tests will fail more clearly, not less |
| Error message changes | None | Adding info, not removing |
| Dead code removal | None | Code is unused |
| Doc changes | None | Cosmetic |

---

## Estimated Impact

- **Lines changed:** ~150
- **Files modified:** 18
- **Test behavior:** Unchanged (same assertions, better messages)
- **Runtime behavior:** Unchanged (only logging details added)

---

**Awaiting Approval**

Signature: ____________________
Date: ____________________
