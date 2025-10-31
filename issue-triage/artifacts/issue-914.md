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
1. Reviewed `docs/pages/documentation/getting-started/faq.md`, which documents the manual workaround (`git config --global --add safe.directory '*'`), confirming the issue is still acknowledged.
2. Audited the codebase (`lib/src/services/git_service.dart`, `CacheService`) and found no automation that marks the cache repository as safe.
3. Checked past issues (#789/#589/#569) referenced in the reporter’s comment to verify this has been a long-standing Windows pain point.

## Evidence
```
$ nl -ba docs/pages/documentation/getting-started/faq.md | sed -n '111,132p'
   116 Error: Unable to find git in your PATH.
   123 git config --global --add safe.directory '*'

$ rg "safe.directory" -n
<docs only; no implementation code>
```

## Current Status in v4.0.0
- [x] Still reproducible (requires manual git config)
- [ ] Already fixed
- [ ] Not applicable to v4.0.0
- [ ] Needs more information

## Troubleshooting/Implementation Plan

### Root Cause Analysis
Git 2.36+ flags FVM’s cache directory as “unsafe” because Flutter’s repository is cloned under a directory owned by a different SID (or outside the user’s profile). Without adding it to `safe.directory`, Git refuses to run and Flutter prints “Unable to find git in your PATH.” FVM currently leaves this to the user.

### Proposed Solution
1. **Detect Windows + Git version**: During cache creation (`GitService._createLocalMirror`) and updates, detect if we’re on Windows and Git ≥2.36 (parse `git --version`).
2. **Auto-mark safe directories**:
   - After cloning the cache (and when switching versions), run `git config --global --add safe.directory <path>` for `context.gitCachePath` and the derived version directories.
   - Before writing, check whether the entry already exists (`git config --global --get safe.directory <path>`) to avoid duplicates.
3. **Handle non-global configs**: Respect environments where users disable global config (e.g., corporate). Provide a `--no-git-safe-config` flag or env to opt out.
4. **Improve messaging**: If git commands still fail with the same error, catch the exception and surface a clearer hint rather than propagating Flutter’s generic message.
5. **Testing**:
   - Add an integration test (PowerShell or unit with `ProcessManager`) that simulates a Windows environment by mocking `git` responses, verifying we call `git config --global --add safe.directory`.
   - Manually validate on a Windows VM with Git 2.46 or later to ensure FVM installs without manual steps.
6. **Docs**: Update the FAQ to note that FVM now auto-configures safe directories, while leaving manual instructions for edge cases.

### Alternative Approaches
- Prompt the user the first time the error occurs, offering to run the `git config` command automatically. Less intrusive but adds interactive flow.

### Dependencies & Risks
- Running `git config --global` modifies user settings; obtain consent via release notes and ensure we don’t override existing values.
- Some organizations restrict global config writes; log a warning if the command fails and fall back to current guidance.

## Classification Recommendation
- Priority: **P1 - High** (blocks Windows installs out of the box)
- Suggested Folder: `validated/p1-high/`

## Notes for Follow-up
- Reconcile with docs once automation lands and close the linked historical issues (#789/#589/#569) as resolved.
