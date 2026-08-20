# Issue #761: [Feature Request] when we typo, show error

## Metadata
- **Reporter**: @shinriyo
- **Created**: 2024-08-22
- **Issue Type**: UX bug
- **URL**: https://github.com/conceptadev/fvm/issues/761

## Problem Summary
Typos like `fvm fluter --version` should produce an error, but currently FVM ignores the unknown token and just prints the version (because `--version` is handled as a global flag).

## Validation Steps
1. Reproduced against the current branch: `dart run bin/main.dart fluter --version`.
2. Confirmed it printed the package version and exited successfully.
3. Inspected `FvmCommandRunner.runCommand`; top-level `--version` is handled before the unknown command is rejected.

## Evidence
```text
$ dart run bin/main.dart fluter --version
4.1.1
$ echo $?
0
```

## Troubleshooting/Implementation Plan
In `FvmCommandRunner.run`, after parsing args, detect `argResults.rest` when no command selected and throw `UsageException` with unknown command message.
Add regression tests for typos with and without top-level flags, ensuring valid `fvm --version` remains successful.

## Recommendation
- Priority: **P3 - Low**
- Suggested Folder: `validated/p3-low/`
