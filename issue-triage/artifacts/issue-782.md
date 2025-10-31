# Issue #782: `Bad substitution` when rerouting flutter/dart commands

## Metadata
- **Reporter**: @dickermoshe
- **Created**: 2024-09-16
- **Issue Type**: documentation bug
- **URL**: https://github.com/leoafarias/fvm/issues/782

## Summary
Docs instruct creating shims with `fvm flutter ${@:1}`. On Linux, scripts run with `/bin/sh`, which doesn’t support `${@:1}`, causing `Bad substitution`.

## Fix Plan
Update docs to use `fvm flutter "$@"` (POSIX) and ensure shebang/permissions if needed.

## Classification Recommendation
- Folder: `resolved/`
