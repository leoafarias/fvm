# Git Cache Hybrid Plan - Current State Validation Report
**Generated**: 2025-11-17
**Repository**: FVM (Flutter Version Manager)
**Branch**: claude/multi-agent-orchestration-01Mo4XqPHqSKrKSzj5tgt8g8

---

## EXECUTIVE SUMMARY

The plan's claims are **PARTIALLY ACCURATE but with SIGNIFICANT INACCURACIES**:
- 3 out of 4 line number ranges are wrong
- Core behaviors described are generally correct
- Multiple important features not mentioned in the plan exist
- **CRITICAL ISSUE**: Code references undefined function `runGit`

---

## CLAIM-BY-CLAIM VALIDATION

### Claim 1: GitService._createLocalMirror (Regular git clone)

**Status**: PARTIALLY ACCURATE ✓/✗

**Line Numbers**: 
- Plan states: `lib/src/services/git_service.dart:29-78`
- **ACTUAL**: Lines 29-69 (40 lines, not 50)
- **VERDICT**: INACCURATE

**Function Behavior**:
```dart
// Lines 29-69
Future<void> _createLocalMirror() async {
  final gitCacheDir = Directory(context.gitCachePath);
  logger.info('Creating local mirror...');
  final process = await Process.start(
    'git',
    [
      'clone',
      '--progress',
      if (Platform.isWindows) '-c',
      if (Platform.isWindows) 'core.longpaths=true',
      context.flutterUrl,
      gitCacheDir.path,
    ],
    runInShell: true,
  );
  // ... error handling and logging
}
```

**Validation**:
- ✓ Performs regular `git clone` (not bare)
- ✓ Leaves both working tree and `.git` directory
- ✓ Includes progress tracking
- ✓ Handles Windows long paths
- ✓ Throws on failure and cleans up partial clone

**Additional Notes**:
- Uses `Process.start()` with stderr/stdout listening (lines 50-58)
- Uses `GitCloneProgressTracker` utility
- Automatically deletes cache on failure (line 63)

---

### Claim 2: updateLocalMirror (Non-bare repo operations)

**Status**: PARTIALLY ACCURATE ✓/✗

**Line Numbers**:
- Plan states: `lib/src/services/git_service.dart:111-173`
- **ACTUAL**: Lines 109-185 (77 lines, not 63)
- **VERDICT**: INACCURATE (off by 2 lines start, 12 lines end)

**Function Behavior**:
```dart
// Lines 109-185
Future<void> updateLocalMirror() async {
  final unlock = await _updatingCacheLock.getLock();  // Line 110 - MISSED BY PLAN
  final gitCacheDir = Directory(context.gitCachePath);
  final isGitDir = await GitDir.isGitDir(gitCacheDir.path);

  try {
    if (isGitDir) {
      // Lines 117-148: Update operations
      await gitDir.runCommand(['reset', '--hard', 'HEAD']);      // Line 124
      await gitDir.runCommand(['clean', '-fd']);                  // Line 125
      await gitDir.runCommand(['remote', 'prune', 'origin']);    // Line 129
      await gitDir.runCommand(['fetch', '--all', '--tags', '--prune']);  // Line 133
      
      // Lines 135-147: Corruption check
      final statusResult = await gitDir.runCommand(['status', '--porcelain']);
      if (output.isEmpty) {
        logger.debug('No uncommitted changes. Working directory is clean.');
      } else {
        await _createLocalMirror();  // Line 146 - CORRUPTED, RECREATE
      }
    } else {
      await _createLocalMirror();  // Line 180
    }
  } finally {
    unlock();  // Line 183 - MISSED BY PLAN
  }
}
```

**Validation**:
- ✓ Hard-reset: `reset --hard HEAD` (line 124)
- ✓ Clean: `clean -fd` (line 125)
- ✓ Prune: `remote prune origin` (line 129)
- ✓ Fetch: `fetch --all --tags --prune` (line 133)
- ✓ Assumes non-bare repository (explicit git operations)

**ADDITIONAL FEATURES NOT MENTIONED IN PLAN**:

1. **File Lock Mechanism** (lines 110, 183):
   ```dart
   final unlock = await _updatingCacheLock.getLock();
   try { ... } finally { unlock(); }
   ```
   - 10-minute timeout lock for concurrent access protection
   - Cross-process synchronization
   - Prevents concurrent mirror updates

2. **Corruption Detection** (lines 156-163):
   ```dart
   } catch (e) {
     if (e is ProcessException) {
       final messageLower = e.message.toLowerCase();
       if (messageLower.contains('not a git repository') ||
           messageLower.contains('corrupt') ||
           messageLower.contains('damaged') ||
           messageLower.contains('hash mismatch') ||
           (messageLower.contains('object file') &&
               messageLower.contains('empty'))) {
         logger.warn('Local mirror appears to be corrupted...');
         await _createLocalMirror();
         return;
       }
     }
   ```
   - Detects: "not a git repository", "corrupt", "damaged", "hash mismatch", "object file empty"
   - Auto-recovers by recreating mirror
   - Re-throws non-corruption errors

3. **Status Check Before Return** (lines 135-147):
   ```dart
   final statusResult = await gitDir.runCommand(['status', '--porcelain']);
   final output = (statusResult.stdout as String).trim();
   if (output.isEmpty) {
     logger.debug('No uncommitted changes. Working directory is clean.');
   } else {
     await _createLocalMirror();  // Recreate if dirty
   }
   ```

---

### Claim 3: _cloneWithFallback (Reference-first fallback)

**Status**: PARTIALLY ACCURATE ✓/✗

**Line Numbers**:
- Plan states: `lib/src/services/flutter_service.dart:24-89`
- **ACTUAL**: Lines 26-77 (52 lines, not 66)
- **VERDICT**: INACCURATE (off by 2 lines start, 12 lines end)

**Function Behavior**:
```dart
// Lines 26-77
Future<ProcessResult> _cloneWithFallback({
  required String repoUrl,
  required Directory versionDir,
  required FlutterVersion version,
  required String? channel,
}) async {
  final args = [...];  // Setup base args
  
  // Try with --reference first if git cache is enabled (Line 47)
  if (context.gitCache) {
    try {
      return await runGit(  // LINE 49 - **CALLS UNDEFINED FUNCTION**
        [
          ...args,
          '--reference',
          context.gitCachePath,
          repoUrl,
          versionDir.path,
        ],
        echoOutput: echoOutput,
      );
    } on ProcessException catch (e) {
      if (isReferenceError(e.toString())) {  // Line 60
        logger.warn('Git clone with --reference failed, falling back...');
        _cleanupPartialClone(versionDir);  // Line 64
      } else {
        rethrow;
      }
    }
  }

  // Normal clone without --reference (Line 72)
  return await runGit(  // LINE 73 - **CALLS UNDEFINED FUNCTION**
    [...args, repoUrl, versionDir.path],
    echoOutput: echoOutput,
  );
}
```

**Validation**:
- ✓ Tries `--reference` first if `context.gitCache` enabled (line 47)
- ✓ Falls back to normal clone (line 72-76)
- ✓ Catches reference errors and retries (line 59-69)

**CRITICAL ISSUE - UNDEFINED FUNCTION**:

⚠️ **Lines 49 and 73 call `runGit(...)` which is UNDEFINED in the codebase**

```
RESULT: This function does not exist anywhere:
  - Not defined in flutter_service.dart
  - Not defined in any imported service
  - Not defined as extension
  - Not defined as top-level function
  - Not found in entire lib/ directory
```

**Implications**:
- This code will NOT compile
- `runGit` needs to be defined, likely as wrapper around ProcessService
- Expected signature: `Future<ProcessResult> runGit(List<String> args, {bool echoOutput})`
- Should shell out to git command with proper error handling

**ADDITIONAL FEATURES NOT MENTIONED**:

1. **Reference Error Detection** (lines 322-335):
   ```dart
   bool isReferenceError(String errorMessage) {
     final lowerMessage = errorMessage.toLowerCase();
     const referenceErrorPatterns = [
       'reference repository',
       'reference not found',
       'unable to read reference',
       'bad object',
     ];
     return referenceErrorPatterns.any(lowerMessage.contains) ||
         (lowerMessage.contains('corrupt') &&
             lowerMessage.contains('reference'));
   }
   ```

2. **Partial Clone Cleanup** (lines 79-88):
   ```dart
   void _cleanupPartialClone(Directory versionDir) {
     try {
       if (versionDir.existsSync()) {
         versionDir.deleteSync(recursive: true);
       }
     } catch (_) {
       // Ignore cleanup failures
     }
   }
   ```

3. **Channel/Branch Support** (lines 36-41):
   ```dart
   if (!version.isUnknownRef && channel != null) ...[
     '-c', 'advice.detachedHead=false',
     '-b', channel,
   ],
   ```

---

### Claim 4: Reference Discovery (Git ls-remote)

**Status**: ACCURATE with IMPORTANT CAVEATS ✓

**Line Numbers**:
- Plan states: `lib/src/services/git_service.dart:72-101`
- **ACTUAL**: Function is 72-95, but `isGitReference` at 97-101 uses it
- **VERDICT**: PARTIALLY ACCURATE (function narrower, but scope correct)

**Reference Discovery Implementation**:
```dart
// Lines 72-95
Future<List<GitReference>> _fetchGitReferences() async {
  if (_referencesCache != null) return _referencesCache!;  // Line 73 - IN-MEMORY CACHE

  final List<String> command = ['ls-remote', '--tags', '--branches'];
  command.add(context.flutterUrl);

  try {
    final result = await get<ProcessService>().run(
      'git',
      args: command,  // USES: git ls-remote --tags --branches <url>
    );

    return _referencesCache = GitReference.parseGitReferences(
      result.stdout as String,
    );
  } on ProcessException catch (error, stackTrace) {
    logger.debug('ProcessException while fetching git references: $error');
    Error.throwWithStackTrace(
      AppException(
        'Failed to fetch git references from ${context.flutterUrl}. '
        'Ensure git is installed and the URL is accessible.',
      ),
      stackTrace,
    );
  }
}

// Lines 97-101
Future<bool> isGitReference(String version) async {
  final references = await _fetchGitReferences();
  return references.any((reference) => reference.name == version);
}
```

**Validation**:
- ✓ Uses `git ls-remote` (line 75)
- ✓ Requires network connectivity (confirmed)
- ✓ Works even when mirror has all refs

**IMPORTANT CAVEAT - CACHING LIMITATION**:

1. **In-Memory Caching ONLY** (lines 19, 73, 82):
   ```dart
   late final List<GitReference>? _referencesCache;  // Line 19
   if (_referencesCache != null) return _referencesCache!;  // Line 73
   return _referencesCache = GitReference.parseGitReferences(...);  // Line 82
   ```
   - Cache is per-process (lost on restart)
   - Cache is per-GitService instance
   - No persistent storage

2. **Network Access Always Required for First Call**:
   - First call to `isGitReference` triggers `git ls-remote`
   - Even with full mirror, still needs network
   - Plan should address persistent caching

3. **Reference Validation Skipped** (validate_flutter_version.workflow.dart:35-36):
   ```dart
   // Skip git reference validation - let the installation process handle it
   logger.debug('Skipping git reference validation for version: $version');
   ```

---

## ADDITIONAL CONTEXT & FEATURES

### Fork Support (Not Mentioned in Plan)

**FlutterVersion.parse()** (lines 74-140 in flutter_version_model.dart):
```dart
// Supports pattern: [fork/]version[@channel]
// Examples: "my-fork/stable", "upstream/main", "fork/v3.15.0"
```

**FlutterFork Model** (lines 192-203):
```dart
class FlutterFork with FlutterForkMappable {
  final String name;
  final String url;
}
```

**Fork Directory Handling** (flutter_service.dart:142-150):
```dart
if (version.fromFork) {
  final forkDir = Directory(
    path.join(context.versionsCachePath, version.fork!),
  );
  if (!forkDir.existsSync()) {
    forkDir.createSync(recursive: true);
  }
}
```

**EnsureCacheWorkflow Skips Cache Update for Forks** (line 175):
```dart
// Only update local mirror if not a fork and git cache is enabled
if (useGitCache && !version.fromFork) {
  try {
    await gitService.updateLocalMirror();
  } on Exception {
    logger.warn('Failed to setup local cache. Falling back to git clone.');
  }
}
```

**Critical Finding**: Forks are explicitly EXCLUDED from cache mirror updates. The plan needs to address:
- How will fork-specific caches work?
- Should each fork have its own mirror?
- Or should forks always direct-clone?

### Cache Integrity Verification

**CacheIntegrity Enum** (cache_service.dart:14-22):
```dart
enum CacheIntegrity {
  valid,
  invalid,
  versionMismatch;
}
```

**verifyCacheIntegrity()** (cache_service.dart:170-180):
- Checks if executable exists and is executable
- Verifies version matches (complex semver logic, lines 276-314)
- Three-tier validation

**Corruption Auto-Recovery** (ensure_cache.workflow.dart:18-36):
- Non-executable caches auto-removed and reinstalled
- Logged as corruption, triggers immediate reinstall

### Lock Mechanism

**FileLocker** (context.dart:208-217):
- 10-second default expiry
- Cross-process synchronization
- Prevents concurrent operations on same resource
- Used in GitService._updatingCacheLock (git_service.dart:22-26)

### Test Coverage Assessment

**Found Tests**:
- `test/services/git_service_test.dart` - Tests `_fetchGitReferences` error handling
- `test/services/git_clone_fallback_test.dart` - Tests reference error detection
- `test/utils/is_git_commit_test.dart` - Tests commit validation
- `test/src/utils/git_clone_progress_tracker_test.dart` - Tests progress tracking

**Missing Tests**:
- ❌ `_createLocalMirror()` - No direct tests
- ❌ `updateLocalMirror()` - No direct tests
- ❌ Corruption detection logic - No specific tests
- ❌ Cache fallback on reference failure - Integration test needed
- ❌ Fork-specific cache handling - No tests

**Test Quality**: Low coverage of core git cache functionality

---

## INACCURACIES & GAPS

### 1. Line Number Inaccuracies (3 of 4)

| Claim | Stated Lines | Actual Lines | Error |
|-------|-------------|-------------|-------|
| _createLocalMirror | 29-78 | 29-69 | -9 lines |
| updateLocalMirror | 111-173 | 109-185 | -2 start, +12 end |
| _cloneWithFallback | 24-89 | 26-77 | +2 start, -12 end |
| _fetchGitReferences | 72-101 | 72-95 + 97-101 | Partial ✓ |

### 2. Missing Features in Plan

| Feature | Location | Impact |
|---------|----------|--------|
| File lock for concurrent access | git_service.dart:22, 110, 183 | Prevents race conditions |
| Corruption detection & auto-recovery | git_service.dart:156-163 | Maintains integrity |
| Reference error classification | flutter_service.dart:322-335 | Enables smart fallback |
| Partial clone cleanup | flutter_service.dart:79-88 | Prevents disk space leaks |
| In-memory reference cache | git_service.dart:19, 73, 82 | Reduces git ls-remote calls |
| Fork-specific handling | flutter_service.dart:142-150, ensure_cache:175 | Required for fork support |
| Cache integrity verification | cache_service.dart:170-180 | Validates cache state |
| Version matching logic | cache_service.dart:276-314 | Complex semver rules |

### 3. Critical Issues

**BLOCKER**: `runGit()` function undefined
- Lines 49, 73 in flutter_service.dart call undefined function
- Code will not compile
- Must be implemented before plan execution
- Signature needed: `Future<ProcessResult> runGit(List<String> args, {bool echoOutput})`

### 4. Fork Cache Strategy Unclear

Current behavior:
- Forks are EXCLUDED from cache mirror updates
- Each fork install does direct clone

Plan consideration needed:
- Should forks have separate mirrors?
- Or continue with direct-clone approach?
- How does --reference work with fork URLs?

### 5. Persistent Reference Caching Missing

- Only in-memory cache exists
- Per-process, lost on restart
- Plan should add persistent layer
- Consider: ~/.fvm/ref-cache.json or similar

### 6. Reference Validation Skipped

- `ValidateFlutterVersionWorkflow` skips git ref validation (line 35-36)
- Validation deferred to install time
- Could cause delayed error discovery

---

## IMPLEMENTATION RECOMMENDATIONS FOR PLAN

### Must Address

1. **Define `runGit()` function** before implementation
   - Wrap ProcessService.run for git commands
   - Handle echoOutput flag
   - Should it use --reference automatically?

2. **Document bare vs non-bare choice**
   - Current: Non-bare (has working directory)
   - Implications for --reference support
   - Impact on lock mechanism

3. **Fork cache strategy**
   - Decide: shared cache vs separate caches vs direct-clone
   - Plan for --reference with fork URLs
   - Update EnsureCacheWorkflow guards

4. **Test coverage expansion**
   - Add unit tests for `_createLocalMirror()`
   - Add unit tests for `updateLocalMirror()` corruption detection
   - Add integration test for fallback scenario
   - Add fork-specific cache tests

### Should Consider

1. **Persistent reference cache**
   - Persist `git ls-remote` results locally
   - Time-based invalidation (1 day?)
   - Reduces network dependency

2. **Lock timeout tuning**
   - Current: 10 minutes for updateLocalMirror
   - May be too long for large repos
   - Monitor in practice

3. **Windows compatibility**
   - Long path handling already present (lines 38-39)
   - runGit implementation should test this

4. **Reference error message clarity**
   - Current patterns comprehensive
   - Consider logging actual git error for debugging

---

## SUMMARY FINDINGS

### Accuracy Assessment

- **Current State Claims**: 2 accurate, 2 inaccurate (line numbers)
- **Core Behaviors**: Mostly correct, but incomplete
- **Missing Features**: 8+ features not mentioned but present
- **Critical Blocker**: runGit() undefined - CODE WILL NOT COMPILE

### Risk Level: **HIGH**

**Primary Risk**:
- Undefined `runGit()` function blocks all development
- Must implement before proceeding

**Secondary Risks**:
- Fork handling strategy not clear
- Reference caching incomplete (no persistence)
- Test coverage sparse for core logic
- Line numbers require correction in documentation

### Recommendation

✗ **NOT READY FOR EXECUTION** - Code has compilation blocker

**Before proceeding**:
1. Define and implement `runGit()` function
2. Correct all line number references
3. Clarify fork cache strategy
4. Expand test coverage
5. Address persistent reference caching
