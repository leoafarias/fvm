# DRY Review Report for FVM Codebase

**Date:** 2025-12-22
**Reviewer:** DRY Reviewer Agent
**Branch:** `claude/dry-code-reviewer-GOE4r`

---

## 1) Summary

- **Duplicated knowledge found**: Yes, 4 distinct clusters of duplicated knowledge identified
- **Highest-risk duplication**: Environment variable PATH update logic is duplicated between `helpers.dart` and `flutter_service.dart`—same algorithm in two locations that must change together if PATH handling evolves
- **Second-highest risk**: Interactive version selection pattern repeated across 3+ commands with identical logic for cache lookup and user prompts
- **Overall assessment**: The codebase demonstrates good use of abstraction (workflows, services, base classes), but has some evolutionary duplication that warrants attention
- **Recommended action level**: **Suggest** (Medium priority refactoring opportunities, no blocking issues)

---

## 2) Findings

### Finding 1: Environment Variable PATH Update Logic

| Attribute | Value |
|-----------|-------|
| **Title** | Duplicate PATH environment update algorithm |
| **Severity** | Medium |
| **Category** | DRY Violation |

**Evidence:**

**Location 1:** `lib/src/utils/helpers.dart:359-373`
```dart
Map<String, String> updateEnvironmentVariables(
  List<String> paths,
  Map<String, String> env,
) {
  paths = paths.toSet().toList();
  final updatedEnvironment = Map<String, String>.of(env);
  final envPath = env['PATH'] ?? '';
  final separator = Platform.isWindows ? ';' : ':';
  updatedEnvironment['PATH'] = paths.join(separator) + separator + envPath;
  return updatedEnvironment;
}
```

**Location 2:** `lib/src/services/flutter_service.dart:348-368` (in `VersionRunner` class)
```dart
Map<String, String> _updateEnvironmentVariables(List<String> paths) {
  paths = paths.toSet().toList();
  final env = _context.environment;
  final logger = _context.get<Logger>();
  logger.debug('Starting to update environment variables...');
  final updatedEnvironment = Map<String, String>.of(env);
  final envPath = env['PATH'] ?? '';
  final separator = Platform.isWindows ? ';' : ':';
  updatedEnvironment['PATH'] = paths.join(separator) + separator + envPath;
  return updatedEnvironment;
}
```

**Shared Knowledge:** Algorithm for prepending paths to system PATH with cross-platform separator handling.

**Why it matters:**
- If PATH handling logic needs to change (e.g., handling duplicate entries, different ordering, escaping), both locations must be updated
- The platform-specific separator (`Platform.isWindows ? ';' : ':'`) is knowledge that should exist in one place
- Risk of divergence if one is updated and the other forgotten

**Recommendation:**

*Best refactor option:* Consolidate into the existing `updateEnvironmentVariables` helper in `helpers.dart` and have `VersionRunner._updateEnvironmentVariables` call it:

```dart
// In VersionRunner
Map<String, String> _updateEnvironmentVariables(List<String> paths) {
  logger.debug('Starting to update environment variables...');
  return updateEnvironmentVariables(paths, _context.environment);
}
```

*Wrong abstraction risk:* Low. The helper already exists and has the correct signature. This is a simple delegation.

---

### Finding 2: Interactive Version Selection Pattern

| Attribute | Value |
|-----------|-------|
| **Title** | Repeated cache version selection logic in commands |
| **Severity** | Medium |
| **Category** | DRY Violation |

**Evidence:**

**Location 1:** `lib/src/commands/global_command.dart:69-75`
```dart
if (argResults!.rest.isEmpty) {
  final versions = await cacheService.getAllVersions();
  version = logger.cacheVersionSelector(versions);
} else {
  version = argResults!.rest[0];
}
```

**Location 2:** `lib/src/commands/remove_command.dart:54-59`
```dart
if (argResults!.rest.isEmpty) {
  final versions = await get<CacheService>().getAllVersions();
  version = logger.cacheVersionSelector(versions);
} else {
  version = argResults!.rest[0];
}
```

**Location 3:** `lib/src/commands/use_command.dart:72-80` (similar pattern with additional logic)

**Shared Knowledge:** The UI/UX decision that when no version argument is provided, show an interactive selector with cached versions.

**Why it matters:**
- If the fallback behavior changes (e.g., different prompt message, filtering criteria, default selection), all locations must be updated
- Inconsistent user experience if one command diverges

**Recommendation:**

*Best refactor option:* Add a helper method to `BaseFvmCommand` or a command mixin:

```dart
// In base_command.dart or a new mixin
Future<String?> getVersionFromArgsOrSelector({
  String? existingVersion,
  bool required = true,
}) async {
  if (existingVersion != null) return existingVersion;
  if (firstRestArg != null) return firstRestArg;

  final versions = await get<CacheService>().getAllVersions();
  return logger.cacheVersionSelector(versions);
}
```

*Alternative:* Keep duplication temporarily if commands may diverge (e.g., `use` command has flavor-specific logic). Document the intentional duplication.

*Wrong abstraction risk:* Medium. The `use_command` has additional complexity (project pinned version, flavors). A helper that tries to handle all cases may become a "god method." Consider if the simple 3-command case warrants extraction while `use` remains specialized.

---

### Finding 3: Git Repository Validation Boilerplate

| Attribute | Value |
|-----------|-------|
| **Title** | Repeated git directory setup in GitService methods |
| **Severity** | Low |
| **Category** | Acceptable Repetition |

**Evidence:**

**Location 1:** `lib/src/services/git_service.dart:189-204` (`getBranch`)
```dart
final flutterVersion = FlutterVersion.parse(version);
final versionDir = get<CacheService>().getVersionCacheDir(flutterVersion);
final isGitDir = await GitDir.isGitDir(versionDir.path);
if (!isGitDir) throw Exception('Not a git directory');
final gitDir = await GitDir.fromExisting(versionDir.path);
```

**Location 2:** `lib/src/services/git_service.dart:207-217` (`getTag`)
```dart
final flutterVersion = FlutterVersion.parse(version);
final versionDir = get<CacheService>().getVersionCacheDir(flutterVersion);
final isGitDir = await GitDir.isGitDir(versionDir.path);
if (!isGitDir) throw Exception('Not a git directory');
final gitDir = await GitDir.fromExisting(versionDir.path);
```

**Shared Knowledge:** Version-to-git-directory resolution and validation.

**Why it matters:**
- Minor maintenance burden, but the pattern is simple and localized
- Error message is the same, validation logic identical

**Recommendation:**

*Best refactor option:* Extract a private helper:

```dart
Future<GitDir> _getGitDirForVersion(String version) async {
  final flutterVersion = FlutterVersion.parse(version);
  final versionDir = get<CacheService>().getVersionCacheDir(flutterVersion);
  final isGitDir = await GitDir.isGitDir(versionDir.path);
  if (!isGitDir) throw Exception('Not a git directory');
  return GitDir.fromExisting(versionDir.path);
}
```

*Wrong abstraction risk:* Low. This is a private helper within the same class with clear purpose.

---

### Finding 4: Rest Arguments Removal Pattern

| Attribute | Value |
|-----------|-------|
| **Title** | Repeated pattern for extracting command arguments |
| **Severity** | Low |
| **Category** | Acceptable Repetition |

**Evidence:**

| File | Line | Code |
|------|------|------|
| `spawn_command.dart` | 33 | `final flutterArgs = [...?argResults?.rest]..removeAt(0);` |
| `exec_command.dart` | 29 | `final execArgs = [...?argResults?.rest]..removeAt(0);` |
| `flavor_command.dart` | 48 | `final flutterArgs = [...?argResults?.rest]..removeAt(0);` |

**Shared Knowledge:** Pattern to skip the first argument (version/flavor/command) and pass remaining args.

**Why it matters:**
- This is a 1-liner with minimal cognitive load
- The semantics differ slightly between contexts (version vs flavor vs command name)

**Recommendation:**

*Keep as-is.* This is **acceptable repetition**. The pattern is:
1. Simple (single line)
2. Self-documenting
3. Semantically different in each context

Extracting a helper like `getArgsAfterFirst()` would add indirection without meaningful benefit. The "knowledge" here is Dart's list manipulation syntax, not domain knowledge.

---

## 3) Proposed Patch Sketches

### Patch A: Consolidate Environment Variable Logic

```dart
// lib/src/services/flutter_service.dart
// Before (in VersionRunner class):
Map<String, String> _updateEnvironmentVariables(List<String> paths) {
  paths = paths.toSet().toList();
  final env = _context.environment;
  final logger = _context.get<Logger>();
  logger.debug('Starting to update environment variables...');
  final updatedEnvironment = Map<String, String>.of(env);
  final envPath = env['PATH'] ?? '';
  final separator = Platform.isWindows ? ';' : ':';
  updatedEnvironment['PATH'] = paths.join(separator) + separator + envPath;
  return updatedEnvironment;
}

// After:
import '../utils/helpers.dart' show updateEnvironmentVariables;

Map<String, String> _updateEnvironmentVariables(List<String> paths) {
  final logger = _context.get<Logger>();
  logger.debug('Starting to update environment variables...');
  return updateEnvironmentVariables(paths, _context.environment);
}
```

### Patch B: Git Directory Helper (Optional)

```dart
// lib/src/services/git_service.dart
// Add private helper:
Future<GitDir> _getGitDirForVersion(String version) async {
  final flutterVersion = FlutterVersion.parse(version);
  final versionDir = get<CacheService>().getVersionCacheDir(flutterVersion);

  if (!await GitDir.isGitDir(versionDir.path)) {
    throw Exception('Not a git directory: ${versionDir.path}');
  }

  return GitDir.fromExisting(versionDir.path);
}

// Update getBranch:
Future<String?> getBranch(String version) async {
  final gitDir = await _getGitDirForVersion(version);
  final result = await gitDir.currentBranch();
  return result.branchName;
}

// Update getTag:
Future<String?> getTag(String version) async {
  final gitDir = await _getGitDirForVersion(version);
  try {
    final pr = await gitDir.runCommand(['describe', '--tags', '--exact-match']);
    return (pr.stdout as String).trim();
  } on ProcessException catch (e) {
    // ... existing error handling ...
  }
}
```

---

## 4) Verification Checklist

### Tests to Add/Update

- [ ] **Unit test for `updateEnvironmentVariables` in helpers.dart** - ensure it handles edge cases (empty paths, empty env, Windows vs Unix separators)
- [ ] **Verify `VersionRunner` tests still pass** after delegating to helper
- [ ] **Add test for `_getGitDirForVersion`** if extracted - test both valid git dir and non-git dir scenarios

### Smoke Checks

```bash
# Run existing tests
dart test

# Manual verification after refactor
fvm install stable
fvm use stable
fvm flutter --version
fvm spawn stable flutter --version
fvm global stable
```

### Rollout/Compatibility Concerns

- **None identified.** All proposed changes are internal refactors with no API changes
- The `updateEnvironmentVariables` function in `helpers.dart` is already public, so delegating to it is safe
- No breaking changes to CLI behavior

---

## Summary of Recommendations by Priority

| Priority | Finding | Action |
|----------|---------|--------|
| **Strongly Recommend** | Environment variable PATH logic | Consolidate to single helper |
| **Suggest** | Version selection pattern | Consider helper in base class |
| **Optional** | Git directory validation | Extract private helper |
| **No Action** | Rest args removal | Acceptable repetition |

---

## Appendix: Codebase Strengths (Non-DRY Observations)

The FVM codebase demonstrates several good practices that *prevent* DRY violations:

1. **Workflow Pattern**: Complex multi-step operations are encapsulated in workflow classes (`UseVersionWorkflow`, `EnsureCacheWorkflow`, etc.), preventing duplication of orchestration logic across commands.

2. **Service Layer**: Core business logic (cache management, git operations, flutter SDK operations) is centralized in service classes.

3. **Base Command Class**: `BaseFvmCommand` provides shared functionality (argument parsing helpers, logger access, service access) to all commands.

4. **Model Hierarchy**: `CacheFlutterVersion` extends `FlutterVersion`, properly inheriting shared properties rather than duplicating them.

5. **Centralized Constants**: Platform-specific values (file names, paths, URLs) are defined in `constants.dart`.

These patterns contribute to a maintainable codebase with minimal knowledge duplication.
