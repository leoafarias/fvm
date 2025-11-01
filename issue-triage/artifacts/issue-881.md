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
- [ ] Still reproducible
- [x] Already fixed
- [ ] Not applicable to v4.0.0
- [ ] Needs more information

## Resolution
PR #954 (“Support SSH fork URLs”, merged 2025-11-01) relaxed `isValidGitUrl` to accept scp-style and `ssh://` remotes, and the CLI now allows those URLs in both `fvm fork add` and `fvm config --flutter-url`. Unit tests were added with the new formats, and the reporter-confirmed validation passes.

## Recommendation
**Action**: closed  
**Reason**: SSH/scp Git URLs are accepted as of PR #954.
