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
- [ ] Still reproducible
- [ ] Already fixed
- [x] Not applicable to v4.0.0
- [ ] Needs more information
- [ ] Cannot reproduce

## Resolution
- Outcome: **Won't implement** — keeping `fvm remove` narrowly scoped avoids wildcard edge cases and keeps maintenance surface small.
- GitHub comment drafted on 2025-11-03 to explain the decision and close the issue.

## Recommendation
**Action**: resolved (won't implement)

## Notes for Follow-up
- If demand resurfaces with stronger justification, reopen with concrete requirements and coverage plan for wildcard matching.
