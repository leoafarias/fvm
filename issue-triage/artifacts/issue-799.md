# Issue #799: PathAccessException: Cannot open ~/.zshrc

## Metadata
- **Reporter**: @iampato
- **Created**: 2024-11-24
- **Reported Version**: FVM 3.x
- **Issue Type**: bug (duplicate)
- **URL**: https://github.com/leoafarias/fvm/issues/799

## Problem Summary
Running `fvm` after a Homebrew install throws `PathAccessException: Cannot open file, path = '/Users/.../.zshrc'`. The reporter’s shell profile is managed (likely read-only), matching the conditions of issue #897 (Nix/Home Manager environments preventing profile edits).

## Version Context
- Reported against: v3.x installer
- Current version: v4.0.0
- Version-specific: no
- Reason: FVM still attempts to touch shell profiles; the fix is tracked in #897.

## Validation Steps
1. Compared stack trace with issue #897—the same `PathAccessException` occurs when the installer tries to read/write shell config files.
2. Confirmed #897 remains open with a P1 plan to guard shell profile writes.
3. No unique reproduction steps beyond the scenario already covered in #897.

## Evidence
```
Issue #897  // Root cause analysis and fix plan
```

**Files/Code References:**
- [issue-triage/artifacts/issue-897.md](issue-897.md) – Active plan for the underlying bug.

## Current Status in v4.0.0
- [x] Still reproducible
- [ ] Already fixed
- [ ] Not applicable to v4.0.0
- [ ] Needs more information
- [ ] Cannot reproduce

## Troubleshooting/Implementation Plan

### Root Cause Analysis
Duplicate of #897; same read-only shell profile scenario.

### Proposed Solution
1. Link the reporter to #897 so they can track progress.
2. Close #799 as a duplicate once #897 is resolved.

### Alternative Approaches
- None; addressing #897 will fix this.

### Dependencies & Risks
- None beyond #897’s scope.

### Related Code Locations
- [scripts/install.sh](../scripts/install.sh) – Installer path that touches shell profiles (referenced in #897 plan).

## Recommendation
**Action**: resolved  
**Reason**: Duplicate of active issue #897; close after pointing to canonical tracking issue.

## Draft Reply
```
Thanks for reporting this! We’re tracking the same `PathAccessException` under #897—it happens when shell profiles are read-only (Home Manager, locked dotfiles, etc.). I’m going to mark this as a duplicate so we can keep the fix centralized. Please subscribe to #897 for updates and feel free to add any extra context there if your setup differs.
```

## Notes
- Ensure #897 response references this issue before closing.

---
**Validated by**: Code Agent  
**Date**: 2025-10-31
