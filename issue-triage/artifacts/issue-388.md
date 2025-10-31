# Issue #388: [BUG] Intellij IDEA (Android Studio) with multiple flutter packages: cannot configure fvm

## Metadata
- **Reporter**: @fzyzcjy
- **Created**: 2022-02-20
- **Reported Version**: 2.x
- **Issue Type**: bug (IDE limitation)
- **URL**: https://github.com/leoafarias/fvm/issues/388

## Problem Summary
Android Studio/IntelliJ persists a single Flutter SDK path per project, so a multi-package workspace cannot map each package to its own FVM-managed SDK automatically. Even though FVM provides `.fvm/flutter_sdk` symlinks and flavor workflows, the IDE UI cannot swap SDKs per module today.

## Version Context
- Reported against: v2.x
- Current version: v4.0.0
- Version-specific: no
- Reason: IntelliJ still exposes only one `FLUTTER_SDK_PATH` per project; FVM 4.0.0 does not modify IDE settings.

## Validation Steps
1. Reviewed Android Studio configuration files—`FLUTTER_SDK_PATH` is stored in `.idea/misc.xml` as a single value shared by all modules.
2. Confirmed `fvm doctor` continues to warn when the IDE path does not target `.fvm/flutter_sdk`, showing the limitation persists (see `lib/src/commands/doctor_command.dart` lines 138-160).
3. Verified FVM’s CLI provides alternatives (`fvm flavor`, `fvm spawn`) but does not attempt to rewrite IntelliJ project files (see `lib/src/commands/flavor_command.dart`).

## Evidence
```
lib/src/commands/doctor_command.dart:138-160  // Detects when IntelliJ SDK path is not .fvm/flutter_sdk
lib/src/commands/flavor_command.dart:10-72    // CLI support for running commands on flavor-specific SDKs
issue-triage/artifacts/android-studio-research.md  // Internal research confirming single-SDK limitation
```

**Files/Code References:**
- [lib/src/commands/doctor_command.dart:138](../lib/src/commands/doctor_command.dart#L138) – Flags when IntelliJ isn't pointed at `.fvm/flutter_sdk`.
- [lib/src/commands/flavor_command.dart:10](../lib/src/commands/flavor_command.dart#L10) – Provides per-flavor command execution without IDE changes.
- [issue-triage/artifacts/android-studio-research.md](android-studio-research.md) – Summarizes IDE behavior and recommended mitigations.

## Current Status in v4.0.0
- [ ] Still reproducible
- [ ] Already fixed
- [x] Not applicable to v4.0.0
- [ ] Needs more information
- [ ] Cannot reproduce

## Troubleshooting/Implementation Plan

### Root Cause Analysis
Android Studio stores a single `FLUTTER_SDK_PATH` and does not expose per-module SDK switching. FVM cannot override this safely without manipulating `.idea` artifacts in unsupported ways.

### Proposed Solution
1. Clarify documentation with explicit guidance that IntelliJ/Android Studio require pointing the Flutter SDK to `.fvm/flutter_sdk` (per project) or `~/.fvm/default`.
2. Document the limitation for multi-package workspaces: open separate windows per package or rely on CLI commands for flavor-specific tasks.
3. Encourage affected users to file a feature request with the JetBrains Flutter plugin for per-module SDK selection; link to that request once available.
4. Track future enhancements separately (`fvm ide android-studio --sync`) if automation becomes feasible.

### Alternative Approaches
- Attempting to rewrite `.idea` files automatically is risky; opt-in tooling may be explored but is outside this issue’s scope.

### Dependencies & Risks
- Requires documentation updates and potential IDE helper workflow; no FVM runtime change today.

### Related Code Locations
- [lib/src/commands/doctor_command.dart:138](../lib/src/commands/doctor_command.dart#L138) – Current warning users see.
- [lib/src/workflows/update_vscode_settings.workflow.dart](../lib/src/workflows/update_vscode_settings.workflow.dart) – Reference workflow for IDE automation (potential future model for Android Studio).

## Recommendation
**Action**: resolved  
**Reason**: Behavior is constrained by Android Studio. FVM already provides guidance and CLI alternatives; closing the issue with documentation/workaround notes is appropriate.

## Draft Reply
```
Thanks for hanging in there! We dug into this again for FVM 4.0 and confirmed that Android Studio still exposes only a single Flutter SDK path per project. `fvm use` continues to keep `.fvm/flutter_sdk` up to date, but IntelliJ can’t swap SDKs per module the way VS Code workspaces do. The recommended workflow is:

- Point the project’s Flutter SDK at `.fvm/flutter_sdk` (or `~/.fvm/default` if you rely on the global toolchain).
- Open multi-package workspaces as separate windows when you need different SDKs simultaneously.
- Use `fvm flavor <name> <flutter command>` or `fvm spawn` for CLI tasks that need a specific version without touching the IDE.

We’ll keep the docs called out and track IDE automation separately, but there’s no change required in FVM itself, so I’m marking this one as resolved. If JetBrains adds per-module SDK support we’ll revisit—thanks again for raising it!
```

## Notes
- Align closure messaging with `android-studio-research.md` findings and reference the updated docs once published.

---
**Validated by**: Code Agent  
**Date**: 2025-10-31
