# Issue #577: [Feature Request] Use the flutter version defined in pubspec.yaml when running `fvm install`

## Metadata
- **Reporter**: Cássio (@cassioso)
- **Created**: 2023-12-01
- **Reported Version**: 3.0.x
- **Issue Type**: enhancement
- **URL**: https://github.com/leoafarias/fvm/issues/577

## Problem Summary
When `fvm install` is invoked without arguments, it only looks at `.fvmrc`. If the project relies on the `environment.flutter` constraint in `pubspec.yaml`, users still need to provide the version manually or create a config file. They’d like FVM to read the pubspec constraint and install the appropriate Flutter version automatically.

## Version Context
- Reported against: 3.0.x
- Current version: v4.0.0
- Version-specific: no — `InstallCommand` still only checks `.fvmrc`.

## Validation Steps
1. Reviewed `lib/src/commands/install_command.dart`; when no argument is provided it calls `project.pinnedVersion`. If null, it throws an error.
2. Confirmed `Project` already exposes `pubspec` via `pubspec_parse`, so we have access to `pubspec.environment['flutter']`.
3. `FlutterReleaseClient` can return release metadata; we can resolve constraints to actual versions.

## Evidence
```
$ sed -n '34,80p' lib/src/commands/install_command.dart
      final project = get<ProjectService>().findAncestor();
      final version = project.pinnedVersion;
      if (version == null) {
        throw const AppException(
          'Please provide a channel or a version, or run'
          ' this command in a Flutter project that has FVM configured.',
        );
      }
```

**Files/Code References:**
- [lib/src/commands/install_command.dart#L34](../lib/src/commands/install_command.dart#L34) – Throws when `.fvmrc` absent.
- [lib/src/models/project_model.dart#L40](../lib/src/models/project_model.dart#L40) – `Project` keeps the parsed pubspec.

## Current Status in v4.0.0
- [x] Still reproducible
- [ ] Already fixed
- [ ] Not applicable to v4.0.0
- [ ] Needs more information
- [ ] Cannot reproduce

## Troubleshooting/Implementation Plan

### Proposed Solution
1. Extend `InstallCommand` to read `project.pubspec?.environment['flutter']` when `.fvmrc` is missing or when a new `--pubspec` flag is passed.
2. Parse the constraint with `VersionConstraint.parse` and resolve it using `FlutterReleaseClient`:
   - If the constraint matches a specific version, install that release.
   - If it’s a range (e.g., `>=3.16.0 <4.0.0`), pick the latest release satisfying the constraint.
   - Handle channel aliases (e.g., `flutter: ">=0.0.0"` should default to stable).
3. Update error handling to provide clear feedback when no release satisfies the constraint (e.g., constraints beyond current stable).
4. Add tests covering exact versions, ranges, and missing constraints.
5. Document the behavior and flag in the install guide.

### Alternative Approaches
- Introduce a dedicated command (`fvm resolve pubspec`) that prints the version, letting users decide whether to install automatically.

### Dependencies & Risks
- Matching constraints to releases requires keeping release metadata updated (already handled by `FlutterReleaseClient`).
- Need to avoid unexpected behavior in projects with very loose constraints; guarding behind a flag (e.g., `--from-pubspec`) may be safer initially.

### Related Code Locations
- [lib/src/services/releases_service/releases_client.dart](../lib/src/services/releases_service/releases_client.dart) – Source of release data.
- [docs/pages/documentation/getting-started/configuration.mdx](../docs/pages/documentation/getting-started/configuration.mdx) – Update instructions.

## Recommendation
**Action**: validate-p2

**Reason**: Improves developer ergonomics by honoring project metadata, but not a critical blocker.

## Notes
- Coordinate with issue #648 (Dart constraint resolution) to share constraint resolution utilities.

---
**Validated by**: Code Agent
**Date**: 2025-10-31
