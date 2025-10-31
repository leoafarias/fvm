# Issue #774: dart: command not found error while using rps package

## Metadata
- **Reporter**: @msarkrish
- **Created**: 2024-08-30
- **Issue Type**: support/documentation
- **URL**: https://github.com/leoafarias/fvm/issues/774

## Summary
`rps` global script invokes `dart` from PATH. Without adding FVM’s `~/.fvm/default/bin` to PATH, `dart` is unresolved.

## Resolution
Documented approach: run `fvm global <version>` and add `~/.fvm/default/bin` to PATH (or configure per-project `.fvm/flutter_sdk/bin`). Then `rps` will find `dart`.

## Classification Recommendation
- Folder: `resolved/`
