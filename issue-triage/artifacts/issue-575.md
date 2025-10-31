# Issue #575: [Feature Request] Spawn on a flavor

## Metadata
- **Reporter**: Martin Braun (@martin-braun)
- **Created**: 2023-11-29
- **Reported Version**: 3.0.x
- **Issue Type**: enhancement
- **URL**: https://github.com/leoafarias/fvm/issues/575

## Problem Summary
The reporter wanted a way to run a Flutter command using a flavor-defined version without permanently switching (`fvm use`). The idea was akin to `fvm spawn` but driven by the `flavors` map in `.fvmrc`.

## Status in v4.0.0
- ✅ Already available. `fvm flavor <name> <flutter args>` executes the command against the flavor’s configured version without altering the active flavor.

## Validation Steps
1. Inspected `lib/src/commands/flavor_command.dart` — the command looks up the flavor, ensures the version is cached, and proxies the Flutter command via `FlutterService.runFlutter`.
2. Verified `FvmCommandRunner` registers `FlavorCommand`.
3. Manually tested (`fvm flavor lts flutter --version`) — runs with the flavor version and doesn’t change the current flavor.

## Recommendation
**Action**: resolved

**Reason**: Functionality requested is now provided by `fvm flavor`. We should respond on the issue with usage examples and point to docs; no new engineering work required.

## Notes
- Consider updating documentation to highlight the `fvm flavor` command for this workflow.

---
**Validated by**: Code Agent
**Date**: 2025-10-31
