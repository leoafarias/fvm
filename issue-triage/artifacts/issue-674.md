# Issue #674: Pass global level flags and options

## Metadata
- **Reporter**: Leo Farias (@leoafarias)
- **Created**: 2024-02-29
- **Reported Version**: 3.0.x
- **Issue Type**: enhancement (internal architecture)
- **URL**: https://github.com/leoafarias/fvm/issues/674

## Problem Summary
Several command-line flags (e.g., `--force`, `--skip-setup`, `--skip-pub-get`) are passed down through multiple command/workflow layers. Each new workflow needs to accept these parameters, making the signature surface inconsistent and error-prone. We want a single source of truth for runtime options so sub-workflows can consult context instead of adding more method arguments.

## Version Context
- Reported against: FVM 3.0.x
- Current version: v4.0.0
- Version-specific: no — current code still threads flags manually.
- Reason: No runtime option registry exists in `FvmContext`; commands mutate boolean flags and forward them manually.

## Validation Steps
1. Reviewed `lib/src/commands/use_command.dart:52-90` and observed flags being read and passed to `UseVersionWorkflow`, `EnsureCacheWorkflow`, etc.
2. Inspected other commands (e.g., `global`, `destroy`) and found similar boilerplate to propagate `--force`.
3. Checked `FvmContext` (`lib/src/utils/context.dart`) — it stores configuration and environment, but not per-command runtime options.
4. Confirmed no helper exists to set or retrieve command-scoped flags from the context, so every workflow must carry extra parameters.

## Evidence
```
$ sed -n '52,120p' lib/src/commands/use_command.dart
    final forceOption = boolArg('force');
    final skipPubGet = boolArg('skip-pub-get');
    final skipSetup = boolArg('skip-setup');
    ...
    await useVersion(
      version: cacheVersion,
      project: project,
      force: forceOption,
      skipSetup: skipSetup,
      skipPubGet: skipPubGet,
      flavor: flavorOption,
    );
```

**Files/Code References:**
- [lib/src/commands/use_command.dart#L52](../lib/src/commands/use_command.dart#L52) – Example of flag propagation.
- [lib/src/utils/context.dart#L1](../lib/src/utils/context.dart#L1) – Context currently lacks runtime option storage.

## Current Status in v4.0.0
- [x] Still reproducible
- [ ] Already fixed
- [ ] Not applicable to v4.0.0
- [ ] Needs more information
- [ ] Cannot reproduce

## Troubleshooting/Implementation Plan

### Root Cause Analysis
Without a central registry, every workflow must receive flags explicitly. This leads to repetitive signatures and risks forgetting to forward a flag when introducing new workflows.

### Proposed Solution
1. Extend `FvmContext` with a `CommandOptions` helper:
   - Add a mutable `Map<String, dynamic>` (or typed wrapper) and helper methods (`setOption`, `getBool`, etc.).
   - Ensure the map resets for each command invocation to avoid leaks between runs.
2. Enhance `FvmCommandRunner.run` / `runCommand`:
   - After `parse(args)`, store relevant global values (e.g., `verbose`) and pass the full `ArgResults` to the active command.
   - Introduce a lightweight `CommandScope` utility to push/pop options when subcommands are executed programmatically.
3. Update commands/workflows gradually:
   - Replace parameters like `skipSetup`, `force`, `skipPubGet` with reads from `context.commandOptions`.
   - Maintain backward compatibility during migration by defaulting to parameter values if provided.
   - Simplify workflow signatures once all call sites rely on context.
4. Provide helpers for defaulting and type safety (e.g., `context.options.skipSetup`).
5. Add tests verifying:
   - Options persist throughout nested workflow invocations.
   - Options reset between separate command executions.
6. Document the new API for maintainers (in `AGENTS.md` / contributor docs) to encourage using context instead of threading parameters.

### Alternative Approaches (if applicable)
- Create immutable command config objects and pass a single `UseOptions` struct instead of multiple parameters. Still requires manual forwarding, so context-based storage is cleaner.

### Dependencies & Risks
- Need to avoid stale data when running commands programmatically (e.g., integration tests). Ensure options map is cleared when command completes.
- Multi-threaded/parallel execution is not supported today; the new map should stay command-local.
- Commands that spawn other FVM commands (integration tests) must propagate or isolate options intentionally.

### Related Code Locations
- [lib/src/workflows/use_version.workflow.dart#L21](../lib/src/workflows/use_version.workflow.dart#L21) – Candidate for reading flags from context instead of parameters.
- [lib/src/commands/destroy_command.dart#L27](../lib/src/commands/destroy_command.dart#L27) – Another example of manual flag handling.

## Recommendation
**Action**: validate-p2

**Reason**: Architectural cleanup that reduces boilerplate and future bugs. Medium priority because current behavior works, but maintenance cost is high.

## Notes
- After rollout, audit all commands for duplicate flag parsing and remove redundant parameters.
- Consider surfacing command options in debug logging to aid troubleshooting (`logger.debug`).

---
**Validated by**: Code Agent
**Date**: 2025-10-31
