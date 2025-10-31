# Issue #799: PathAccessException: ~/.zshrc permission denied

## Metadata
- **Reporter**: @iampato
- **Created**: 2024-11-24
- **Issue Type**: bug (duplicate of #897)
- **URL**: https://github.com/leoafarias/fvm/issues/799

## Summary
Running `fvm` throws `PathAccessException` while accessing `~/.zshrc`. Same root cause as #897 (Home Manager / read-only shell configs).

## Recommendation
Track under #897 (guard shell profile writes). Close as duplicate once fix lands.

## Classification Recommendation
- Folder: `resolved/`
