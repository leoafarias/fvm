# Issue #884: [Feature Request] Add `--[no-]update-gitignore` flag to `fvm use`

## Metadata
- **Reporter**: @albinpk
- **Created**: 2025-06-27
- **Reported Version**: FVM 3.x
- **Issue Type**: feature request (command flag)
- **URL**: https://github.com/leoafarias/fvm/issues/884

## Problem Summary
The reporter wanted a flag to force `.gitignore` updates because `fvm use --force --skip-setup` used to skip the prompt and warning, leaving `.fvm/` unignored.

## Validation Steps
1. Inspected `SetupGitIgnoreWorkflow` (lib/src/workflows/setup_gitignore.workflow.dart). In v4.0.0 it now updates `.gitignore` automatically when `updateGitIgnore` is true, without prompting.
2. Ran `fvm use stable --force --skip-setup` on v4.0.0; the CLI no longer shows the warning from the issue—`.gitignore` is updated silently.

## Evidence
```
$ fvm use stable --force --skip-setup
[WARN] Not checking for version mismatch as --force flag is set.
✓ Dependencies resolved.
✓ Project now uses Flutter SDK : Channel: Stable
# No gitignore warning; .gitignore contains "# FVM Version Cache" block.

lib/src/workflows/setup_gitignore.workflow.dart:33-42  // auto-updates without prompt
```

## Current Status in v4.0.0
- [ ] Still reproducible
- [x] Already fixed (feature implemented differently)
- [ ] Not applicable to v4.0.0
- [ ] Needs more information

## Recommendation
Close as resolved—no additional CLI flag needed because `.gitignore` management is automatic. If users want to opt out, they can set `updateGitIgnore: false` in `.fvmrc`.

## Classification Recommendation
- Folder: `resolved/`
