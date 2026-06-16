# Issue #914: [BUG] Error: Unable to find git in your PATH.

## Metadata
- **Reporter**: @kuguma
- **Created**: 2025-09-18
- **Reported Version**: FVM on Windows (Git 2.35+)
- **Issue Type**: bug
- **URL**: https://github.com/leoafarias/fvm/issues/914

## Problem Summary
On Windows, FVM users repeatedly hit `Error: Unable to find git in your PATH.` when running FVM commands despite Git being installed. The root cause is Git’s “safe.directory” security change: because FVM’s cloned Flutter repositories reside under `%USERPROFILE%\AppData\Local\fvm\cache.git`, Git refuses to operate until the directory is marked safe. Users must manually run `git config --global --add safe.directory …`, which contradicts FVM’s goal of streamlining setup.

## Version Context
- Reported against: FVM 3.x (persists through v4.0.0)
- Current version: v4.0.0
- Version-specific: no — Windows + modern Git remain affected

## Validation Steps
1. Reviewed `docs/pages/documentation/getting-started/faq.md`, which now links to a dedicated troubleshooting guide and documents the manual workaround (`git config --global --add safe.directory "*"`)
2. Verified `docs/pages/documentation/troubleshooting/git-safe-directory-windows.md`, `_meta.json`, and `overview.md` now exist after the latest `main` merge.
3. Audited `lib/src/commands/doctor_command.dart` and found no diagnostic that runs Git against the FVM cache or detects `safe.directory` failures.
4. Audited the error handling path and found no targeted interception for Flutter/Git's misleading "Unable to find git in your PATH" message.
5. Checked past issues (#789/#589/#569) referenced in the reporter's comment to verify this has been a long-standing Windows pain point.

## Evidence
```
docs/pages/documentation/getting-started/faq.md:112 links to the Git Safe Directory troubleshooting guide.
docs/pages/documentation/troubleshooting/git-safe-directory-windows.md documents symptoms, root cause, and manual fixes.
lib/src/commands/doctor_command.dart:252-265 prints project/IDE/environment details only; no Git safe-directory validation.
lib/src/workflows/ensure_cache.workflow.dart:101-112 only checks `git --version`.
```

## Current Status in v4.0.0
- [x] Still reproducible (requires manual git config)
- [ ] Already fixed
- [ ] Not applicable to v4.0.0
- [ ] Needs more information

## Troubleshooting/Implementation Plan

### Root Cause Analysis
Git 2.36+ flags FVM’s cache directory as “unsafe” because Flutter’s repository is cloned under a directory owned by a different SID (or outside the user’s profile). Without adding it to `safe.directory`, Git refuses to run and Flutter prints “Unable to find git in your PATH.” FVM currently leaves this to the user.

### Proposed Solution (updated after Nov 4, 2025 maintainer comment)
Given the security implications of writing to users’ global Git config, the team would rather not auto-configure `safe.directory`. Instead:
1. **Documentation**: Keep the existing dedicated troubleshooting page and FAQ link current; do not recreate the page.
2. **Doctor Check**: Add a `fvm doctor` rule that detects the error string or failed Git commands and instructs users how to run `git config --global --add safe.directory <path>` themselves.
3. **CLI Messaging**: When Git throws the PATH error, catch it and surface a targeted explanation with a link to the troubleshooting page.
4. **Optional Prompt**: Consider offering an *opt-in* command (e.g., `fvm doctor --fix-safe-directory`) that runs the Git command only when explicitly requested, to avoid silent modifications.

### Alternative Approaches
- If we later decide to offer automation, keep it behind an explicit opt-in flag/command to avoid surprising users or violating security policies.

### Dependencies & Risks
- Running `git config --global` modifies user settings; obtain consent via release notes and ensure we don’t override existing values.
- Some organizations restrict global config writes; log a warning if the command fails and fall back to current guidance.

## Classification Recommendation
- Priority: **P1 - High** (blocks Windows installs out of the box)
- Suggested Folder: `validated/p1-high/`

## Notes for Follow-up
- Documentation is now present on `main`; remaining closure criteria are doctor detection and targeted CLI messaging.
