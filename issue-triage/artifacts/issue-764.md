# Issue #764: [Feature Request] FVM should automatically switch used Flutter version on git checkout

## Metadata
- **Reporter**: @rasmk
- **Created**: 2024-08-23
- **Issue Type**: feature request
- **URL**: https://github.com/conceptadev/fvm/issues/764

## Problem Summary
`.fvm/versions` symlink is recreated on every `fvm use`, removing previous version symlinks. When switching git branches (with .fvmrc committed), the local `.fvm/versions` folder may point to the wrong cached version until `fvm use` reruns.

## Validation Steps
1. Inspected `UpdateProjectReferencesWorkflow` on current `origin/main`.
2. Confirmed `_updateLocalSdkReference` deletes the local versions directory before creating the selected version link.
3. Confirmed `.fvm/flutter_sdk` is recreated as an absolute link to the selected cache directory.

## Evidence
```text
lib/src/workflows/update_project_references.workflow.dart
  project.localVersionsCachePath.dir
    ..deleteIfExists()
    ..createSync(recursive: true);

The current workflow removes prior per-version project links on every use.
```

## Current Status in v4.1.2
- [x] Still reproducible by code inspection
- [ ] Already fixed
- [ ] Needs more information

## Troubleshooting/Implementation Plan
1. Update `UpdateProjectReferencesWorkflow._updateLocalSdkReference` to retain existing version symlinks and only update the symlink for the current version.
2. Ensure `.fvm/flutter_sdk` points to the selected version via relative link (and avoid deleting the entire folder).
3. Add integration tests covering branch switch scenarios.
4. Run the repository manual branch smoke test because this changes project SDK references and `use` behavior.

## Recommendation
- Priority: **P2 - Medium**
- Suggested Folder: `validated/p2-medium/`
