# Issue #897: How to avoid warning of access .bash_profile?

## Metadata
- **Reporter**: @i11010520
- **Created**: 2025-07-24
- **Reported Version**: FVM 3.x (Nix/Home Manager environment)
- **Issue Type**: bug (installer integration)
- **URL**: https://github.com/leoafarias/fvm/issues/897

## Problem Summary
Running FVM in a Nix/Home Manager environment prints `PathAccessException: Cannot open file, path = '/Users/me/.bash_profile' (OS Error: Permission denied, errno = 13)`. Home Manager manages shell profiles in the Nix store, making files like `~/.bash_profile` read-only. FVM shouldn’t attempt to open/write those files automatically.

## Version Context
- Reported against: v3.x installer / CLI
- Current version: v4.0.0
- Version-specific: no — still relevant where Home Manager controls shell configs

## Validation Steps
1. Reviewed `scripts/install.sh`; it appends PATH exports to `.bashrc`/`.bash_profile` when writable. However the Dart CLI likely still probes these files elsewhere, triggering the `PathAccessException`.
2. Searched the codebase for `.bash_profile` references; only the installer mentions it, suggesting the runtime access happens indirectly (e.g., via packaging hooks or update checks). We need a reproduction in Nix to capture the stack trace.
3. Confirmed the issue remains open and unaddressed in v4.0.0 (no guard around shell profile access).

## Evidence
```
Issue report: PathAccessException ... '/Users/me/.bash_profile'
Scripts: scripts/install.sh lines 454+ append to ~/.bash_profile when writable.
```

## Current Status in v4.0.0
- [x] Still reproducible (likely)
- [ ] Already fixed
- [ ] Not applicable to v4.0.0
- [ ] Needs more information

## Troubleshooting/Implementation Plan

### Root Cause Investigation
1. Reproduce on macOS/Linux with a read-only shell profile (simulate Home Manager by chmod 444 or bind-mount). Capture the full FVM stack trace to pinpoint where the CLI touches `.bash_profile`.
2. Audit packaging hooks (e.g., `cli_pkg` wrappers) to see if they try to source shell profiles.

### Fix Plan
1. **Skip shell config access when non-writable**:
   - Guard any file reads/writes to `~/.bash_profile`, `~/.bashrc`, `~/.zshrc` with try/catch and downgrade to a warning.
   - Introduce an environment flag (e.g., `FVM_SKIP_SHELL_CONFIG=true`) that tells the installer/CLI to skip profile modifications entirely.
2. **Installer improvements**:
   - Enhance `update_shell_config` to detect read-only Home Manager paths (use `test -w` plus check `stat -f %Su` vs current user). If not writable, log a clear hint instead of delegating to Dart code.
3. **Runtime adjustments**:
   - If the Dart CLI itself tries to open shell profiles (e.g., to show suggestions), catch `FileSystemException` at top level (`runner.dart`) and map it to a friendly message (“Profile is managed by Nix; run export manually”).
4. **Documentation**:
   - Update installation docs with a Home Manager section explaining manual PATH export and the new skip flag.

### Alternative Approaches
- Provide a CLI command (`fvm env --print-path`) so users can integrate manually without any automatic profile edits.

### Dependencies & Risks
- Must ensure we don’t silently skip profile updates for standard users who rely on automation.
- Need to validate across bash/zsh/fish and on systems with strict permissions.

## Classification Recommendation
- Priority: **P1 - High** (prevents users in managed environments from running FVM without manual edits)
- Suggested Folder: `validated/p1-high/`

## Notes for Follow-up
- After implementing guards, test on a Home Manager VM. If runtime never touches `.bash_profile`, update the issue with findings (might be purely installer). Close if reproducible warning disappears.
