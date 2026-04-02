# PR #962 - Deep Analysis: Security Fix for Short Commit Hash Vulnerability

> Status update (2025-12-09): PR #962 was closed without merge after the maintainer determined issue #783 is not a security vulnerability. This analysis is retained for historical context.

## TL;DR - Answers to Your Questions

### Is this needed?
**YES** - The vulnerability exists today in v4.0.x. When users run `fvm use abc123def0` (short commit hash), that exact short hash gets stored in `.fvmrc`. Short hashes can collide between forks, enabling DOS attacks.

### What does it do?
Expands short commit hashes to full 40-character SHA-1 before storing:
```
Before: .fvmrc → {"flutter": "6d04a16210"}     // 10 chars - vulnerable
After:  .fvmrc → {"flutter": "6d04a162109d..."}  // 40 chars - secure
```

### Are there regressions?
**NO regressions** - The fix is transparent:
- Users can still type short hashes in commands
- Existing projects auto-upgrade on next `fvm use`
- Semantic versions (3.10.0) and channels (stable) unchanged

### What's the impact?
| Concern | Answer |
|---------|--------|
| Breaking changes | None |
| Performance | +1 git rev-parse call (negligible) |
| User workflow | Unchanged |
| Existing configs | Work as-is, upgrade on next `fvm use` |

### Should you merge it?
**Not yet** - PR needs:
1. Rebase (conflicts with merged PR #981)
2. Fix fail-unsafe pattern (currently stores short hash if resolution fails)
3. Add missing tests for fork-prefixed versions

---

## PR Details
- **Number**: #962
- **Title**: Security: Store full commit hashes in config to prevent DOS attacks
- **Author**: GitHub Copilot (@app/copilot-swe-agent)
- **Created**: November 4, 2025
- **Status**: OPEN - NEEDS REBASE + FIXES
- **Fixes**: Issue #783
- **Link**: https://github.com/leoafarias/fvm/pull/962

---

## Problem Statement

### The Vulnerability (Issue #783)
Short commit hashes (10 chars) stored in `.fvmrc` can be exploited for **denial-of-service attacks** via hash collisions across repository forks.

**Attack Scenario**:
1. Victim's `.fvmrc` contains short hash: `{"flutter": "6d04a16210"}`
2. Attacker creates Flutter fork with malicious commit
3. Attacker crafts commit with colliding 10-char prefix
4. Victim clones/installs - gets attacker's malicious code
5. Build system compromised

**Reference**: https://blog.teddykatz.com/2019/11/12/github-actions-dos.html

---

## Proposed Solution

### New Method: `GitService.resolveCommitHash()`
```dart
Future<String?> resolveCommitHash(String commitRef, FlutterVersion version)
```
- Uses `git rev-parse` to expand any commit reference to full 40-char SHA-1
- Returns `null` if resolution fails
- Validates output is exactly 40 hex characters

### Integration in UpdateProjectReferencesWorkflow
```dart
String versionToStore = version.name;
if (version.isUnknownRef) {
  final fullHash = await get<GitService>().resolveCommitHash(
    version.version,
    version,
  );
  if (fullHash != null) {
    versionToStore = fullHash;
  }
}
```

---

## ⚠️ CRITICAL: Merge Conflict with PR #981

**PR #981** (just merged) modified the same lines in `update_project_references.workflow.dart`:

| Lines | Main (after #981) | PR #962 (stale) |
|-------|-------------------|-----------------|
| 145-146 | `version.nameWithAlias` | `version.name` → `versionToStore` |

### Required Rebase Changes
After rebasing on main, PR #962 must use `nameWithAlias` pattern:
```dart
String versionToStore = version.nameWithAlias;  // Not version.name
if (version.isUnknownRef) {
  final fullHash = await get<GitService>().resolveCommitHash(
    version.version,  // Still correct - use version part only
    version,
  );
  if (fullHash != null) {
    versionToStore = fullHash;
  }
}
```

---

## Expert Review Findings

### 1. Security Analysis (Critical Issues)

#### Issue A: Fail-Unsafe Pattern (CRITICAL)
**Severity**: HIGH
**Location**: `update_project_references.workflow.dart`

```dart
if (fullHash != null) {
  versionToStore = fullHash;
}
// If fullHash is null, versionToStore remains short hash!
```

**Problem**: When `resolveCommitHash()` returns `null` (network failure, non-git dir, etc.), the SHORT HASH is silently stored - **vulnerability persists**.

**Fix Required**:
```dart
if (version.isUnknownRef) {
  final fullHash = await get<GitService>().resolveCommitHash(...);
  if (fullHash == null) {
    throw AppException(
      'Security: Failed to expand commit hash. Cannot safely store version.'
    );
  }
  versionToStore = fullHash;
}
```

#### Issue B: Weak Regex Validation (MEDIUM)
**Severity**: MEDIUM
**Location**: `git_service.dart`

```dart
static final _sha1HashRegex = RegExp(r'^[0-9a-fA-F]+$');
```

**Problem**: Matches ANY length hex string. The `length == 40` check happens separately, but the regex should enforce length for clarity and to prevent ReDoS on long inputs.

**Fix Required**:
```dart
static final _sha1HashRegex = RegExp(r'^[0-9a-fA-F]{40}$');
```

#### Issue C: Backward Compatibility Risk (HIGH)
**Severity**: HIGH

**Problem**: Existing `.fvmrc` files with short hashes remain vulnerable indefinitely. They only get upgraded on `fvm use`, not `fvm install`.

**Recommendations**:
1. Add warning when reading configs with short hashes
2. Consider `fvm migrate-config` command
3. Auto-upgrade on ANY fvm command, not just `use`

#### Issue D: Timing of Resolution (MEDIUM)
**Severity**: MEDIUM

Hash is resolved AFTER installation. If collision exists at install time, wrong commit is already cloned before hash expansion.

**Ideal Fix**: Resolve hash BEFORE cloning in install workflow.

---

### 2. Test Coverage Analysis

**Current Coverage Rating**: 4/10

#### Unit Tests (`git_service_hash_resolution_test.dart`)
| Test | Coverage |
|------|----------|
| Method exists | ✅ Trivial |
| Non-git directory returns null | ✅ |
| Short hash expansion | ❌ Missing |
| Full hash preservation | ❌ Missing |
| Invalid hash handling | ❌ Missing |
| Empty string | ❌ Missing |

#### Integration Tests (`commit_hash_resolution_test.dart`)
| Test | Coverage |
|------|----------|
| Short hash → full hash | ✅ |
| Full hash preserved | ✅ |
| Non-commit versions unchanged | ✅ |
| Fork-prefixed commits | ❌ Missing |
| Resolution failure fallback | ❌ Missing |

#### Workflow Tests
| Test | Coverage |
|------|----------|
| `isUnknownRef = true` path | ❌ Missing |
| GitService mock verification | ❌ Missing |

**Critical Missing Tests**:
1. Fork-prefixed commit hash (e.g., `myfork/abc123`)
2. Resolution failure → fallback behavior
3. Workflow test with `isUnknownRef = true`
4. Invalid/malicious input handling

---

### 3. Code Quality Issues

#### A. Insufficient Security Logging
```dart
logger.debug('Failed to resolve commit hash: $e');
```
**Problem**: Security failures logged at DEBUG level - users don't see them.

**Fix**: Use `logger.warn()` for security-relevant events.

#### B. Missing Input Validation
```dart
final pr = await gitDir.runCommand(['rev-parse', commitRef]);
```
**Problem**: No validation that `commitRef` is a hex string before passing to git.

**Risk**: While git handles this safely, explicit validation is better.

**Fix**:
```dart
if (!RegExp(r'^[0-9a-fA-F]+$').hasMatch(commitRef)) {
  throw AppException('Invalid commit hash format');
}
```

---

## Files Changed (9 files)

| File | Changes | Issues |
|------|---------|--------|
| `lib/src/services/git_service.dart` | +54 lines, new `resolveCommitHash()` | Weak regex, missing input validation |
| `lib/src/workflows/update_project_references.workflow.dart` | +15 lines | Fail-unsafe, needs rebase for #981 |
| `lib/fvm.dart` | +1 export | OK |
| `test/services/git_service_hash_resolution_test.dart` | New file | Minimal coverage |
| `test/integration/commit_hash_resolution_test.dart` | New file | Good but missing fork tests |
| `test/src/workflows/update_project_references.workflow_test.dart` | +3 lines mock | Missing isUnknownRef=true test |
| `test/commands/install_command_test.dart` | -1 import | OK |
| `docs/security-fix-full-commit-hash.md` | New documentation | Good |
| `IMPLEMENTATION_SUMMARY.md` | New file | Should be removed |

---

## Multi-Agent Validation Checklist

### Agent 1: Security Validation
- [ ] Verify fail-safe pattern implemented (throw on null, don't fallback)
- [ ] Verify regex enforces exactly 40 chars
- [ ] Verify input validation before git rev-parse
- [ ] Test with malicious inputs (special chars, long strings)
- [ ] Verify security events logged at WARN level

### Agent 2: Fork Compatibility (Post-#981)
- [ ] Rebase on main (includes #981 changes)
- [ ] Use `nameWithAlias` for non-commit versions
- [ ] Test fork-prefixed commit hashes work correctly
- [ ] Verify `version.version` correctly strips fork prefix

### Agent 3: Test Coverage
- [ ] Add unit test for successful hash resolution
- [ ] Add unit test for hash resolution failure
- [ ] Add workflow test with `isUnknownRef = true`
- [ ] Add test for fork-prefixed commits
- [ ] Add edge case tests (empty, invalid chars)

### Agent 4: Backward Compatibility
- [ ] Test existing configs with short hashes still work
- [ ] Verify upgrade happens on `fvm use`
- [ ] Consider warning for short hashes in configs
- [ ] Document migration path for users

---

## Recommendations

### Before Merge (Required)
1. **Rebase on main** - Resolve conflicts with PR #981
2. **Fix fail-unsafe pattern** - Throw exception instead of silent fallback
3. **Improve regex** - Use `RegExp(r'^[0-9a-fA-F]{40}$')`
4. **Add missing tests** - Fork-prefixed commits, failure handling

### After Merge (Recommended)
1. **Security advisory** - Notify users about upgrading configs
2. **Add `fvm migrate-config`** - Command to upgrade all configs
3. **Add startup warning** - Warn when short hashes detected in `.fvmrc`

### Files to Clean Up
- Remove `IMPLEMENTATION_SUMMARY.md` (not needed in repo)

---

## Verdict

**Status**: DO NOT MERGE YET

**Blockers**:
1. ❌ Needs rebase on main (conflicts with PR #981)
2. ❌ Fail-unsafe pattern must be fixed
3. ❌ Missing critical tests for fork versions

**After Fixes**:
The core approach is sound. Once rebased and the critical issues are fixed, this PR will properly address the security vulnerability.

---

## Timeline

- **Nov 4, 2025**: PR opened by GitHub Copilot
- **Dec 5, 2025**: PR #981 merged (creates conflict)
- **Dec 5, 2025**: Deep analysis completed - issues identified
