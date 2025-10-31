# Issue #761: [Feature Request] when we typo, show error

## Metadata
- **Reporter**: @shinriyo
- **Created**: 2024-08-22
- **Issue Type**: UX bug
- **URL**: https://github.com/leoafarias/fvm/issues/761

## Problem Summary
Typos like `fvm fluter --version` should produce an error, but currently FVM ignores the unknown token and just prints the version (because `--version` is handled as a global flag).

## Proposed Fix
In `FvmCommandRunner.run`, after parsing args, detect `argResults.rest` when no command selected and throw `UsageException` with unknown command message.

## Classification Recommendation
- Priority: **P3 - Low**
- Suggested Folder: `validated/p3-low/`
