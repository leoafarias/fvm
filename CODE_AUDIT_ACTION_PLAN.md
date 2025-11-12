# FVM Code Audit - Action Plan

## Overview
This document outlines concrete, actionable items from the multi-agent code audit. Items are prioritized by real impact, not theoretical issues.

---

## 🔴 CRITICAL - Fix Immediately

### 1. Null Pointer Crash in File Lock
**File:** `lib/src/utils/file_lock.dart:59-61`
**Problem:** Using `!` on potentially null `lastModified` will crash at runtime
**Fix:**
```dart
// Current (broken):
bool isLockedWithin(Duration threshold) =>
    _lockExists &&
    (lastModified!.isAfter(DateTime.now().subtract(threshold)));

// Fixed:
bool isLockedWithin(Duration threshold) {
  if (!_lockExists) return false;
  final modified = lastModified;
  return modified != null &&
         modified.isAfter(DateTime.now().subtract(threshold));
}
```
**Effort:** 5 minutes
**Risk if not fixed:** App crashes when checking lock age

---

## 🟠 HIGH PRIORITY - Address Soon

### 2. Memory Leak in Git Service
**File:** `lib/src/services/git_service.dart:50-58`
**Problem:** Stream subscriptions never canceled, leak memory in long-running processes
**Fix:**
```dart
// Current (leaks):
// ignore: avoid-unassigned-stream-subscriptions
process.stderr.transform(utf8.decoder).listen((line) {
  progressTracker.processLine(line);
  processLogs.add(line);
});

// Fixed:
final stderrSubscription = process.stderr
    .transform(utf8.decoder)
    .listen((line) {
      progressTracker.processLine(line);
      processLogs.add(line);
    });

final stdoutSubscription = process.stdout
    .transform(utf8.decoder)
    .listen((line) => logger.info(line));

final exitCode = await process.exitCode;

await stderrSubscription.cancel();
await stdoutSubscription.cancel();
```
**Effort:** 15 minutes
**Risk if not fixed:** Memory grows unbounded over time

### 3. Remove Unused `scope` Dependency
**File:** `pubspec.yaml:24`
**Problem:** `scope: ^5.1.0` is declared but never imported anywhere
**Fix:** Delete line 24 from pubspec.yaml, run `dart pub get`
**Effort:** 2 minutes
**Risk if not fixed:** Larger bundle size, potential security surface

### 4. Race Condition with Symlink Target
**File:** `lib/src/services/cache_service.dart:198, 210, 218`
**Problem:** Calling `targetSync()` multiple times - target could change between calls
**Fix:**
```dart
// In each method that uses targetSync() multiple times:
final target = _globalCacheLink.targetSync();
// Use 'target' variable instead of calling targetSync() repeatedly
```
**Effort:** 10 minutes
**Risk if not fixed:** Inconsistent behavior in concurrent scenarios

---

## 🟡 MEDIUM PRIORITY - Plan for Next Refactor

### 5. Infinite Loop Potential in Lock Acquisition
**File:** `lib/src/utils/file_lock.dart:64-74`
**Problem:** `getLock()` has unbounded while loop, no timeout
**Fix:** Add max wait duration parameter
```dart
Future<void Function()> getLock({
  Duration? pollingInterval,
  Duration maxWait = const Duration(minutes: 5),
}) async {
  final deadline = DateTime.now().add(maxWait);

  while (isLocked) {
    if (DateTime.now().isAfter(deadline)) {
      throw TimeoutException('Failed to acquire lock within $maxWait');
    }
    await Future.delayed(
      pollingInterval ?? const Duration(milliseconds: 100),
    );
  }

  lock();
  return () => unlock();
}
```
**Effort:** 10 minutes
**Risk if not fixed:** App hangs if lock never released

### 6. Fix Incorrect Documentation
**Files:** Multiple
**Problem:** Comments that are actually wrong (not just verbose)

**6a. GlobalCommand description is backwards**
`lib/src/commands/global_command.dart:14`
```dart
// Current: /// Removes Flutter SDK
// Fixed:   /// Sets Flutter SDK version as global default
```

**6b. ExecCommand comment is misleading**
`lib/src/commands/exec_command.dart:28`
```dart
// Current: // Removes version from first arg
// Fixed:   // Removes command name from first arg
```

**Effort:** 5 minutes total
**Impact:** Developers won't be confused by wrong docs

### 7. Broken Symlink Handling
**File:** `lib/src/utils/extensions.dart:62-64`
**Problem:** `targetSync()` throws on broken symlinks, no error handling
**Fix:**
```dart
final sourceExists = existsSync();
if (sourceExists) {
  try {
    if (targetSync() == target.path) {
      return; // Already points to correct target
    }
  } on FileSystemException {
    // Broken symlink, will recreate below
  }
}
```
**Effort:** 5 minutes
**Risk if not fixed:** Crashes when encountering broken symlinks

### 8. Generic Exception Instead of AppException
**Files:** `lib/src/services/git_service.dart:64, 196` and others
**Problem:** Using `throw Exception('message')` breaks error handling patterns
**Fix:** Replace with `throw AppException('message')`
**Examples:**
- Line 64: `throw Exception('Git clone failed')` → `throw AppException('Git clone failed')`
- Line 196: `throw Exception('Not a git directory')` → `throw AppException('Not a git directory')`

**Effort:** 10 minutes
**Impact:** Consistent error handling throughout app

### 9. Inconsistent Error Re-throwing
**Files:** Multiple locations (20 uses of `rethrow`, 11 uses of `Error.throwWithStackTrace`)
**Problem:** Mixed patterns make stack traces inconsistent
**Decision needed:** Pick one pattern and standardize

**Recommendation:** Use `Error.throwWithStackTrace()` when you have the stack trace, `rethrow` when you don't modify the exception

**Effort:** 30 minutes to standardize
**Impact:** Better error diagnostics

---

## 🟢 LOW PRIORITY - Quality Improvements

### 10. Code Duplication - Version Selection
**Files:** `lib/src/commands/use_command.dart:72-80`, `remove_command.dart:54-58`, `global_command.dart:69-75`
**Problem:** Same logic copied 3 times

**Create utility in base_command.dart:**
```dart
Future<String> getVersionArgument() async {
  if (argResults!.rest.isEmpty) {
    final versions = await get<CacheService>().getAllVersions();
    return logger.cacheVersionSelector(versions);
  }
  return argResults!.rest[0];
}
```

**Then replace in all 3 commands with:**
```dart
final version = await getVersionArgument();
```

**Effort:** 20 minutes
**Impact:** Easier to maintain, one place to update logic

### 11. Code Duplication - Workflow Initialization
**Files:** 5+ command files
**Problem:** Every command manually creates workflows

**Add to base_command.dart:**
```dart
EnsureCacheWorkflow get ensureCache => EnsureCacheWorkflow(context);
ValidateFlutterVersionWorkflow get validateFlutterVersion =>
    ValidateFlutterVersionWorkflow(context);
UseVersionWorkflow get useVersion => UseVersionWorkflow(context);
```

**Then replace:**
```dart
// Old:
final ensureCache = EnsureCacheWorkflow(context);

// New:
final cacheVersion = await ensureCache(flutterVersion);
```

**Effort:** 30 minutes
**Impact:** Less boilerplate, cleaner command code

### 12. Unused Constant
**File:** `lib/src/utils/constants.dart:23`
**Problem:** `kFvmDocsConfigUrl` is defined but never used
**Fix:** Delete line 23
**Effort:** 1 minute
**Impact:** Cleanup

### 13. File Operations Duplication
**Files:** 12 locations manually doing `createSync(recursive: true)`
**Problem:** Extension already exists but not used consistently
**Fix:** Replace manual checks with existing extension method

**Current pattern in multiple files:**
```dart
if (!directory.existsSync()) {
  directory.createSync(recursive: true);
}
```

**Extension already exists in `lib/src/utils/extensions.dart:47-51`:**
```dart
void ensureCreated() {
  if (!existsSync()) {
    createSync(recursive: true);
  }
}
```

**Action:** Use the extension instead of manual checks

**Effort:** 15 minutes
**Impact:** More consistent, less code

### 14. Table Creation Inconsistency
**Files:** 5+ files manually creating tables
**Problem:** `createTable()` utility exists but not used consistently

**Current:** Many files manually configure tables
**Fix:** Use existing `lib/src/utils/console_utils.dart` utility everywhere

**Effort:** 20 minutes
**Impact:** Consistent table styling

### 15. Duplicate Comments in Models
**Files:**
- `lib/src/models/project_model.dart:184-185` (two consecutive identical comments)
- `lib/src/models/cache_flutter_version_model.dart:56, 66` (duplicate "Returns dart exec file" for different methods)

**Fix:** Remove one comment from project_model.dart, differentiate comments in cache_flutter_version_model.dart

**Effort:** 2 minutes
**Impact:** Cleaner docs

### 16. Outdated TODO Comment
**File:** `test/src/services/project_service_test.dart:65`
**Problem:** TODO about finding alternative approach, but test is permanently skipped
**Fix:** Either implement the TODO or update comment to explain why test is skipped

**Effort:** 5 minutes (or more if implementing)
**Impact:** Clear expectations

---

## Summary by Effort

### Quick Wins (< 10 minutes each)
- Fix null pointer in file_lock.dart
- Remove scope dependency
- Fix incorrect documentation (3 places)
- Delete unused constant
- Fix duplicate comments

**Total effort: ~25 minutes**
**Total impact: Prevents crashes, cleaner code**

### Short Tasks (10-30 minutes each)
- Fix memory leak in git_service.dart
- Fix symlink race condition
- Add timeout to lock acquisition
- Fix broken symlink handling
- Standardize AppException usage
- Version selection utility
- File operations consistency
- Table creation consistency

**Total effort: ~2-3 hours**
**Total impact: Better reliability, less duplication**

### Longer Tasks (30+ minutes)
- Standardize error re-throwing pattern
- Workflow initialization refactor

**Total effort: ~1 hour**
**Total impact: More maintainable codebase**

---

## Recommended Approach

**Week 1: Critical + High Priority**
1. Fix null pointer crash (5 min)
2. Fix memory leak (15 min)
3. Remove unused dependency (2 min)
4. Fix symlink race condition (10 min)
5. Fix incorrect documentation (5 min)

**Week 2: Medium Priority**
1. Add lock timeout (10 min)
2. Fix broken symlink handling (5 min)
3. Standardize AppException usage (10 min)
4. Standardize error re-throwing (30 min)

**Week 3: Low Priority (as time permits)**
1. Version selection utility (20 min)
2. Workflow initialization helpers (30 min)
3. Use existing utilities consistently (35 min)
4. Clean up docs and TODOs (10 min)

**Total time investment: ~4-5 hours**
**Return: More reliable, maintainable codebase**

---

## What's NOT Included (Intentionally)

These were identified but are not real problems:
- ❌ Minor comment style preferences (verbose but not wrong)
- ❌ Variable naming that's clear enough in context
- ❌ Patterns that are fine even if not "perfect"
- ❌ Theoretical issues that don't affect real usage
- ❌ Over-engineering new abstractions

This plan focuses on real bugs, real maintenance pain points, and real cleanup opportunities.
