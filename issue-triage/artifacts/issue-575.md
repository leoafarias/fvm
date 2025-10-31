# Issue #575: [Feature Request] Spawn on a flavor

## Metadata
- **Reporter**: @martin-braun
- **Created**: 2023-11-29
- **Reported Version**: 3.0.x
- **Issue Type**: enhancement
- **URL**: https://github.com/leoafarias/fvm/issues/575

## Problem Summary
The reporter asked for a way to run Flutter commands using the versions declared in the `.fvmrc` `flavors` map without permanently switching the active flavor. They effectively wanted `fvm spawn` semantics tied to a flavor name.

## Version Context
- Reported against: v3.0.x
- Current version: v4.0.0
- Version-specific: no
- Reason: The `flavor` command ships with FVM 4.0.0 and already implements the requested behavior.

## Validation Steps
1. Inspected `lib/src/commands/flavor_command.dart` to confirm it resolves the flavor, validates the configured version, installs it if needed, and proxies the Flutter command (lines 10-72).
2. Verified the command is registered in the runner (`lib/src/runner.dart:68`).
3. Confirmed documentation advertises `fvm flavor <flavor> <flutter_command>` including examples (`docs/pages/documentation/guides/basic-commands.mdx:321-343`).

## Evidence
```
lib/src/commands/flavor_command.dart:10-72  // Flavor command executes Flutter commands using flavor-specific versions
lib/src/runner.dart:68                      // Registers FlavorCommand with the CLI runner
docs/pages/documentation/guides/basic-commands.mdx:321-343  // User-facing docs describing fvm flavor usage
```

**Files/Code References:**
- [lib/src/commands/flavor_command.dart:10](../lib/src/commands/flavor_command.dart#L10) – Implementation of `fvm flavor`.
- [lib/src/runner.dart:68](../lib/src/runner.dart#L68) – Command registration.
- [docs/pages/documentation/guides/basic-commands.mdx:321](../docs/pages/documentation/guides/basic-commands.mdx#L321) – Documentation section covering the workflow.

## Current Status in v4.0.0
- [ ] Still reproducible
- [x] Already fixed
- [ ] Not applicable to v4.0.0
- [ ] Needs more information
- [ ] Cannot reproduce

## Troubleshooting/Implementation Plan

### Root Cause Analysis
The capability exists; users may have missed it due to earlier documentation gaps. No new engineering work required.

### Proposed Solution
1. Reply on the issue with clear instructions and examples using `fvm flavor`.
2. Cross-link the relevant docs (`basic-commands` and `project-flavors` guide).
3. Optionally add a short FAQ snippet pointing to `fvm flavor` for temporary version usage.

### Alternative Approaches
- `fvm use {flavor}` also works but persists the environment; clarify the distinction in docs.

### Dependencies & Risks
- Documentation-only. No code changes.

### Related Code Locations
- [docs/pages/documentation/guides/project-flavors.md:46](../docs/pages/documentation/guides/project-flavors.md#L46) – Additional examples for flavor workflows.

## Recommendation
**Action**: resolved  
**Reason**: The requested functionality is available and documented; respond with instructions and close.

## Draft Reply
```
Great news—this workflow is already available today. 🎉

`fvm flavor <name> <flutter command>` looks up the version you pinned under that flavor in `.fvmrc`, ensures it’s installed, and runs the Flutter command without switching your current flavor. For example:

```bash
fvm flavor lts flutter --version
fvm flavor staging flutter build apk
```

Docs for reference: https://fvm.app/documentation/guides/basic-commands#flavor

Because the command fully covers this request I’m going to close the issue, but feel free to follow up if anything is missing.
```

## Notes
- Consider adding a short tip to the `fvm flavor` docs highlighting that it preserves the active flavor.

---
**Validated by**: Code Agent  
**Date**: 2025-10-31
