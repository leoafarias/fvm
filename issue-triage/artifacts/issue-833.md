# Issue #833: [Feature Request] wild card

## Metadata
- **Reporter**: @shinriyo
- **Created**: 2025-03-22
- **Reported Version**: FVM 3.x
- **Issue Type**: feature request
- **URL**: https://github.com/leoafarias/fvm/issues/833

## Problem Summary
`fvm remove` currently accepts a specific version or the `--all` flag. The reporter wants wildcard support (e.g., `fvm remove 3.27.*`) to bulk remove patch versions.

## Version Context
- Reported against: pre-v4
- Current version: v4.0.0
- Version-specific: no — command syntax unchanged

## Validation Steps
1. Reviewed `RemoveCommand` (lib/src/commands/remove_command.dart); it parses explicit versions or `--all` and iterates accordingly.
2. No wildcard handling exists; implementing requires pattern matching before removal.

## Evidence
```
lib/src/commands/remove_command.dart
  final versions = argResults!.rest; // expects explicit versions
```

## Current Status in v4.0.0
- [x] Still valid feature gap

## Troubleshooting/Implementation Plan
1. Extend `RemoveCommand` to detect version patterns containing `*` and expand them against installed cache versions (`CacheService.getAllVersions`).
2. Support `major.*`, `major.minor.*`, and channel names? Clarify expected scope; start with semver segments.
3. Update command help to document wildcard usage (include escaping instructions for shells).
4. Add tests covering pattern expansion and verifying that nonexistent patterns result in no action (with warning).

## Classification Recommendation
- Priority: **P3 - Low** (quality-of-life enhancement)
- Suggested Folder: `validated/p3-low/`

## Notes for Follow-up
- Consider reusing semver parsing from `FlutterVersion` to avoid manual globbing.
