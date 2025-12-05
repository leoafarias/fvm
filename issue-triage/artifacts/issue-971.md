# Issue #971 - Deep Research Analysis

## Issue Details
- **Number**: #971
- **Title**: `fvm install` erases `updateVscodeSettings`
- **Created**: November 14, 2025
- **Author**: Daniel Luz (@mernen)
- **Status**: CLOSED
- **Resolved**: PR #986 (v4.0.3, Dec 5, 2025)
- **Priority**: P0 - Critical (Data Loss Bug)
- **Labels**: bug

## Problem Summary
Running `fvm install` erases the `updateVscodeSettings` setting from `.fvmrc` and destroys any formatting/comments in `.vscode/settings.json`.

## Root Cause Analysis

### Call Chain
```
InstallCommand
  → UseVersionWorkflow
    → UpdateProjectReferencesWorkflow.call()
      → ProjectService.update()
        → ProjectConfig.copyWith()
```

### The Bug Location

**File**: `lib/src/services/project_service.dart`
**Lines**: 75-79

```dart
final config = currentConfig.copyWith(
  flutter: flutterSdkVersion,
  flavors: mergedFlavors?.isNotEmpty == true ? mergedFlavors : null,
  updateVscodeSettings: updateVscodeSettings,  // ← BUG: passes null
);
```

### Why It Happens

1. `UpdateProjectReferencesWorkflow.call()` (line 143-147) calls `ProjectService.update()` without specifying `updateVscodeSettings`:
   ```dart
   final updatedProject = get<ProjectService>().update(
     project,
     flavors: {if (flavor != null) flavor: version.name},
     flutterSdkVersion: version.name,
     // updateVscodeSettings NOT passed → defaults to null
   );
   ```

2. `ProjectService.update()` passes `null` directly to `copyWith()`:
   ```dart
   updateVscodeSettings: updateVscodeSettings,  // null
   ```

3. The generated `copyWith()` in `config_model.mapper.dart` uses a sentinel value `$none`:
   ```dart
   $R call({Object? updateVscodeSettings = $none, ...}) =>
     $apply(FieldCopyWithData({
       if (updateVscodeSettings != $none)  // null != $none → TRUE
         #updateVscodeSettings: updateVscodeSettings,  // adds null to data
       ...
     }));
   ```

4. When `null` is explicitly passed (not the default `$none`), the condition `updateVscodeSettings != $none` is TRUE, so `null` gets stored, overwriting the existing value.

## Affected Settings (Potentially)

The same pattern may affect these settings if they're not explicitly passed:
- `updateVscodeSettings` ✓ Confirmed affected
- `updateGitIgnore` - Possibly affected
- `updateMelosSettings` - Possibly affected
- `runPubGetOnSdkChanges` - Possibly affected
- `privilegedAccess` - Possibly affected

## Fix

**File**: `lib/src/services/project_service.dart`
**Line**: 78

### Current Code
```dart
final config = currentConfig.copyWith(
  flutter: flutterSdkVersion,
  flavors: mergedFlavors?.isNotEmpty == true ? mergedFlavors : null,
  updateVscodeSettings: updateVscodeSettings,
);
```

### Fixed Code
```dart
final config = currentConfig.copyWith(
  flutter: flutterSdkVersion,
  flavors: mergedFlavors?.isNotEmpty == true ? mergedFlavors : null,
  updateVscodeSettings: updateVscodeSettings ?? currentConfig.updateVscodeSettings,
);
```

### Alternative: Fix All Similar Settings
```dart
final config = currentConfig.copyWith(
  flutter: flutterSdkVersion,
  flavors: mergedFlavors?.isNotEmpty == true ? mergedFlavors : null,
  updateVscodeSettings: updateVscodeSettings ?? currentConfig.updateVscodeSettings,
  updateGitIgnore: updateGitIgnore ?? currentConfig.updateGitIgnore,
  updateMelosSettings: updateMelosSettings ?? currentConfig.updateMelosSettings,
  runPubGetOnSdkChanges: runPubGetOnSdkChanges ?? currentConfig.runPubGetOnSdkChanges,
  privilegedAccess: privilegedAccess ?? currentConfig.privilegedAccess,
);
```

Note: This would require adding parameters for the other settings to the `update()` method signature.

## Reproduction Steps

1. Create a project with `.vscode/settings.json` and FVM configured
2. Add `"updateVscodeSettings": false` to `.fvmrc`
3. Run `fvm install`
4. Check `.fvmrc` - the `updateVscodeSettings` setting is gone

## Impact

- **Severity**: High
- **Type**: Data Loss
- **Users Affected**: Anyone using `updateVscodeSettings: false` in their `.fvmrc`
- **Workaround**: Manually restore the setting after each `fvm install`

## Testing Considerations

1. Add test to verify `updateVscodeSettings` is preserved after `fvm install`
2. Add test to verify `updateVscodeSettings` is preserved after `fvm use`
3. Consider testing other settings for the same issue

## Related Files

- `lib/src/services/project_service.dart` - Fix location
- `lib/src/workflows/update_project_references.workflow.dart` - Caller
- `lib/src/models/config_model.dart` - ProjectConfig definition
- `lib/src/models/config_model.mapper.dart` - Generated copyWith

## Action Items

- [x] Fix `project_service.dart` line 78
- [x] Add unit test for settings preservation
- [x] Consider adding integration test
- [x] Verify other settings aren't affected
- [x] Release in patch version (v4.0.3)

## Timeline

- **Nov 14, 2025**: Issue reported with detailed analysis
- **Dec 5, 2025**: Deep research completed, fix identified
- **Dec 5, 2025**: Fixed via PR #986 using `$merge`, released in v4.0.3
