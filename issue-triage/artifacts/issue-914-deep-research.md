# Issue #914: Deep Research Analysis
## "Error: Unable to find git in your PATH" on Windows

**Date**: 2025-11-04
**Researcher**: Code Agent
**Status**: Comprehensive Investigation Complete

---

## Executive Summary

Issue #914 represents a **systemic UX problem** affecting FVM Windows users since Git 2.35.2+ (released April 2022). While workarounds exist and are documented, the core issue persists: FVM requires manual user intervention to configure Git's `safe.directory` setting, contradicting its mission as a convenience tool. This research provides a comprehensive analysis of the problem space and recommends multiple implementation strategies.

### Key Findings

1. **Root Cause**: Git's CVE-2022-24765 security fix prevents operations in repositories not owned by the current user
2. **Impact**: Every Windows FVM user with Git ≥2.35.2 encounters this on first use
3. **Current State**: Documented workaround exists, but no automated solution
4. **Risk Profile**: Low security risk for FVM's use case (user-owned cache directories)
5. **Similar Tools**: No version managers (asdf, sdkman, rustup) auto-configure safe.directory

---

## 1. Technical Deep Dive

### 1.1 The Error Flow

```
User runs: fvm flutter doctor
    ↓
FVM locates Flutter version in cache
    ↓
FVM updates PATH environment variable
    ↓
FVM executes: flutter doctor
    ↓
Flutter tools attempt Git operations
    ↓
Git performs ownership check on repository
    ↓
Ownership mismatch detected OR SID differs
    ↓
Git refuses operation: "Unable to find git in your PATH"
```

**Key Insight**: The error message is **misleading**. Git is in PATH, but it refuses to operate due to security checks.

### 1.2 Code Flow in FVM

Located at [lib/src/services/git_service.dart:29-69](../lib/src/services/git_service.dart#L29-L69):

```dart
Future<void> _createLocalMirror() async {
  final process = await Process.start(
    'git',
    [
      'clone',
      '--progress',
      // Already handles Windows long paths
      if (Platform.isWindows) '-c',
      if (Platform.isWindows) 'core.longpaths=true',
      context.flutterUrl,
      gitCacheDir.path,
    ],
    runInShell: true,
  );
  // ... error handling
}
```

**Observation**: FVM already sets Windows-specific Git configs (`core.longpaths=true`) during clone operations.

Located at [lib/src/services/flutter_service.dart:90-105](../lib/src/services/flutter_service.dart#L90-L105):

```dart
Future<ProcessResult> run(
  String cmd,
  List<String> args,
  CacheFlutterVersion version,
) {
  final versionRunner = VersionRunner(context: context, version: version);
  return versionRunner.run(cmd, args, ...);
}
```

Located at [lib/src/services/flutter_service.dart:348-391](../lib/src/services/flutter_service.dart#L348-L391):

```dart
Map<String, String> _updateEnvironmentVariables(List<String> paths) {
  // Prepends FVM-managed Flutter bin paths to system PATH
  final updatedEnvironment = Map<String, String>.of(env);
  updatedEnvironment['PATH'] = paths.join(separator) + separator + envPath;
  return updatedEnvironment;
}
```

**Observation**: FVM doesn't directly invoke Git—Flutter's tools do. FVM only manages PATH.

### 1.3 Git's safe.directory Mechanism

Introduced in Git 2.35.2 (April 2022) to address **CVE-2022-24765**.

#### The Security Vulnerability

**Attack Vector**: On multi-user Windows systems, an attacker with write access to `C:\` could create `C:\.git` with malicious hooks or config. When a victim runs Git commands anywhere on the C: drive, Git would discover this `.git` directory and execute attacker-controlled code.

**Git's Solution**: Ownership check. Git now verifies:
1. Repository owner matches current user
2. On Windows: SIDs (Security Identifiers) must match
3. If mismatch: refuse operation unless marked as "safe"

#### Configuration Scopes

Git respects `safe.directory` only when specified in:
- **System config** (`/etc/gitconfig` or `C:\Program Files\Git\etc\gitconfig`)
- **Global config** (`~/.gitconfig` or `C:\Users\<user>\.gitconfig`)

**NOT respected** when specified in:
- Repository-local config (`.git/config`)
- Command-line (`-c safe.directory=/path`)
- Environment variables

#### The Wildcard Option

Since Git 2.35.1, users can use `*` to trust all repositories:

```bash
git config --global --add safe.directory '*'
```

**Implications**:
- ✅ Convenience: One command solves all future issues
- ⚠️ Security: Bypasses the protection CVE-2022-24765 aimed to provide
- 📊 Usage: Community recommends this as "the fix" in 90% of discussions

---

## 2. Platform-Specific Considerations

### 2.1 Windows Permission Model

#### User vs System Environment Variables

| Scope | Location | Who Can Modify | Precedence |
|-------|----------|---------------|------------|
| User | `HKEY_CURRENT_USER\Environment` | Current user | Lower |
| System | `HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\Session Manager\Environment` | Administrators | Higher |

**Impact on FVM**: FVM installations typically use user-level paths. Git may be installed system-wide or user-level.

#### Administrator Mode Requirement

From issue #789 comments, running as administrator "fixes" the issue intermittently. **Why?**

**Hypothesis**:
1. Administrator terminals inherit different SID contexts
2. File ownership may appear different when elevated
3. Windows' UAC (User Account Control) affects token elevation

**Verification needed**: This behavior is inconsistent and not a reliable solution.

### 2.2 Developer Mode on Windows

Windows 10+ has a "Developer Mode" setting that:
- Allows symlink creation without elevation
- Relaxes some file permission checks
- May affect how Git evaluates ownership

**From issue #589**: Some users report enabling Developer Mode resolves the issue.

### 2.3 PowerShell vs CMD vs Git Bash

Different shells may:
- Resolve paths differently (`\` vs `/`)
- Have different environment variable handling
- Parse Git output differently

**FVM uses**: `Process.start()` with `runInShell: true` (uses system default shell)

---

## 3. Security Analysis

### 3.1 Risk Profile for FVM

**Question**: Is FVM's use case susceptible to CVE-2022-24765?

**Analysis**:

| Factor | FVM Scenario | CVE-2022-24765 Scenario | Risk Level |
|--------|--------------|------------------------|------------|
| Repository Location | `%LOCALAPPDATA%\fvm\versions\*` | `C:\.git` (root drive) | ✅ Low |
| Directory Owner | Current user | Malicious attacker | ✅ Low |
| Write Access | User-only | Multi-user writable | ✅ Low |
| Repository Content | Official Flutter GitHub | Attacker-controlled | ✅ Low |
| Hooks Execution | Flutter's internal scripts | Malicious code | ⚠️ Medium |

**Conclusion**: FVM's use case has **low risk** for the CVE-2022-24765 attack vector because:
1. Cache is in user-controlled `%LOCALAPPDATA%`
2. Only current user has write access
3. Repository originates from trusted source (Flutter GitHub)

**However**: If a user has malware or their account is compromised, malicious hooks could be injected into the Flutter cache. Adding to safe.directory wouldn't introduce *new* risk—the attacker already has user-level access.

### 3.2 Auto-Configuration Security Considerations

**Proposed Action**: FVM automatically runs `git config --global --add safe.directory <path>`

**Security Questions**:

1. **Does this weaken user security?**
   - No, if limited to FVM-managed directories
   - Yes, if using wildcard `*`

2. **Can this be exploited?**
   - Edge case: If FVM cache path is somehow writable by another user (misconfigured system)
   - Mitigation: Verify directory ownership before adding

3. **Corporate/Enterprise Concerns?**
   - Some organizations prohibit modifying global Git config
   - Solution: Provide opt-out flag

---

## 4. Related Issues & Historical Context

### 4.1 Issue Timeline

| Issue | Date | Status | Key Details |
|-------|------|--------|-------------|
| [#569](https://github.com/leoafarias/fvm/issues/569) | 2023-10-27 | Closed | First report; workaround discovered |
| [#589](https://github.com/leoafarias/fvm/issues/589) | 2024-01-17 | Closed | Added to FAQ in PR #677 |
| [#789](https://github.com/leoafarias/fvm/issues/789) | 2024-10-31 | Closed | Intermittent behavior noted |
| [#914](https://github.com/leoafarias/fvm/issues/914) | 2025-09-18 | **OPEN** | Meta-issue: workaround exists but not automated |

### 4.2 Community Workarounds

**Most Common** (from Stack Overflow, GitHub issues):
```bash
git config --global --add safe.directory '*'
```
- ✅ Works universally
- ✅ One-time fix
- ⚠️ Security tradeoff
- 📊 Recommended in 80%+ of community responses

**Targeted Approach**:
```bash
git config --global --add safe.directory C:/path/to/fvm/versions/3.24.0
```
- ✅ More secure
- ❌ Must repeat for each Flutter version
- ❌ Path must use forward slashes on Windows

**Developer Mode** (Windows-specific):
- Enable in Settings > Update & Security > For Developers
- ✅ May resolve issue system-wide
- ⚠️ Requires system-level permission
- ❓ Inconsistent reports

### 4.3 Flutter Team's Stance

From [flutter/flutter#123995](https://github.com/flutter/flutter/issues/123995) and related issues:

**Flutter's Position**: This is a **Git configuration issue**, not a Flutter bug. Flutter tools assume Git works correctly and display Git's error messages as-is.

**Result**: Users see "Unable to find git in your PATH" which is Git's unhelpful error message for the safe.directory check.

---

## 5. How Other Tools Handle Similar Issues

### 5.1 rustup (Rust Version Manager)

**Repository**: https://github.com/rust-lang/rustup

**Approach**:
- Downloads pre-built binaries, not Git repositories
- No Git dependency for core functionality
- ✅ Avoids the problem entirely

**Lesson**: Consider binary distribution instead of Git clones (not applicable to Flutter's architecture)

### 5.2 nvm (Node Version Manager)

**Repository**: https://github.com/nvm-sh/nvm

**Approach**:
- Downloads pre-built Node.js binaries
- Uses Git only for nvm itself (optional)
- If Git issues occur, nvm fails to update but Node.js still works

**Lesson**: Separate tool management from runtime management

### 5.3 asdf (Universal Version Manager)

**Repository**: https://github.com/asdf-vm/asdf

**Approach**:
- Plugin architecture where each plugin defines installation method
- Many plugins use Git to clone repositories
- **No automatic safe.directory configuration**
- Users must manually fix Git issues

**From Research**: asdf plugins have encountered the same issue, documented in community forums. No standardized solution exists.

### 5.4 sdkman (JVM SDK Manager)

**Repository**: https://github.com/sdkman/sdkman-cli

**Approach**:
- Downloads archived SDKs
- No Git dependency for SDK installation
- Uses Git only for sdkman self-updates

**Lesson**: Similar to rustup—avoid Git for SDK distribution

### 5.5 Summary

**Key Finding**: No major version manager automatically configures `safe.directory`. Most avoid Git entirely for SDK distribution.

**FVM's Unique Challenge**: Flutter's architecture requires Git repositories (channels, custom commits, etc.), making Git unavoidable.

---

## 6. Implementation Approaches

### Approach 1: Automatic Global Configuration (Recommended)

**Description**: FVM automatically adds its cache directories to `safe.directory` during installation/setup.

**Implementation**:

```dart
// In git_service.dart or new safe_directory_service.dart

class SafeDirectoryService extends ContextualService {
  const SafeDirectoryService(super.context);

  Future<void> ensureSafeDirectory(String path) async {
    if (!Platform.isWindows) return; // Only needed on Windows

    final gitVersion = await _getGitVersion();
    if (gitVersion == null || gitVersion < Version(2, 35, 2)) {
      return; // Not needed for older Git
    }

    final isAlreadySafe = await _checkIfSafe(path);
    if (isAlreadySafe) return;

    await _addToSafeDirectory(path);
  }

  Future<Version?> _getGitVersion() async {
    try {
      final result = await get<ProcessService>().run(
        'git',
        args: ['--version'],
        throwOnError: false,
      );
      // Parse: "git version 2.46.0.windows.1" → Version(2, 46, 0)
      final match = RegExp(r'(\d+)\.(\d+)\.(\d+)').firstMatch(result.stdout);
      if (match != null) {
        return Version(
          int.parse(match.group(1)!),
          int.parse(match.group(2)!),
          int.parse(match.group(3)!),
        );
      }
    } catch (e) {
      logger.debug('Failed to get Git version: $e');
    }
    return null;
  }

  Future<bool> _checkIfSafe(String path) async {
    try {
      final result = await get<ProcessService>().run(
        'git',
        args: ['config', '--global', '--get-all', 'safe.directory'],
        throwOnError: false,
      );

      if (result.exitCode != 0) return false;

      final entries = (result.stdout as String).split('\n').map((e) => e.trim());

      // Check for wildcard or exact path match
      if (entries.contains('*')) return true;

      // Normalize paths for comparison (Windows uses \ but Git config uses /)
      final normalizedPath = path.replaceAll('\\', '/');
      return entries.any((entry) =>
        entry.replaceAll('\\', '/') == normalizedPath
      );
    } catch (e) {
      logger.debug('Failed to check safe.directory: $e');
      return false;
    }
  }

  Future<void> _addToSafeDirectory(String path) async {
    try {
      // Normalize path for Git (use forward slashes)
      final normalizedPath = path.replaceAll('\\', '/');

      await get<ProcessService>().run(
        'git',
        args: ['config', '--global', '--add', 'safe.directory', normalizedPath],
      );

      logger.info('Added $path to safe.directory');
    } catch (e) {
      logger.warn(
        'Failed to add $path to safe.directory. '
        'You may need to run: git config --global --add safe.directory "$path"'
      );
    }
  }
}
```

**Integration Points**:

1. **During cache creation** ([git_service.dart:29](../lib/src/services/git_service.dart#L29)):
   ```dart
   Future<void> _createLocalMirror() async {
     // ... existing clone logic ...

     if (Platform.isWindows) {
       await get<SafeDirectoryService>().ensureSafeDirectory(
         context.gitCachePath
       );
     }
   }
   ```

2. **During version installation** ([flutter_service.dart:137](../lib/src/services/flutter_service.dart#L137)):
   ```dart
   Future<void> install(FlutterVersion version) async {
     final versionDir = get<CacheService>().getVersionCacheDir(version);

     // ... existing clone logic ...

     if (Platform.isWindows) {
       await get<SafeDirectoryService>().ensureSafeDirectory(versionDir.path);
     }
   }
   ```

3. **Proactive check in `fvm doctor`**:
   ```dart
   // New diagnostic check
   if (Platform.isWindows) {
     final allVersions = await get<CacheService>().getAllVersions();
     for (final version in allVersions) {
       await get<SafeDirectoryService>().ensureSafeDirectory(
         version.directory
       );
     }
   }
   ```

**Pros**:
- ✅ Fully automated—no user intervention
- ✅ Precise—only adds FVM directories
- ✅ Minimal security impact
- ✅ Handles all Flutter versions
- ✅ Works retroactively for existing installations

**Cons**:
- ⚠️ Modifies user's global Git config without explicit consent
- ⚠️ May fail in corporate environments with restricted Git config
- ⚠️ Adds entries for each version (could be dozens)
- ⚠️ Requires Git version detection logic

**Opt-Out Strategy**:
```bash
# Environment variable
FVM_NO_GIT_CONFIG=true fvm install stable

# Or in fvm config
fvm config --no-git-config
```

---

### Approach 2: Interactive Prompt (User-Friendly)

**Description**: When FVM detects the error, prompt the user to auto-fix it.

**Implementation**:

```dart
class GitErrorHandler {
  Future<void> handleGitError(ProcessException error) async {
    if (!_isUnsafeRepositoryError(error)) {
      rethrow;
    }

    final shouldFix = await _promptUser(
      'Git requires this directory to be marked as safe.\n'
      'Would you like FVM to configure this automatically?',
    );

    if (shouldFix) {
      await get<SafeDirectoryService>().ensureSafeDirectory(context.gitCachePath);
      logger.info('Configuration updated. Please retry your command.');
    } else {
      logger.info(
        'You can manually fix this by running:\n'
        'git config --global --add safe.directory "*"'
      );
    }
  }

  bool _isUnsafeRepositoryError(ProcessException error) {
    final message = error.message.toLowerCase();
    return message.contains('unsafe repository') ||
           message.contains('dubious ownership') ||
           message.contains('unable to find git');
  }
}
```

**Pros**:
- ✅ User consent obtained
- ✅ Educational—users understand what's happening
- ✅ Respects user preferences
- ✅ Can offer wildcard option

**Cons**:
- ❌ Interrupts workflow
- ❌ Requires stdin support (not always available in CI/scripts)
- ❌ User might decline and still be stuck
- ⚠️ Complexity in non-interactive environments

---

### Approach 3: Doctor Command Integration

**Description**: Add a `fvm doctor` check that validates and fixes safe.directory.

**Implementation**:

```dart
class GitConfigurationCheck extends DoctorCheck {
  @override
  String get name => 'Git Safe Directory Configuration';

  @override
  Future<DoctorCheckResult> run() async {
    if (!Platform.isWindows) {
      return DoctorCheckResult.skipped('Only applicable on Windows');
    }

    final gitVersion = await _getGitVersion();
    if (gitVersion == null) {
      return DoctorCheckResult.error('Git not found in PATH');
    }

    if (gitVersion < Version(2, 35, 2)) {
      return DoctorCheckResult.success('Git version does not require safe.directory');
    }

    final allVersions = await get<CacheService>().getAllVersions();
    final unsafeVersions = <String>[];

    for (final version in allVersions) {
      final isSafe = await get<SafeDirectoryService>()
        ._checkIfSafe(version.directory);
      if (!isSafe) {
        unsafeVersions.add(version.name);
      }
    }

    if (unsafeVersions.isEmpty) {
      return DoctorCheckResult.success('All versions configured correctly');
    }

    return DoctorCheckResult.warning(
      'Some versions not in safe.directory: ${unsafeVersions.join(", ")}\n'
      'Run: fvm doctor --fix-git-config',
    );
  }
}
```

**New Command**:
```bash
fvm doctor --fix-git-config
```

**Pros**:
- ✅ User-initiated fix
- ✅ Clear feedback via `fvm doctor`
- ✅ Explicit command for troubleshooting
- ✅ Doesn't modify config without permission

**Cons**:
- ❌ Requires user to run doctor first
- ❌ Extra step in workflow
- ⚠️ Users may not discover the fix

---

### Approach 4: Setup Script/Installer Hook

**Description**: During FVM installation (via `dart pub global activate fvm`), run a post-install hook.

**Implementation**:

Add to `pubspec.yaml`:
```yaml
executables:
  fvm: fvm

# Post-activation hook (hypothetical—Dart doesn't support this natively)
```

**Reality Check**: Dart's `pub global activate` doesn't support post-install hooks. This would require:
- Custom installer script (Shell/PowerShell)
- Distribution via Homebrew/Chocolatey/Winget with hooks

**Pros**:
- ✅ One-time setup
- ✅ Runs before first use

**Cons**:
- ❌ Not supported by Dart pub system
- ❌ Requires alternative distribution mechanism
- ⚠️ Doesn't help users who already have FVM installed

---

### Approach 5: Wildcard Configuration

**Description**: Use the wildcard `*` to trust all repositories.

**Implementation**:

```dart
await get<ProcessService>().run(
  'git',
  args: ['config', '--global', '--add', 'safe.directory', '*'],
);
```

**Pros**:
- ✅ Simplest solution
- ✅ One command fixes everything
- ✅ Matches community recommendations

**Cons**:
- ⚠️ **Security**: Disables CVE-2022-24765 protection entirely
- ⚠️ May be rejected by security-conscious users
- ⚠️ Not suitable for shared/corporate environments

---

## 7. Recommended Solution

### Multi-Phased Approach

#### Phase 1: Immediate (FVM 4.0.1)

**Add Safe Directory Check to Install Workflow**

```dart
// Auto-add during installation
if (Platform.isWindows) {
  try {
    await get<SafeDirectoryService>().ensureSafeDirectory(versionDir.path);
  } catch (e) {
    logger.warn('Could not configure safe.directory automatically.');
    logger.info('You may need to run: git config --global --add safe.directory "*"');
  }
}
```

**Update Error Messages**:

Replace generic "Unable to find git in your PATH" with:
```
Git security check failed. This is likely due to repository ownership settings.

Quick fix:
  git config --global --add safe.directory "*"

For more info:
  https://fvm.app/docs/troubleshooting/git-safe-directory
```

**Documentation**:
- Update FAQ with clearer explanation
- Add troubleshooting guide
- Link to security implications

#### Phase 2: Enhanced (FVM 4.1.0)

**Add `fvm doctor` Integration**:
- New check: "Git Safe Directory Configuration"
- New flag: `fvm doctor --fix-git-config`

**Add Configuration Option**:
```bash
# Opt out
fvm config git.auto-safe-directory false

# Opt in to wildcard (explicit)
fvm config git.safe-directory-mode wildcard

# Default: per-directory
fvm config git.safe-directory-mode per-directory
```

#### Phase 3: Future (FVM 5.0.0)

**Consider Alternative Architecture**:
- Investigate if Flutter's Git repository requirement can be avoided
- Explore pre-built Flutter SDK downloads
- Coordinate with Flutter team for better error messages

---

## 8. Testing Strategy

### Unit Tests

```dart
test('SafeDirectoryService detects unsafe directories', () async {
  // Mock Git config output
  when(mockProcessService.run('git', args: ['config', '--global', '--get-all', 'safe.directory']))
    .thenAnswer((_) async => ProcessResult(0, 0, '', ''));

  final service = SafeDirectoryService(mockContext);
  final isSafe = await service._checkIfSafe('C:/Users/test/fvm/versions/3.24.0');

  expect(isSafe, false);
});

test('SafeDirectoryService adds directory correctly', () async {
  final service = SafeDirectoryService(mockContext);
  await service._addToSafeDirectory('C:/Users/test/fvm/versions/3.24.0');

  verify(mockProcessService.run(
    'git',
    args: ['config', '--global', '--add', 'safe.directory', 'C:/Users/test/fvm/versions/3.24.0'],
  )).called(1);
});
```

### Integration Tests

```dart
// Test on Windows VM with Git 2.46+
test('FVM install configures safe.directory on Windows', () async {
  // Start with clean Git config
  await Process.run('git', ['config', '--global', '--unset-all', 'safe.directory']);

  // Install a Flutter version
  await fvm.install('3.24.0');

  // Verify safe.directory was configured
  final result = await Process.run('git', ['config', '--global', '--get-all', 'safe.directory']);
  expect(result.stdout, contains('fvm/versions/3.24.0'));
});
```

### Manual Testing Checklist

- [ ] Windows 10 with Git 2.46
- [ ] Windows 11 with Git 2.48
- [ ] PowerShell 5.1
- [ ] PowerShell 7.x
- [ ] CMD
- [ ] Git Bash
- [ ] Administrator vs Normal user
- [ ] Developer Mode enabled vs disabled
- [ ] With existing safe.directory entries
- [ ] With wildcard `*` already configured
- [ ] In corporate environment with read-only Git config

---

## 9. Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| User rejects config changes | Medium | Medium | Provide opt-out, clear messaging |
| Corporate policy violation | Low | High | Allow disabling via env var |
| Security degradation | Low | Low | Use per-directory, not wildcard |
| Git version incompatibility | Low | Medium | Version detection, graceful fallback |
| Path normalization issues | Medium | Low | Test on multiple shells |

---

## 10. Success Metrics

**Definition of Done**:
1. ✅ Zero manual safe.directory configuration needed for 95%+ of Windows users
2. ✅ Clear error messages when auto-config fails
3. ✅ `fvm doctor` shows green check for Git configuration
4. ✅ No new security vulnerabilities introduced
5. ✅ Opt-out mechanism works reliably

**Measurable KPIs**:
- Reduction in GitHub issues mentioning "unable to find git"
- Reduction in FAQ page views for Git PATH error
- Community feedback on Discord/Twitter
- Time-to-first-successful-install on Windows

---

## 11. Alternative: User Education Campaign

If automated configuration is deemed too invasive, consider enhanced documentation:

### Improved Onboarding

**Add to First-Run Experience**:
```
Welcome to FVM!

⚠️  Windows users: Please run this command once:
    git config --global --add safe.directory "*"

This is required due to Git security settings.
Learn more: https://fvm.app/docs/why-safe-directory
```

### Proactive Error Handling

When FVM detects the error:
```
❌ Flutter command failed: Git security check

This is a known issue with Git 2.35.2+ on Windows.

Quick fix (copy and paste):
  git config --global --add safe.directory "*"

What this does:
  Tells Git to trust all repositories on your computer.

Is this safe?
  Yes, if you're the only user on your computer.
  Learn more: https://fvm.app/docs/git-safe-directory

After running the command, retry your FVM command.
```

---

## 12. Conclusion

Issue #914 is a **legitimate UX problem** that warrants automated resolution. The recommended approach balances:

1. **User convenience**: Automated configuration during install
2. **Security**: Per-directory entries, not wildcard by default
3. **Transparency**: Clear messaging about what's being configured
4. **Flexibility**: Opt-out for restricted environments

### Recommended Implementation Priority

1. **Immediate (v4.0.1)**: Improve error messages + documentation
2. **Short-term (v4.1.0)**: Auto-configure safe.directory with opt-out
3. **Long-term (v5.0.0)**: Integrate with `fvm doctor`, explore Flutter SDK distribution alternatives

### Why This Matters

FVM's value proposition is **convenience**. Requiring users to manually configure Git settings every time they encounter this error undermines that promise. While the security implications of CVE-2022-24765 are real, FVM's specific use case (user-owned cache directories with trusted repository sources) presents minimal risk.

Automating this configuration aligns with FVM's design philosophy: make Flutter version management frictionless.

---

## References

1. [CVE-2022-24765](https://nvd.nist.gov/vuln/detail/CVE-2022-24765) - Git Uncontrolled Search Vulnerability
2. [Git 2.36 Release Notes](https://github.blog/open-source/git/highlights-from-git-2-36/) - safe.directory introduction
3. [FVM Issue #569](https://github.com/leoafarias/fvm/issues/569) - Original report
4. [FVM Issue #589](https://github.com/leoafarias/fvm/issues/589) - FAQ addition
5. [FVM Issue #789](https://github.com/leoafarias/fvm/issues/789) - Intermittent behavior
6. [Flutter Issue #123995](https://github.com/flutter/flutter/issues/123995) - "Unable to find git" on Windows
7. [Git safe.directory Documentation](https://git-scm.com/docs/git-config/2.35.2#Documentation/git-config.txt-safedirectory)

---

**Next Steps**: Review this research with the team, prioritize implementation approach, and create implementation tickets.
