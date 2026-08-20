# Issue #784: [Feature Request] Set specified version of Flutter SDK in current terminal environment

## Metadata
- **Reporter**: @SunJenry
- **Created**: 2024-09-20
- **Issue Type**: feature request
- **URL**: https://github.com/conceptadev/fvm/issues/784

## Problem Summary
User wants to temporarily use a specific Flutter version in the current shell session without modifying global config or creating project files.

## Validation Steps
1. Inspected current commands on `origin/main`.
2. Confirmed `fvm spawn <version> <command>` and `fvm flutter` affect child commands only.
3. Confirmed no command prints shell exports for evaluation in the caller's current shell.

## Evidence
```text
Available related commands: global, spawn, flutter, dart, exec.
No env/current command or shell-export output exists.
```

## Current Status in v4.1.2
- [x] Still unresolved
- [ ] Already implemented
- [ ] Needs more information

## Existing Workarounds
- `fvm flutter <command>` or `fvm spawn <version> <command>` cover individual commands but still require prefix.

## Troubleshooting/Implementation Plan
- Add `fvm env <version>` that prints export commands, e.g. `eval "$(fvm env stable)"`, to prepend the version’s `bin` directory for the current shell. No files touched.
- Provide `fvm env --unset` to restore defaults.
- Define separate output for POSIX shells, fish, and PowerShell and add quoting tests for paths containing spaces.

## Recommendation
- Priority: **P3 - Low**
- Suggested Folder: `validated/p3-low/`

## Notes for Follow-up
- Document usage including Windows PowerShell equivalents.
