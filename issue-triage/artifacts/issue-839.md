# Issue #839: [BUG] "You should add the fvm version directory \".fvm/\" to .gitignore." does not add a newline

## Metadata
- **Reporter**: @twogood
- **Created**: 2025-04-21
- **Reported Version**: FVM 3.2.1
- **Issue Type**: bug (minor)
- **URL**: https://github.com/leoafarias/fvm/issues/839

## Problem Summary
When FVM appends `.fvm/` to `.gitignore`, the file is written without a terminating newline. Subsequent manual appends end up on the same line.

## Version Context
- Reported against: v3.2.1
- Current version: v4.0.0
- Version-specific: no — `SetupGitIgnoreWorkflow` still writes without trailing newline.

## Validation Steps
1. Reviewed `SetupGitIgnoreWorkflow.call`. It reconstructs the file via `lines.join('\n')` and writes the string without ensuring a final newline.
2. Reproduced by executing `fvm use stable` in a test repo: `.gitignore` ends with `.fvm/` and EOF.

## Evidence
```
lib/src/workflows/setup_gitignore.workflow.dart:99-102
  ignoreFile.writeAsStringSync(lines.join('\n'), mode: FileMode.write);
# No trailing newline appended.
```

## Current Status in v4.0.0
- [x] Still reproducible
- [ ] Already fixed
- [ ] Not applicable to v4.0.0
- [ ] Needs more information

## Troubleshooting/Implementation Plan
1. After joining lines, append a newline: `lines.join('\n') + '\n'` (unless file already empty?). Alternatively, use `writeAsStringSync(..., mode: FileMode.write)` with `Lines.join('\n')` and call `writeln`.
2. Add unit test simulating existing `.gitignore` and verifying file ends with newline after workflow.
3. Ensure we don’t introduce double blank lines by adjusting fold logic if necessary.

## Classification Recommendation
- Priority: **P3 - Low** (cosmetic but improves UX)
- Suggested Folder: `validated/p3-low/`

## Notes for Follow-up
- After fix, close issue referencing commit and mention newline addition.
