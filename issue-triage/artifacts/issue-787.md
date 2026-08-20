# Issue #787: [Feature Request] Add alias command files for execute directly `flutter`

## Metadata
- **Reporter**: @quyenvsp
- **Created**: 2024-10-10
- **Issue Type**: feature request
- **URL**: https://github.com/conceptadev/fvm/issues/787

## Problem Summary
Request to ship wrapper scripts (`flutter`, `dart`, `fvm`) so users can run `flutter` directly through FVM without prefixing commands.

## Current Behavior
- FVM offers `fvm global` (adds `~/.fvm/default/bin` to PATH) and project symlinks (`.fvm/flutter_sdk/bin`). Users can already set PATH to those directories.
- Reporter provided alias scripts used locally for 2 years.

## Validation Steps
1. Confirmed current FVM maintains a global SDK link and documents adding its `bin` directory to PATH.
2. Confirmed FVM does not ship `flutter`/`dart` wrapper executables alongside the FVM binary.
3. Confirmed project-local direct resolution still requires IDE configuration, shell hooks, or manual PATH changes.

## Evidence
```text
Current commands include `fvm global`, `fvm flutter`, and `fvm dart`.
No packaged alias/flutter or alias/dart wrappers exist on origin/main.
```

## Considerations
- Adding wrappers could simplify setup, especially on Windows.
- Need to ensure wrappers respect `fvm use` project settings and global version, and don't conflict with existing Flutter installations.

## Troubleshooting/Implementation Plan
1. Evaluate existing `global` command behavior; confirm direct `flutter` via symlink meets requirement. Document this path first.
2. If wrappers still useful (e.g., for CI), package optional `bin/flutter` and `bin/dart` scripts calling `fvm flutter`/`fvm dart`.
3. Update installer to create wrappers only when safe (avoid overwriting existing binaries).
4. Document usage and potential conflicts.
5. Test command resolution when a system Flutter is already earlier on PATH and on Windows where wrapper/shim behavior differs.

## Recommendation
- Priority: **P3 - Low** (quality-of-life enhancement; alternative already exists via PATH)
- Suggested Folder: `validated/p3-low/`

## Notes for Follow-up
- Might close after improving docs explaining how to add `.fvm/flutter_sdk/bin` to PATH.
