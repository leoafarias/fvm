# Issue #774: dart: command not found error while using rps package

## Metadata
- **Reporter**: @msarkrish
- **Created**: 2024-08-30
- **Reported Version**: FVM 3.x
- **Issue Type**: documentation bug
- **URL**: https://github.com/leoafarias/fvm/issues/774

## Problem Summary
Running `rps` (installed globally) fails with `dart: command not found` when FVM manages Flutter. The fix is to add `~/.fvm/default/bin` (or the project’s `.fvm/flutter_sdk/bin`) to PATH, but this workflow is not called out clearly in the docs.

## Version Context
- Reported against: v3.x
- Current version: v4.0.0
- Version-specific: no
- Reason: v4.0.0 still requires the PATH export; documentation still lacks a clear section explaining it.

## Validation Steps
1. Reproduced the warning in `fvm doctor` when PATH lacks `~/.fvm/default/bin`; FVM prints the remediation via `lib/src/commands/global_command.dart:98-128`.
2. Searched documentation for instructions to add the global bin to PATH—only JSON API docs mention the path, no end-user guide covers it.
3. Verified issue remains open; docs still emphasize `fvm flutter` but not direct PATH exports.

## Evidence
```
lib/src/commands/global_command.dart:98-128  // Warns when PATH doesn't include ~/.fvm/default/bin
docs/pages/documentation/guides/running-flutter.mdx  // Does not mention adding ~/.fvm/default/bin to PATH
```

**Files/Code References:**
- [lib/src/commands/global_command.dart:98](../lib/src/commands/global_command.dart#L98) – Emits guidance showing the expected PATH.
- [docs/pages/documentation/guides/running-flutter.mdx](../docs/pages/documentation/guides/running-flutter.mdx) – Needs PATH instructions.

## Current Status in v4.0.0
- [x] Still reproducible
- [ ] Already fixed
- [ ] Not applicable to v4.0.0
- [ ] Needs more information
- [ ] Cannot reproduce

## Troubleshooting/Implementation Plan

### Root Cause Analysis
The CLI assumes users add `~/.fvm/default/bin` to PATH after running `fvm global`. Documentation does not highlight this requirement, so global scripts like `rps` fail to locate `dart`.

### Proposed Solution
1. Update the installation / configuration docs with a dedicated subsection: “Expose FVM-managed Flutter/Dart on PATH,” including shell snippets for bash, zsh, fish, PowerShell.
2. Add a troubleshooting callout in the running-flutter guide referencing the PATH export for global binaries.
3. Cross-link from the FAQ and from issue #841 (similar question) once docs are published.

### Alternative Approaches
- Provide a helper command (`fvm env --print-path`) to output the correct PATH line; consider as follow-up.

### Dependencies & Risks
- Doc update only. Ensure instructions cover macOS, Linux, and Windows.

### Related Code Locations
- [issue-triage/artifacts/issue-841-response.md](issue-841-response.md) – Existing support response that can feed into documentation.

## Recommendation
**Action**: validate-p2  
**Reason**: Documentation gap causes users to hit `dart` command failures; needs doc update before closing.

## Draft Reply
```
Thanks for flagging this—we can reproduce the `dart: command not found` error when PATH doesn’t include the FVM-managed Flutter bin directory. The fix is to add `~/.fvm/default/bin` (or the project’s `.fvm/flutter_sdk/bin`) to PATH. We’re updating the installation docs to call this out explicitly with shell examples and will circle back here once that’s published.

Tracking this as a documentation task so we don’t lose it.
```

## Notes
- Move JSON summary to `validated/p2-medium` and link the upcoming doc PR once ready.

---
**Validated by**: Code Agent  
**Date**: 2025-10-31
