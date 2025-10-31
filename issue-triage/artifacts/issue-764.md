# Issue #764: [Feature Request] FVM should automatically switch used Flutter version on git checkout

## Metadata
- **Reporter**: @rasmk
- **Created**: 2024-08-23
- **Issue Type**: feature request
- **URL**: https://github.com/leoafarias/fvm/issues/764

## Problem Summary
`.fvm/versions` symlink is recreated on every `fvm use`, removing previous version symlinks. When switching git branches (with .fvmrc committed), the local `.fvm/versions` folder may point to the wrong cached version until `fvm use` reruns.

## Proposed Solution
1. Update `UpdateProjectReferencesWorkflow._updateLocalSdkReference` to retain existing version symlinks and only update the symlink for the current version.
2. Ensure `.fvm/flutter_sdk` points to the selected version via relative link (and avoid deleting the entire folder).
3. Add integration tests covering branch switch scenarios.

## Classification Recommendation
- Priority: **P2 - Medium**
- Suggested Folder: `validated/p2-medium/`
