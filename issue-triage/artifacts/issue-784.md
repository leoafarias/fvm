# Issue #784: [Feature Request] Set specified version of Flutter SDK in current terminal environment

## Metadata
- **Reporter**: @SunJenry
- **Created**: 2024-09-20
- **Issue Type**: feature request
- **URL**: https://github.com/leoafarias/fvm/issues/784

## Problem Summary
User wants to temporarily use a specific Flutter version in the current shell session without modifying global config or creating project files.

## Existing Workarounds
- `fvm flutter <command>` or `fvm spawn <version> <command>` cover individual commands but still require prefix.

## Proposed Solution
- Add `fvm env <version>` that prints export commands, e.g. `eval "$(fvm env stable)"`, to prepend the version’s `bin` directory for the current shell. No files touched.
- Provide `fvm env --unset` to restore defaults.

## Classification Recommendation
- Priority: **P3 - Low**
- Suggested Folder: `validated/p3-low/`

## Notes for Follow-up
- Document usage including Windows PowerShell equivalents.
