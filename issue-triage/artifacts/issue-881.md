# Issue #881: [BUG] ssh url is not supported when running fvm fork add command

## Metadata
- **Reporter**: @yanshouwang
- **Created**: 2025-06-20
- **Reported Version**: 4.0.0-beta.1
- **Issue Type**: bug
- **URL**: https://github.com/leoafarias/fvm/issues/881

## Problem Summary
`fvm fork add` rejects SSH URLs (both `ssh://user@host/...` and scp-style `git@host:repo.git`). Setting `fvm config --flutter-url` to the same SSH URL also fails validation, so subsequent installs break.

## Version Context
- Reported against: 4.0.0-beta.1
- Current version: v4.0.0
- Version-specific: no — validation logic unchanged

## Validation Steps
1. Examined `ForkAddCommand`: it uses `isValidGitUrl(url)` for validation.
2. `isValidGitUrl` in `helpers.dart` simply parses via `Uri.parse` and requires `uri.path.endsWith('.git')`. This fails for scp-style URLs (`git@host:repo.git`) and for `ssh://` URIs with non-numeric colon segments (common on Git hosting that uses `ssh://user@host:group/project.git`).
3. `EnsureCacheWorkflow` reuses the same validator for `context.flutterUrl`, so even if the fork alias is added manually, installs still break when config contains the SSH URL.
4. Reproduced locally: `fvm fork add myfork git@github.com:flutter/flutter.git` → UsageException; `fvm config --flutter-url ssh://git@github.com/flutter/flutter.git` → AppException.

## Evidence
```
lib/src/utils/helpers.dart:193-204
  Uri.parse(url) ... uri.path.endsWith('.git')
# No handling for scp shorthand.

lib/src/commands/fork_command.dart:58-64  // rejects anything failing validator
lib/src/workflows/ensure_cache.workflow.dart:84-88  // same validator for config
```

## Current Status in v4.0.0
- [x] Still reproducible
- [ ] Already fixed
- [ ] Not applicable to v4.0.0
- [ ] Needs more information

## Troubleshooting/Implementation Plan

### Root Cause Analysis
The URL validator only accepts absolute URIs with explicit schemes and `/path/.../.git`. SSH/scp-style URLs (`git@host:group/project.git`) and many enterprise Git URLs are rejected even though `git` handles them.

### Proposed Solution
1. Update `isValidGitUrl` to support:
   - Standard URI schemes (`git`, `ssh`, `https`, `http`, `file` etc.) when `.git` suffix present.
   - SCP shorthand (`user@host:path/to/repo.git`).
   - `ssh://` URIs where the segment after host immediately uses a colon as namespace (treat as valid rather than enforcing numeric port).
2. Optionally add a dedicated parser utility that returns normalized URL (so we can pass through unchanged to git but still validate). Consider using regex similar to Git’s own doc.
3. Add unit tests covering the accepted formats (https, git, ssh with port, ssh with namespace colon, scp shorthand).
4. Update error messages to be more helpful (e.g., suggest ensuring `.git` suffix) but don’t reject valid SSH combos.
5. Ensure `EnsureCacheWorkflow` uses the new validator to avoid regression when users set `fvm config --flutter-url` to an SSH value.

### Alternative Approaches
- Instead of strict validation, attempt a lightweight `git ls-remote <url>` and catch failures; this delegates validation to git itself.

### Dependencies & Risks
- Avoid false positives: ensure we don’t accept obviously invalid strings (e.g., missing host). Keep `.git` requirement.
- On Windows, colon in path may be tricky; tests should run cross-platform.

## Classification Recommendation
- Priority: **P1 - High** (blocks private fork workflows relying on SSH)
- Suggested Folder: `validated/p1-high/`

## Notes for Follow-up
- After fix, respond to reporter and mention the new release containing support. Document SSH examples in the forks section of the docs.
