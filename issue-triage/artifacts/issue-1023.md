# Issue #1023: [BUG] How to upgrade fvm flutter?

## Metadata
- **Reporter**: i11010520
- **Created**: 2026-03-11
- **Reported Version**: Not specified; doctor output shows FVM with Dart 3.11.0
- **Issue Type**: question/documentation
- **URL**: https://github.com/leoafarias/fvm/issues/1023

## Problem Summary
The reporter ran `fvm flutter upgrade` and received Flutter's warning about local changes in the cached checkout. They ask whether this is normal and what the correct upgrade workflow is for an FVM-managed SDK.

## Version Context
- Reported against: current FVM 4.x behavior
- Current version: v4.0.0 triage baseline; branch package version is 4.0.5
- Version-specific: no
- Reason: The confusion comes from the FVM proxy workflow and documentation, not one specific SDK version.

## Validation Steps
1. Checked current docs for upgrade guidance.
2. Checked `FlutterCommand` behavior for `fvm flutter upgrade`.
3. Checked comments on the issue; the only response confirms the user should usually install/use a new version rather than mutating a pinned cached release.

## Evidence
```text
docs/pages/documentation/getting-started/faq.md: FVM currently says channel upgrades use standard flutter upgrade.
docs/pages/documentation/guides/basic-commands.mdx:271: Prevents flutter upgrade on release versions. Use channels for upgrades.
lib/src/commands/flutter_command.dart:50-55: release versions are blocked, channels are allowed.
```

**Files/Code References:**
- [../../lib/src/commands/flutter_command.dart](../../lib/src/commands/flutter_command.dart) - blocks `flutter upgrade` for release versions only.
- [../../docs/pages/documentation/getting-started/faq.md](../../docs/pages/documentation/getting-started/faq.md) - upgrade guidance.
- [../../docs/pages/documentation/guides/basic-commands.mdx](../../docs/pages/documentation/guides/basic-commands.mdx) - command reference note.

## Current Status in v4.0.0
- [x] Still reproducible
- [ ] Already fixed
- [ ] Not applicable to v4.0.0
- [ ] Needs more information
- [ ] Cannot reproduce

## Troubleshooting/Implementation Plan

### Root Cause Analysis
FVM proxies Flutter commands and only blocks `flutter upgrade` for release versions. For channel caches, the upstream Flutter command can still mutate the cached checkout and surface local-change warnings. The docs do not clearly state the preferred FVM workflow: install or pin a newer SDK version instead of manually upgrading a cached release checkout.

### Proposed Solution
1. Update the FAQ and basic command docs to clarify the difference between upgrading a channel cache and moving a project/global config to a newer release.
2. Cross-link #583, which already tracks a first-class `fvm upgrade` workflow.
3. Consider improving the `flutter upgrade` warning to point users to `fvm install <version>`, `fvm use <version>`, or `fvm global <version>`.
4. Add a test for release-version upgrade blocking and, if UX changes, a test for the new message.

### Alternative Approaches
- Block `fvm flutter upgrade` for all FVM-managed SDKs and require explicit `fvm install/use`.
- Keep channel upgrades allowed but require a clearer confirmation prompt.

### Dependencies & Risks
- Blocking all upgrades may surprise channel users who intentionally track `stable`, `beta`, or `master`.
- Documentation changes are low risk and should happen first.

### Related Code Locations
- [../../lib/src/commands/flutter_command.dart](../../lib/src/commands/flutter_command.dart) - command guard.
- [../../test/src/commands/flutter_upgrade_check_test.dart](../../test/src/commands/flutter_upgrade_check_test.dart) - existing guard tests.
- [../../docs/pages/documentation/getting-started/faq.md](../../docs/pages/documentation/getting-started/faq.md) - user-facing guidance.

## Recommendation
**Action**: validate-p3

**Reason**: Valid recurring workflow confusion, but not a confirmed FVM crash. It overlaps with #583 and primarily needs docs/UX clarification.

## Notes
If #583 is implemented, this issue can likely be closed with guidance to use the new workflow.

---
**Validated by**: Code Agent
**Date**: 2026-06-10
