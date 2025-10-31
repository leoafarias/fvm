# Issue #696: [Feature Request] Specify path for .fvm directory

## Metadata
- **Reporter**: Jonah Walker (@supposedlysam-bb)
- **Created**: 2024-03-21
- **Reported Version**: FVM 2.x / 3.x
- **Issue Type**: feature
- **URL**: https://github.com/leoafarias/fvm/issues/696

## Problem Summary
Debuggers and CLI tools recurse into the `.fvm` folder because it sits inside the project root. The reporter wants to move `.fvm/` elsewhere (for example, the workspace root) so IDE breakpoints and linters ignore Flutter sources without additional filters.

## Version Context
- Reported against: legacy versions 2.x–3.x
- Current version: v4.0.0
- Version-specific: no
- Reason: v4 still hardcodes `.fvm` to `project/.fvm`, so the limitation persists.

## Validation Steps
1. Reviewed `Project.localFvmPath` and `localVersionsCachePath`, which currently always join the project path with `.fvm`, ignoring any config overrides.
2. Confirmed `ProjectConfig` already exposes a `cachePath` field in `.fvmrc`, but the runtime code never uses it to customize the local `.fvm` directory.
3. Checked the configuration docs; they describe `.fvm` contents but offer no guidance for relocating it, leaving users without an official workaround.

## Evidence
```
$ sed -n '98,116p' lib/src/models/project_model.dart
  @MappableField()
  String get localFvmPath => _fvmPath(path);
  @MappableField()
  String get localVersionsCachePath {
    return join(_fvmPath(path), 'versions');
  }

$ sed -n '20,48p' docs/pages/documentation/getting-started/configuration.mdx
There are two main parts...
### Config File `.fvmrc`
...
-  `cachePath`: Defines the path to the project's cache directory.  ← documented but unused.
```

**Files/Code References:**
- [lib/src/models/project_model.dart#L98](../lib/src/models/project_model.dart#L98) – Hardcodes `.fvm` relative to the project root.
- [docs/pages/documentation/getting-started/configuration.mdx#L20](../docs/pages/documentation/getting-started/configuration.mdx#L20) – Documents a `cachePath` option that should enable this feature but currently doesn’t.

## Current Status in v4.0.0
- [x] Still reproducible
- [ ] Already fixed
- [ ] Not applicable to v4.0.0
- [ ] Needs more information
- [ ] Cannot reproduce

## Troubleshooting/Implementation Plan

### Root Cause Analysis
The `Project` model ignores the `cachePath` override in `.fvmrc`, so every workflow assumes `.fvm` lives under the project directory. Tools therefore crawl into `.fvm/flutter_sdk`, triggering debugger noise and recursive CLI behaviors.

### Proposed Solution
1. Update `Project.localFvmPath` (and derived getters such as `localVersionsCachePath`, `localVersionSymlinkPath`) to honor `config?.cachePath`. Accept both absolute and relative values; resolve relative paths against `project.path`.
2. Audit all uses of `_fvmPath(path)` (e.g., `UpdateProjectReferencesWorkflow`, `update_melos_settings.workflow.dart`) to ensure they rely on the computed getters and not hardcoded paths.
3. Extend unit tests for `Project` to cover absolute and relative overrides, verifying `localFvmPath.dir` creates directories in the expected location.
4. Update `docs/pages/documentation/getting-started/configuration.mdx` with an example `.fvmrc` showing `"cachePath": "../workspace/.fvm"` and clarify debugger use cases.
5. (Optional) Add a guard that prevents `cachePath` from pointing inside the system Flutter cache directory, and emit a warning if two projects resolve to the same `.fvm` path to avoid accidental sharing.

### Alternative Approaches (if applicable)
- Introduce a new explicit property (e.g., `localFvmPath`) instead of reusing `cachePath`. This makes intent clearer but requires schema and migration updates.
- Provide a CLI flag (`fvm config --cache-path`) to set the override without editing `.fvmrc`; could be layered on top once core support lands.

### Dependencies & Risks
- Must ensure VS Code and Melos workflows respect the new path; they already go through `project.localFvmPath`, so regression risk is low if getters are updated.
- Sharing one `.fvm` directory across multiple projects could introduce race conditions when switching versions; document best practices and consider future locking.

### Related Code Locations
- [lib/src/workflows/update_project_references.workflow.dart#L26](../lib/src/workflows/update_project_references.workflow.dart#L26) – Creates `.fvm` contents; should work transparently once `localFvmPath` is configurable.
- [lib/src/workflows/update_vscode_settings.workflow.dart#L131](../lib/src/workflows/update_vscode_settings.workflow.dart#L131) – Reads `.fvm/flutter_sdk`; relies on the same getters.

## Recommendation
**Action**: validate-p2

**Reason**: Quality-of-life enhancement affecting debugging and automation. Medium priority because the current behavior is functional but obstructive for IDE workflows.

## Notes
- Coordinate messaging with issue #743/#821 so VS Code docs reflect both workspace behavior and configurable `.fvm` locations.

---
**Validated by**: Code Agent
**Date**: 2025-10-31
