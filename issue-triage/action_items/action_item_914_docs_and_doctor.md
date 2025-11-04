# Action Item: Issue #914 – Documentation & Doctor Check for Git Safe Directory

> ⚠️ **IMPORTANT**: See [action_item_914_docs_corrections.md](./action_item_914_docs_corrections.md) for verified paths and structure corrections after checking the actual FVM documentation setup.

## Objective
Improve discoverability and diagnosis of the Windows Git "unable to find git in your PATH" issue through enhanced documentation and a `fvm doctor` check.

## Background
Windows users with Git ≥2.35.2 frequently encounter "Unable to find git in your PATH" despite Git being installed. This is caused by Git's CVE-2022-24765 security fix that requires repositories to be marked as "safe". The workaround is documented in FAQ but buried and hard to discover.

## Goals
1. Create a dedicated, searchable troubleshooting page for this specific issue
2. Add a `fvm doctor` check that detects this condition and provides actionable guidance
3. Update existing documentation to cross-reference the new page
4. Improve SEO so users searching for the error find FVM's solution quickly

---

## Part 1: Documentation Improvements

### 1.1 Create New Troubleshooting Page

**Directory to create**: `docs/pages/documentation/troubleshooting/`
**File**: `docs/pages/documentation/troubleshooting/git-safe-directory-windows.md`

**Note**: Also need to create `_meta.json` and `index.md` for the troubleshooting section. See corrections doc for details.

**Content Structure**:
```markdown
---
id: git-safe-directory-windows
title: "Git Safe Directory Error on Windows"
description: "Fix 'Unable to find git in your PATH' error on Windows when using FVM"
---

# Git Safe Directory Error on Windows

## Symptoms

You're running FVM commands on Windows and see:
```
Error: Unable to find git in your PATH.
```

But you know Git is installed because `git --version` works fine in your terminal.

## Root Cause

This is not actually a PATH issue. Git ≥2.35.2 (released April 2022) introduced a security check that prevents operations in repositories owned by different users. Due to Windows' permission model, Git sometimes considers FVM's Flutter cache directories as "unsafe."

**Technical Details**: This addresses [CVE-2022-24765](https://nvd.nist.gov/vuln/detail/CVE-2022-24765), a security vulnerability where malicious repositories could execute code.

## Quick Fix (Recommended)

Run this command once in your terminal:

```bash
git config --global --add safe.directory "*"
```

Then restart your terminal and IDE (VS Code, Android Studio, etc.).

### What This Does
Tells Git to trust all repositories on your computer. This is safe for personal development machines where you're the only user.

### Alternative: Trust Only FVM Directories

If you prefer to be more specific:

```bash
# Trust FVM's cache
git config --global --add safe.directory "C:/Users/YourUsername/AppData/Local/fvm/versions"

# Or for a specific Flutter version
git config --global --add safe.directory "C:/Users/YourUsername/AppData/Local/fvm/versions/3.24.0"
```

**Note**: Replace `YourUsername` with your actual Windows username. Use forward slashes (`/`) not backslashes (`\`).

## Verify the Fix

After applying the fix:

```bash
# Check your configuration
git config --global --get-all safe.directory

# Run FVM doctor
fvm doctor

# Try your original command again
fvm flutter doctor
```

## Why This Happens

### The Security Update
In April 2022, Git released version 2.35.2 with a security fix for CVE-2022-24765. The vulnerability allowed attackers on multi-user systems to execute malicious code by placing a `.git` directory in a shared location (e.g., `C:\.git`).

Git's fix: Check if the repository owner matches the current user before executing any Git commands.

### Why FVM is Affected
1. FVM clones Flutter repositories to `%LOCALAPPDATA%\fvm\versions\`
2. Windows' complex permission model (SIDs, UAC elevation) can cause Git to see ownership mismatches
3. Flutter's tools internally use Git commands, which then fail
4. Git's error message is misleading—it says "unable to find git" when it really means "refusing to use git here"

### When It Happens
- ✅ After installing/updating Git to 2.35.2+
- ✅ On fresh Windows installations
- ✅ After changing Windows user accounts
- ✅ In some PowerShell 7+ environments
- ✅ When using non-administrator accounts (sometimes)

## Other Solutions

### Enable Windows Developer Mode
Some users report this helps:
1. Open Windows Settings
2. Go to "Update & Security" → "For developers"
3. Enable "Developer Mode"
4. Restart your terminal

This may not work for everyone and requires system-level permissions.

### Run as Administrator
Running your terminal as Administrator sometimes works, but this is **not recommended** as a permanent solution due to security implications.

## Still Having Issues?

If the above solutions don't work:

1. **Check your Git version**: `git --version` (should be 2.35.2 or higher)
2. **Verify Git works**: `git status` in any Git repository
3. **Check FVM cache location**: `fvm config` (look for `cachePath`)
4. **Run FVM doctor**: `fvm doctor --verbose`
5. **Report issue**: If none of this helps, please [open an issue](https://github.com/leoafarias/fvm/issues/new) with:
   - Windows version
   - Git version
   - PowerShell/CMD version
   - Output of `fvm doctor --verbose`

## Related Issues
- [#569](https://github.com/leoafarias/fvm/issues/569) - Original report (2023)
- [#589](https://github.com/leoafarias/fvm/issues/589) - FAQ addition
- [#789](https://github.com/leoafarias/fvm/issues/789) - Intermittent behavior
- [#914](https://github.com/leoafarias/fvm/issues/914) - Meta-issue

## References
- [Git 2.36 Release Notes](https://github.blog/open-source/git/highlights-from-git-2-36/)
- [CVE-2022-24765 Details](https://nvd.nist.gov/vuln/detail/CVE-2022-24765)
- [Git safe.directory Documentation](https://git-scm.com/docs/git-config#Documentation/git-config.txt-safedirectory)
```

### 1.2 Update Existing FAQ

**File**: `docs/pages/documentation/getting-started/faq.md`

**Changes** (around line 111-132):

```markdown
## Git not found after install on Windows

Some users may be greeted by this error after installing FVM in a project.

```bash
Error: Unable to find git in your PATH.
```

**This is not actually a PATH issue.** Git is installed, but it's refusing to operate due to security settings.

**Quick fix**: Run this command once:

```bash
git config --global --add safe.directory '*'
```

Then restart your terminal and IDE.

**For detailed information and alternative solutions**, see our comprehensive guide:
👉 [Git Safe Directory Error on Windows](/documentation/troubleshooting/git-safe-directory-windows)

<details>
<summary>Why does this happen?</summary>

This happens because of a security update in Git 2.35.2+ (CVE-2022-24765) where Git now checks for ownership of the folder. On Windows, Git sometimes considers FVM's cache directories as "unsafe" due to the complex permission model.

The command above tells Git to trust all repositories on your computer, which is safe for personal development machines.
</details>
```

### 1.3 Create Troubleshooting Index

**File**: `docs/pages/documentation/troubleshooting/index.md`

```markdown
---
id: troubleshooting
title: "Troubleshooting"
---

# Troubleshooting Guide

## Common Issues

### Windows

- **[Git Safe Directory Error](/documentation/troubleshooting/git-safe-directory-windows)** - "Unable to find git in your PATH" on Windows
- [Flutter Commands Fail on Windows](#) - Permission issues
- [Symlinks Not Working](#) - Developer mode required

### macOS

- [Permission Denied Errors](#)
- [Rosetta Issues on Apple Silicon](#)

### Linux

- [PATH Not Persisting](#)
- [Snap Installation Issues](#)

### All Platforms

- [Flutter Version Not Switching](#)
- [Cache Issues](#)
- [Network/Proxy Problems](#)

## Need More Help?

- Check our [FAQ](/documentation/getting-started/faq)
- Search [existing issues](https://github.com/leoafarias/fvm/issues)
- Join our [Discord community](#)
- [Open a new issue](https://github.com/leoafarias/fvm/issues/new)
```

### 1.4 Create Navigation Config

**File**: `docs/pages/documentation/troubleshooting/_meta.json`

```json
{
  "index": {
    "title": "Troubleshooting"
  },
  "git-safe-directory-windows": {
    "title": "Git Safe Directory (Windows)"
  }
}
```

### 1.5 Update Main Navigation

**File**: `docs/pages/documentation/_meta.json`

Add troubleshooting section after "getting-started" (see corrections doc for full context):
```json
  "-- Troubleshooting": {
    "type": "separator",
    "title": "Troubleshooting"
  },
  "troubleshooting": {
    "title": "Troubleshooting",
    "display": "children"
  }
```

---

## Part 2: FVM Doctor Check

### 2.1 Create GitConfigCheck

**File**: `lib/src/commands/doctor/checks/git_config_check.dart`

```dart
import 'dart:io';

import 'package:io/io.dart';

import '../../../services/process_service.dart';
import '../../../utils/logger_service.dart';
import '../../base_command.dart';
import 'doctor_check.dart';

/// Checks Git configuration for safe.directory issues on Windows
class GitConfigCheck extends DoctorCheck {
  GitConfigCheck(super.context);

  @override
  String get name => 'Git Configuration';

  @override
  Future<CheckResult> run() async {
    // Only applicable on Windows
    if (!Platform.isWindows) {
      return CheckResult.skipped('Only applicable on Windows');
    }

    try {
      // Check if Git is available
      final gitVersion = await _getGitVersion();
      if (gitVersion == null) {
        return CheckResult.warning(
          'Git not found in PATH',
          'Install Git from https://git-scm.com/downloads',
        );
      }

      // Only check for Git 2.35.2+
      if (!_needsSafeDirectoryCheck(gitVersion)) {
        return CheckResult.success(
          'Git version $gitVersion (safe.directory not required)',
        );
      }

      // Check if safe.directory is configured
      final hasSafeDirectory = await _checkSafeDirectoryConfig();

      if (hasSafeDirectory) {
        return CheckResult.success(
          'Git safe.directory configured',
        );
      }

      // Not configured - return info with fix
      return CheckResult.info(
        'Git safe.directory not configured',
        'Windows users with Git 2.35.2+ may encounter "Unable to find git in your PATH" errors.\n\n'
        'Quick fix:\n'
        '  git config --global --add safe.directory "*"\n\n'
        'Learn more: https://fvm.app/documentation/troubleshooting/git-safe-directory-windows',
      );
    } catch (e) {
      logger.debug('Error checking Git configuration: $e');
      return CheckResult.warning(
        'Could not check Git configuration',
        e.toString(),
      );
    }
  }

  Future<String?> _getGitVersion() async {
    try {
      final result = await get<ProcessService>().run(
        'git',
        args: ['--version'],
        throwOnError: false,
      );

      if (result.exitCode != 0) return null;

      // Parse "git version 2.46.0.windows.1" → "2.46.0"
      final match = RegExp(r'git version (\d+\.\d+\.\d+)')
          .firstMatch(result.stdout.toString());

      return match?.group(1);
    } catch (e) {
      return null;
    }
  }

  bool _needsSafeDirectoryCheck(String version) {
    try {
      final parts = version.split('.').map(int.parse).toList();
      if (parts.length < 3) return false;

      final major = parts[0];
      final minor = parts[1];
      final patch = parts[2];

      // Check if >= 2.35.2
      if (major > 2) return true;
      if (major < 2) return false;
      if (minor > 35) return true;
      if (minor < 35) return false;
      return patch >= 2;
    } catch (e) {
      return false;
    }
  }

  Future<bool> _checkSafeDirectoryConfig() async {
    try {
      final result = await get<ProcessService>().run(
        'git',
        args: ['config', '--global', '--get-all', 'safe.directory'],
        throwOnError: false,
      );

      // Exit code 1 means no values found
      if (result.exitCode == 1) return false;

      // If exit code 0, check if output contains entries
      final output = result.stdout.toString().trim();

      // Check for wildcard or any entries
      return output.isNotEmpty;
    } catch (e) {
      return false;
    }
  }
}
```

### 2.2 Register Check in Doctor Command

**File**: `lib/src/commands/doctor_command.dart`

Find where checks are registered (likely in a list of checks) and add:

```dart
import 'doctor/checks/git_config_check.dart';

// In the checks list or initialization
final checks = [
  // ... existing checks ...
  GitConfigCheck(context),
  // ... more checks ...
];
```

### 2.3 Update CheckResult Class (if needed)

**File**: `lib/src/commands/doctor/doctor_check.dart` or similar

Ensure `CheckResult` has an `info` level for non-critical suggestions:

```dart
enum CheckStatus {
  success,
  warning,
  error,
  info,     // Add if not exists - for informational messages
  skipped,
}

class CheckResult {
  final CheckStatus status;
  final String message;
  final String? details;

  CheckResult(this.status, this.message, [this.details]);

  factory CheckResult.success(String message, [String? details]) =>
      CheckResult(CheckStatus.success, message, details);

  factory CheckResult.warning(String message, [String? details]) =>
      CheckResult(CheckStatus.warning, message, details);

  factory CheckResult.error(String message, [String? details]) =>
      CheckResult(CheckStatus.error, message, details);

  factory CheckResult.info(String message, [String? details]) =>
      CheckResult(CheckStatus.info, message, details);

  factory CheckResult.skipped(String message) =>
      CheckResult(CheckStatus.skipped, message);
}
```

---

## Part 3: Testing

### 3.1 Manual Testing Checklist

- [ ] Windows 10 with Git 2.46+
  - [ ] Without safe.directory configured
  - [ ] With safe.directory wildcard `*`
  - [ ] With specific directory entries
- [ ] Windows 11 with Git 2.48+
- [ ] macOS (should skip check)
- [ ] Linux (should skip check)
- [ ] Git < 2.35.2 (should show success)
- [ ] Git not in PATH (should show warning)

### 3.2 Test Doctor Output

**Expected output when not configured**:
```
FVM Doctor
✓ FVM Version: 4.0.0
✓ Flutter: 3 versions installed
ℹ Git Configuration
  Git safe.directory not configured

  Windows users with Git 2.35.2+ may encounter "Unable to find git in your PATH" errors.

  Quick fix:
    git config --global --add safe.directory "*"

  Learn more: https://fvm.app/documentation/troubleshooting/git-safe-directory-windows
```

**Expected output when configured**:
```
✓ Git Configuration
  Git safe.directory configured
```

### 3.3 Unit Tests

**File**: `test/src/commands/doctor/checks/git_config_check_test.dart`

```dart
import 'package:fvm/src/commands/doctor/checks/git_config_check.dart';
import 'package:fvm/src/commands/doctor/checks/doctor_check.dart';
import 'package:test/test.dart';

void main() {
  group('GitConfigCheck', () {
    test('skips check on non-Windows platforms', () async {
      // Test would need platform mocking
    });

    test('detects Git version correctly', () {
      final check = GitConfigCheck(mockContext);
      expect(check._needsSafeDirectoryCheck('2.46.0'), true);
      expect(check._needsSafeDirectoryCheck('2.35.2'), true);
      expect(check._needsSafeDirectoryCheck('2.35.1'), false);
      expect(check._needsSafeDirectoryCheck('2.34.0'), false);
    });

    test('returns info when safe.directory not configured', () async {
      // Mock Git version and config checks
      // Verify CheckResult.info is returned
    });

    test('returns success when safe.directory is configured', () async {
      // Mock Git config with safe.directory entries
      // Verify CheckResult.success is returned
    });
  });
}
```

---

## Part 4: SEO & Discoverability

### 4.1 Meta Tags for New Page

**Note**: Nextra automatically generates meta tags from the frontmatter. The `title` and `description` fields in the frontmatter will be used for:
- `<title>` tag
- `<meta name="description">` tag
- Open Graph tags
- Twitter Card tags

No manual HTML meta tags needed. Just ensure the frontmatter has good SEO-friendly content.

### 4.2 Common Search Queries to Target

The page should be optimized for these searches:
- "fvm unable to find git in your path"
- "flutter unable to find git windows"
- "git safe.directory fvm"
- "fvm git error windows"
- "CVE-2022-24765 flutter"

### 4.3 Internal Linking

Update these pages to link to the new troubleshooting page:
- Installation guide
- Getting started
- Windows-specific setup guide (if exists)
- FAQ

---

## Part 5: Release Plan

### Version 4.0.1 (Hotfix)
- ✅ Add doctor check
- ✅ Update FAQ with prominent link
- ✅ Create troubleshooting page

### Documentation Site Update
- ✅ Deploy new pages
- ✅ Update navigation
- ✅ Add internal links
- ✅ Test search functionality

### Communication
- ✅ Tweet about the new guide
- ✅ Update Discord pins with link
- ✅ Comment on related GitHub issues (#569, #589, #789, #914) with link

---

## Success Metrics

### Short-term (1 month)
- [ ] New troubleshooting page in top 5 Google results for "fvm unable to find git"
- [ ] Reduced duplicate issues on GitHub (currently ~4 major issues on this topic)
- [ ] FAQ section view time increases (users finding answer faster)

### Long-term (3 months)
- [ ] Doctor check helps 80%+ of users identify issue before posting
- [ ] Community feedback: "documentation helped me solve this quickly"
- [ ] Issue #914 can be closed with "documented and detected"

---

## Files to Create/Modify

### New Files (5 files)
- [ ] `docs/pages/documentation/troubleshooting/_meta.json` - Navigation config for troubleshooting section
- [ ] `docs/pages/documentation/troubleshooting/index.md` - Troubleshooting overview page
- [ ] `docs/pages/documentation/troubleshooting/git-safe-directory-windows.md` - Main guide page
- [ ] `lib/src/commands/doctor/checks/git_config_check.dart` - Doctor check implementation
- [ ] `test/src/commands/doctor/checks/git_config_check_test.dart` - Unit tests

### Modified Files (3-4 files)
- [ ] `docs/pages/documentation/_meta.json` - Add troubleshooting section to main navigation
- [ ] `docs/pages/documentation/getting-started/faq.md` - Update lines 111-132 with link to new guide
- [ ] `lib/src/commands/doctor_command.dart` - Register new Git config check
- [ ] Possibly `lib/src/commands/doctor/doctor_check.dart` (if adding `info` level for CheckResult)

---

## Completion Criteria

- [x] Deep research completed (see `issue-914-deep-research.md`)
- [ ] Documentation pages created and reviewed
- [ ] Doctor check implemented and tested
- [ ] Unit tests pass
- [ ] Manual testing on Windows complete
- [ ] SEO verification (meta tags, keywords)
- [ ] Internal linking verified
- [ ] Release notes drafted

---

## Next Steps

1. **Review this action plan** with team
2. **Create implementation PR** with:
   - Documentation changes
   - Doctor check code
   - Tests
3. **Deploy documentation** to staging for review
4. **Test doctor check** on Windows VM
5. **Merge and release** as v4.0.1
6. **Update all related issues** with link to new documentation

---

## References
- Research document: `issue-triage/artifacts/issue-914-deep-research.md`
- Original triage: `issue-triage/artifacts/issue-914.md`
- GitHub issue: https://github.com/leoafarias/fvm/issues/914
- Related issues: #569, #589, #789
