# Issue #841: [BUG] flutter globalized failed

## Metadata
- **Reporter**: @megumin31
- **Created**: 2025-05-05
- **Reported Version**: FVM 3.2.1 (Arch Linux)
- **Issue Type**: support/doc clarification
- **URL**: https://github.com/leoafarias/fvm/issues/841

## Problem Summary
After running `fvm install stable --setup` followed by `fvm global stable`, the reporter expected `flutter` to work without the `fvm` prefix. Instead, the shell reported `Unknown command: flutter`.

## Version Context
- Reported against: 3.2.1
- Current version: v4.0.0
- Version-specific: no — behavior is unchanged

## Validation Steps
1. Examined `GlobalCommand`: it configures the global symlink (`~/.fvm/default`) and warns if PATH does not point to that bin directory. No bug surfaced during review.
2. Reproduced locally by removing `~/.fvm/default/bin` from PATH. After running `fvm global stable`, Flutter remains unavailable until PATH includes the global bin directory. The command prints a notice explaining the mismatch.
3. Confirmed installer docs instruct users to add the global bin to PATH; see `docs/pages/documentation/getting-started/installation.mdx` (PATH configuration notes).

## Evidence
```
lib/src/commands/global_command.dart:118-127
  if (!isDefaultInPath && !isCachedVersionInPath ...) {
    logger.notice('However your configured "flutter" path is incorrect')
    ... prints current and expected path (globalCacheBinPath)
  }
```

## Current Status in v4.0.0
- [ ] Still reproducible as a software defect
- [x] Not an FVM bug (user PATH configuration)

## Recommendation
Close as “working as intended” with guidance:
- Ensure the global bin (`~/.fvm/default/bin`) is on PATH. The installer or docs cover how to add it for Bash/Zsh/Fish.
- Alternatively use `fvm flutter` when PATH cannot be modified.

## Classification Recommendation
- Folder: `resolved/`

## Notes for Follow-up
- Consider enhancing documentation to highlight this step in the “Global” command section, but no code change required.
