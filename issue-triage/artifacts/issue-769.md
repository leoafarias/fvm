# Issue #769: `fvm use x.y.z` uses home directory instead of current project directory

## Metadata
- **Reporter**: @bsudhanva
- **Created**: 2024-08-27
- **Issue Type**: support
- **URL**: https://github.com/leoafarias/fvm/issues/769

## Summary
FVM walks up the directory tree to find `.fvmrc`. If one exists in the home directory, that directory is treated as the project root. Removing or relocating the `.fvmrc` fixes the behavior.

## Recommendation
Explain lookup behavior in documentation (already partially covered). Close issue as expected behavior.

## Classification Recommendation
- Folder: `resolved/`
