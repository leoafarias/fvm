---
id: git-safe-directory-windows
title: "Git Safe Directory Error on Windows"
description: "Fix 'Unable to find git in your PATH' errors on Windows when Git 2.35.2+ blocks unsafe repositories"
---

# Git Safe Directory Error on Windows

## Symptoms

You run FVM commands on Windows and see:

```
Error: Unable to find git in your PATH.
```

`git --version` still works, so PATH is fine—but Flutter commands that rely on Git fail.

## Root Cause

Git 2.35.2 (April 2022) introduced a security fix for [CVE-2022-24765](https://nvd.nist.gov/vuln/detail/CVE-2022-24765). It refuses to run inside repositories owned by a different Windows user. Because FVM stores Flutter SDKs under `%LOCALAPPDATA%\fvm\versions`, Windows access control lists sometimes make Git think the directory belongs to another user. Git then halts with the misleading "unable to find git" error.

## Quick Fix (Recommended)

Tell Git to trust every repository on your development machine:

```bash
git config --global --add safe.directory "*"
```

Restart your terminal and IDE (VS Code, Android Studio, etc.) after running the command.

### What This Does

Git's `safe.directory` list defines which paths bypass the ownership check. Using `*` is a pragmatic fix for single-user development machines because it restores pre-2.35.2 behavior.

## Alternative: Trust Only FVM Directories

If you want more control, add the directories that FVM manages:

```bash
# Trust the entire FVM cache
git config --global --add safe.directory "C:/Users/YourUsername/AppData/Local/fvm/versions"

# Or trust a single Flutter version
git config --global --add safe.directory "C:/Users/YourUsername/AppData/Local/fvm/versions/3.24.0"
```

Replace `YourUsername` with your Windows account name. Keep forward slashes (`/`) in the path.

## Verify the Fix

```bash
# List all trusted directories
git config --global --get-all safe.directory

# Double-check your setup
fvm doctor

# Retry the original command
fvm flutter doctor
```

## Why This Happens

### The Security Update
- Git 2.35.2+ blocks repositories whose file owner does not match the current user.
- The change prevents malicious repositories from hijacking shared directories.

### Why FVM Is Affected
1. FVM installs Flutter SDKs under `%LOCALAPPDATA%\fvm\versions`.
2. Windows assigns ownership metadata that may not match your current SID (especially after renames, domain joins, or running shells as Administrator).
3. Flutter tools call Git internally; when Git refuses to run, Flutter reports "Unable to find git in your PATH".

### When It Happens
- After installing/upgrading to Git 2.35.2 or newer
- On fresh Windows setups where no safe directories are configured
- After changing Windows usernames or using multiple user profiles
- When running PowerShell 7+ or terminals elevated as Administrator
- In CI environments that download artifacts created by another user account

## Other Solutions

### Enable Windows Developer Mode
Some users report that enabling Developer Mode (`Settings → System → For developers`) alleviates ownership mismatches. You still need to restart your terminal.

### Run the Terminal as Administrator (Temporary)
Launching PowerShell or CMD as Administrator can bypass the ownership check, but it is inconvenient and not recommended long term.

## Related Resources

- [Git CVE-2022-24765 announcement](https://github.blog/2022-04-18-git-security-vulnerability-announced/)
- [Git safe.directory documentation](https://git-scm.com/docs/git-config#Documentation/git-config.txt-safedirectory)
- [FVM FAQ](/documentation/getting-started/faq)
