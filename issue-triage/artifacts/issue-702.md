# Issue #702: [Feature Request] Manage Workspace with multiple projects in VSCode

## Metadata
- **Reporter**: Mobilite dev (@MobiliteDev)
- **Created**: 2024-03-26
- **Reported Version**: FVM 3.x (pre-v4 docs)
- **Issue Type**: feature
- **URL**: https://github.com/leoafarias/fvm/issues/702

## Problem Summary
The reporter wants a VS Code workspace containing multiple Flutter projects—each pinned to a different SDK with FVM—to automatically select the correct SDK per folder. Today, when FVM updates the `.code-workspace` file, the workspace-level `dart.flutterSdkPath` points every folder to whichever project ran `fvm use` last, so the IDE only sees one SDK version.

## Version Context
- Reported against: v3.x integration
- Current version: v4.0.0
- Version-specific: no
- Reason: v4.0.0 still writes a single `dart.flutterSdkPath` into workspace files, so the limitation persists.

## Validation Steps
1. Reviewed `lib/src/workflows/update_vscode_settings.workflow.dart` and confirmed `_updateWorkspaceFiles` replaces the workspace-wide `settings.dart.flutterSdkPath` with the current project’s symlink every time `fvm use` runs.
2. Verified the same workflow already writes folder-level `.vscode/settings.json`, but the workspace-level override takes precedence in multi-root workspaces.
3. Checked the new VS Code guide (`docs/pages/documentation/guides/vscode.mdx`) and noted it doesn’t address multi-root workspaces or warn about the shared workspace setting.

## Evidence
```
$ sed -n '209,240p' lib/src/workflows/update_vscode_settings.workflow.dart
      workspaceSettings['settings'] ??= <String, dynamic>{};
      if (project.pinnedVersion != null) {
        final workspaceDir = p.dirname(workspaceFile.path);
        final sdkPath = _resolveSdkPath(project, relativeTo: workspaceDir);
        workspaceSettings['settings']['dart.flutterSdkPath'] = sdkPath;
      }
      workspaceFile.writeAsStringSync(prettyJson(workspaceSettings));
```

**Files/Code References:**
- [lib/src/workflows/update_vscode_settings.workflow.dart#L209](../lib/src/workflows/update_vscode_settings.workflow.dart#L209) – Sets `dart.flutterSdkPath` at workspace scope, clobbering other folders.
- [docs/pages/documentation/guides/vscode.mdx#L1](../docs/pages/documentation/guides/vscode.mdx#L1) – Current VS Code docs lacking multi-root guidance.

## Current Status in v4.0.0
- [x] Still reproducible
- [ ] Already fixed
- [ ] Not applicable to v4.0.0
- [ ] Needs more information
- [ ] Cannot reproduce

## Troubleshooting/Implementation Plan

### Root Cause Analysis
FVM’s VS Code workflow updates both folder-level settings and any `.code-workspace` file it finds. When multiple FVM-managed projects share one workspace, the shared workspace setting overwrites the per-folder SDK path, forcing every folder to use the same Flutter SDK.

### Proposed Solution
1. Enhance `UpdateVsCodeSettingsWorkflow._updateWorkspaceFiles` to detect multi-root workspaces (more than one folder entry) and skip writing `workspaceSettings['settings']['dart.flutterSdkPath']`, relying on each folder’s `.vscode/settings.json` instead.
2. Alternatively, if the workspace only contains a single FVM-managed folder, continue writing the workspace-level setting for convenience.
3. Add a docs section to `docs/pages/documentation/guides/vscode.mdx` explaining how multi-root workspaces behave, recommending separate folder settings or the upcoming `dart.getFlutterSdkCommand` integration once #821 lands.
4. Add regression tests (unit or integration) ensuring workspaces with multiple folders no longer override per-folder SDK paths. Mock the workflow with a synthetic workspace JSON containing two folder entries pointing at different pinned versions.

### Alternative Approaches (if applicable)
- Implement `dart.getFlutterSdkCommand` support (issue #821) so VS Code resolves the SDK dynamically per folder, eliminating manual path management. This is more flexible but requires additional tooling work.
- Provide a CLI flag to disable workspace updates (`fvm config`) so teams managing multi-root workspaces can opt out today.

### Dependencies & Risks
- Needs careful parsing of `.code-workspace` files; existing JSON-with-comments parser already in use.
- Must ensure skipping the workspace setting doesn’t regress single-folder workspaces.
- Documentation update should avoid conflicting guidance once the command-based integration ships.

### Related Code Locations
- [lib/src/workflows/update_vscode_settings.workflow.dart#L130](../lib/src/workflows/update_vscode_settings.workflow.dart#L130) – Folder-level settings update that should remain authoritative.
- [lib/src/workflows/update_vscode_settings.workflow.dart#L259](../lib/src/workflows/update_vscode_settings.workflow.dart#L259) – Workflow entry point where detection logic can branch.

## Recommendation
**Action**: validate-p2

**Reason**: Multi-project VS Code workspaces are common and the current behavior breaks expected tooling, but it’s a tooling convenience rather than a hard blocker (P2).

## Notes
- Coordinate with issue #821 so both efforts converge on a long-term VS Code integration story.

---
**Validated by**: Code Agent
**Date**: 2025-10-31
