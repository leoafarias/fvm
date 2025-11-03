# Issue #880: [Feature Request] Add force option to spawn command

## Metadata
- **Reporter**: @MobiliteDev
- **Created**: 2025-06-13
- **Reported Version**: FVM 3.x (CI usage)
- **Issue Type**: feature request
- **URL**: https://github.com/leoafarias/fvm/issues/880

## Problem Summary
`fvm spawn` always delegates to `EnsureCacheWorkflow` with default (interactive) behavior. When the cache needs repair, the workflow prompts the user, which breaks CI pipelines. Other commands (`fvm use`, `fvm install`) expose a `--force` flag to skip prompts; `spawn` does not.

## Version Context
- Reported against: v3.x
- Current version: v4.0.0
- Version-specific: no — spawn command still lacks `--force`

## Validation Steps
1. Reviewed `lib/src/commands/spawn_command.dart`; no flags defined besides positional args.
2. `EnsureCacheWorkflow.call` accepts `force` and uses it to bypass prompts; since `spawn` never passes a flag, CI remains interactive.

## Evidence
```
lib/src/commands/spawn_command.dart:31-44
  final ensureCache = EnsureCacheWorkflow(context);
  final cacheVersion = await ensureCache(flutterVersion);
# No force parameter handled.
```

## Current Status in v4.0.0
- [x] Still reproducible
- [ ] Already fixed
- [ ] Not applicable to v4.0.0
- [ ] Needs more information

## Troubleshooting/Implementation Plan

### Root Cause Analysis
`SpawnCommand` never exposes a non-interactive path, so when `EnsureCacheWorkflow` detects missing cache data it prompts, halting CI jobs. The flag already exists in the workflow but is unused by the command.

### Proposed Solution
1. Update `SpawnCommand` to add a boolean `--force` flag (consistent with `use`/`install`).
2. Parse the flag and pass it to `ensureCache(flutterVersion, force: forceFlag)`.
3. Consider adding `--skip-setup` and `--skip-pub-get` equivalents if we want parity, but primary request is `force`.
4. Add tests in `test/commands/spawn_command_test.dart` (create new test file if absent) verifying that:
   - Without `--force`, the workflow is invoked with `force: false`.
   - With `--force`, `EnsureCacheWorkflow.call` receives `force: true`.
   Use mocks similar to existing command tests.
5. Update documentation (`docs/pages/documentation/guides/workflows.mdx`) to mention the new flag.

### Alternative Approaches
- Allow environment variable `FVM_FORCE=true` to make all commands non-interactive, but command-line flag is straightforward.

### Dependencies & Risks
- Minimal; ensure CLI help text indicates the new option.

## Classification Recommendation
- Priority: **P2 - Medium** (quality-of-life improvement for CI)
- Suggested Folder: `validated/p2-medium/`

## Notes for Follow-up
- After implementation, respond to reporter with release link showing the new flag.
