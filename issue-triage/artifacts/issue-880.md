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
- [ ] Still reproducible
- [ ] Already fixed
- [x] Not applicable to v4.0.0 (maintainer closed as won't implement)
- [ ] Needs more information

## Troubleshooting/Implementation Plan

### Root Cause Analysis
Originally filed because `SpawnCommand` didn't expose a non-interactive path, so cache-repair prompts would hang CI. On Aug 26, 2025 (@leoafarias) clarified that adding `--force` to `spawn` would complicate the pass-through command; instead FVM now detects CI via `context.skipInput`, and users can append `--fvm-skip-input` if needed.

### Proposed Solution
No additional engineering planned; rely on CI auto-detect + `--fvm-skip-input` guidance.

### Alternative Approaches
- Allow environment variable `FVM_FORCE=true` to make all commands non-interactive, but command-line flag is straightforward.

### Dependencies & Risks
- Minimal; ensure CLI help text indicates the new option.

## Classification Recommendation
- Priority: **P2 - Medium** (quality-of-life improvement for CI)
- Suggested Folder: `validated/p2-medium/`

## Notes for Follow-up
- Issue closed on 2025-11-04 as "not planned"; if demand resurfaces, reassess the trade-offs outlined above.
