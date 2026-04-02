# PR #981 - Deep Analysis: Fork Version Cache Fix

## PR Details
- **Number**: #981
- **Title**: fix: read or write cache with fork version
- **Author**: @huanghui1998hhh
- **Created**: November 26, 2025
- **Status**: MERGED (Dec 5, 2025)
- **CI Status**: All tests passed

---

## Problem Statement

### The Bug
When using `fvm use fork/x.x.x` to set a fork version, running `fvm flutter` or `fvm dart` commands was **incorrectly using the official Flutter version** instead of the fork repository.

### Example Scenario
```bash
# User configures a fork
fvm use my-company-fork/3.10.0

# Expected: Use Flutter from my-company-fork
# Actual: Uses official Flutter 3.10.0 (WRONG!)
fvm flutter --version
```

### Root Cause
The fork prefix was being **stripped** during configuration read/write operations. When FVM stored and retrieved version information, it only saved the version number (`3.10.0`) and lost the fork identifier (`my-company-fork`).

---

## Technical Analysis

### Core Issue: `name` vs `nameWithAlias`

FVM has two ways to identify a version:
- **`name`**: Just the version number (e.g., `3.10.0`)
- **`nameWithAlias`**: Full qualified name including fork prefix (e.g., `my-fork/3.10.0`)

Before this PR, the codebase inconsistently used `name` everywhere, which worked for official Flutter versions but broke fork support.

### Key Addition: `nameWithAlias` Getter

**File**: `lib/src/models/flutter_version_model.dart`

```dart
/// Returns the qualified name including fork prefix if present.
///
/// For example: `fork/3.35.4` or `3.35.4` if no fork.
String get nameWithAlias => fromFork ? '$fork/$name' : name;
```

This getter:
- Returns `my-fork/3.10.0` for fork versions
- Returns `3.10.0` for official versions (backward compatible)

---

## Files Changed (11 files)

### 1. Model Layer

| File | Change | Purpose |
|------|--------|---------|
| `flutter_version_model.dart` | Added `nameWithAlias` getter | Core fix - provides qualified name |
| `cache_flutter_version_model.dart` | Updated `toFlutterVersion()` to pass `fork` | Preserves fork info during conversion |
| `project_model.dart` | Updated `activeFlavor` and `localVersionSymlinkPath` | Fork-aware flavor matching and paths |

### 2. Service Layer

| File | Change | Purpose |
|------|--------|---------|
| `project_service.dart` | `findVersion()` returns `nameWithAlias` | Returns full fork identifier |

### 3. Command Layer

| File | Change | Purpose |
|------|--------|---------|
| `list_command.dart` | Display uses `nameWithAlias` | Shows fork prefix in `fvm list` |
| `use_command.dart` | Uses `nameWithAlias` for version lookup | Correctly resolves fork versions |
| `doctor_command.dart` | Error messages use `nameWithAlias` | Accurate fork version in diagnostics |

### 4. Workflow Layer

| File | Change | Purpose |
|------|--------|---------|
| `update_project_references.workflow.dart` | Creates fork subdirectory, uses `nameWithAlias` | Correct local cache structure |

### 5. Tests

| File | Change | Purpose |
|------|--------|---------|
| `enhanced_fork_test.dart` | Updated assertions | Tests fork version handling |
| `update_project_references.workflow_test.dart` | Added 2 fork-specific tests | Validates fork cache structure |
| `update_vscode_settings.workflow_test.dart` | Added 2 fork-specific tests | Validates VS Code integration |

---

## Directory Structure Changes

### Before (Broken)
```
.fvm/
├── versions/
│   └── 3.10.0 → ~/.fvm/versions/3.10.0  # WRONG: Points to official
└── flutter_sdk → versions/3.10.0
```

### After (Fixed)
```
.fvm/
├── versions/
│   └── my-fork/
│       └── 3.10.0 → ~/.fvm/versions/my-fork/3.10.0  # CORRECT: Points to fork
└── flutter_sdk → versions/my-fork/3.10.0
```

---

## Affected Scenarios

### 1. `fvm use fork/version`
**Before**: Saved `3.10.0` to config, lost fork info
**After**: Saves `my-fork/3.10.0`, preserves fork info

### 2. `fvm flutter` / `fvm dart`
**Before**: Looked up `3.10.0`, found official version
**After**: Looks up `my-fork/3.10.0`, finds correct fork

### 3. `fvm list`
**Before**: Showed `3.10.0` without fork indicator
**After**: Shows `my-fork/3.10.0` with full identifier

### 4. `fvm doctor`
**Before**: Error messages referenced wrong version
**After**: Error messages show correct fork version

### 5. VS Code Integration
**Before**: `dart.flutterSdkPath` pointed to wrong location
**After**: Points to `.fvm/versions/my-fork/3.10.0`

### 6. Flavors with Forks
**Before**: Flavor `staging: 3.10.0` couldn't find fork
**After**: Flavor `staging: my-fork/3.10.0` works correctly

---

## Review History

### Initial Review (Dec 2, 2025) - Changes Requested
**Issue Found**: Regression in `list_command.dart:41`

```dart
// Problem: After this PR, findVersion() returns "my-fork/3.10.0"
// But list_command was still using version.name ("3.10.0")
// This caused the green checkmark to never appear for fork versions

final localVersion = get<ProjectService>().findVersion();  // "my-fork/3.10.0"
var printVersion = version.name;                            // "3.10.0"
localVersion == printVersion;                               // FALSE!
```

### Fix Applied (Dec 3, 2025)
Contributor updated `list_command.dart:41`:
```dart
var printVersion = version.nameWithAlias;  // Now returns "my-fork/3.10.0"
```

Also applied optional improvement in `cache_flutter_version_model.dart`:
```dart
FlutterVersion(name, releaseChannel: releaseChannel, type: type, fork: fork);
```

---

## Multi-Agent Validation Guide

### Agent 1: Code Review Agent
**Focus**: Verify all `name` → `nameWithAlias` changes are correct

```yaml
task: "Review all changes from name to nameWithAlias"
files_to_check:
  - lib/src/commands/list_command.dart:41
  - lib/src/commands/use_command.dart:73
  - lib/src/commands/doctor_command.dart:144,156
  - lib/src/services/project_service.dart:52
  - lib/src/models/project_model.dart:74
  - lib/src/workflows/update_project_references.workflow.dart:147,152,153
validation_criteria:
  - Each change preserves fork prefix when present
  - Each change is backward compatible (returns same value for non-fork versions)
  - No places where name should have been changed but wasn't
```

### Agent 2: Test Coverage Agent
**Focus**: Verify test coverage for fork scenarios

```yaml
task: "Analyze test coverage for fork functionality"
test_files:
  - test/commands/enhanced_fork_test.dart
  - test/src/workflows/update_project_references.workflow_test.dart
  - test/src/workflows/update_vscode_settings.workflow_test.dart
validation_criteria:
  - Tests cover fork version parsing
  - Tests cover fork directory structure creation
  - Tests cover fork version display in list
  - Tests cover flavor with fork version
  - Tests cover VS Code settings with fork path
```

### Agent 3: Edge Case Agent
**Focus**: Identify potential edge cases not covered

```yaml
task: "Identify edge cases in fork handling"
scenarios_to_verify:
  - What if fork name contains special characters?
  - What if fork name is empty string?
  - What if fork/version format is malformed?
  - What about channel versions with forks? (e.g., my-fork/stable)
  - What about commit hashes with forks? (e.g., my-fork/abc123)
  - What about nested fork names? (e.g., org/team/version)
```

### Agent 4: Regression Agent
**Focus**: Check for potential regressions

```yaml
task: "Check for regressions in non-fork scenarios"
files_to_verify:
  - lib/src/models/flutter_version_model.dart (toString change)
  - All places using version.toString()
validation_criteria:
  - Official versions still work exactly as before
  - No unexpected fork prefix appears for non-fork versions
  - Existing tests still pass
```

### Agent 5: Integration Agent
**Focus**: End-to-end fork workflow validation

```yaml
task: "Validate complete fork workflow"
workflow_steps:
  1. Configure a fork: fvm fork add my-fork https://github.com/user/flutter.git
  2. Install fork version: fvm install my-fork/3.10.0
  3. Use fork version: fvm use my-fork/3.10.0
  4. Verify config: cat .fvmrc (should show my-fork/3.10.0)
  5. Run command: fvm flutter --version
  6. List versions: fvm list (should show checkmark for my-fork/3.10.0)
  7. Run doctor: fvm doctor (should show my-fork/3.10.0)
validation_criteria:
  - Each step completes without error
  - Fork version is preserved throughout workflow
  - VS Code settings point to correct fork path
```

---

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Regression for official versions | Low | High | `nameWithAlias` returns `name` when no fork |
| Breaking existing fork configs | Low | Medium | Fork parsing unchanged, only storage fixed |
| Test coverage gaps | Medium | Low | Added 4 new fork-specific tests |
| Edge cases with special chars | Medium | Low | Not addressed but existing behavior maintained |

---

## Recommendation

**MERGED** ✅

Reasons for approval:
1. All CI tests passing (including Windows, macOS, Ubuntu)
2. Requested changes have been applied correctly
3. Optional improvement also applied
4. Comprehensive test coverage added
5. Backward compatible with non-fork versions
6. Fixes critical bug for fork users

---

## Post-Merge Actions

1. [ ] Close any related issues (if any exist)
2. [ ] Consider adding to CHANGELOG for next release
3. [ ] Monitor for any user reports of fork issues
4. [ ] Consider adding edge case tests in future PR

---

## Timeline

- **Nov 26, 2025**: PR opened by @huanghui1998hhh
- **Dec 2, 2025**: Review by @leoafarias - requested changes
- **Dec 2, 2025**: Windows test fix applied
- **Dec 3, 2025**: Requested changes applied
- **Dec 5, 2025**: Deep analysis completed
- **Dec 5, 2025**: PR merged by @leoafarias
