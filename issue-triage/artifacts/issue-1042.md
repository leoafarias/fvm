# Issue #1042: [Feature Request] Support to Flutter-Tizen, Flutter-TVOS and future custom SDK

## Metadata
- **Reporter**: @deandreamatias
- **Created**: 2026-06-19
- **Reported Version**: N/A (feature request)
- **Issue Type**: feature / architecture
- **URL**: https://github.com/leoafarias/fvm/issues/1042

## Problem Summary
Reporter wants FVM to manage non-standard Flutter SDK families such as Flutter-Tizen, Flutter-TVOS, and future platform-specific SDKs. The suggested `.fvmrc` shape includes multiple SDK keys, for example `flutter` and `flutter-tizen`, so a project can pin more than one SDK family.

## Version Context
- Reported against: current FVM behavior
- Current version: v4.x
- Version-specific: no
- Reason: existing custom repository support can target one Flutter fork/ref at a time, but FVM does not model multiple SDK families in a single project config.

## 2026-06-22 Urgency Review
- Issue was created on 2026-06-19, after the FVM 4.1.1 release on 2026-06-16.
- It is labeled as an enhancement and does not report a 4.1.1 regression.
- Current FVM supports registered Flutter forks and `[fork/]version[@channel]`, but does not support multiple SDK-family keys or alternate SDK executables as first-class project config.
- Classification remains P2 valid enhancement/design work, not urgent.

## Validation Steps
1. Reviewed current config model.
2. Reviewed existing fork alias command.
3. Reviewed current project SDK path behavior.
4. Reviewed custom-version documentation.

## Evidence
```text
lib/src/models/config_model.dart:15-23: ConfigOptions includes cachePath, useGitCache, gitCachePath, and flutterUrl only.
lib/src/models/config_model.dart:127-147: AppConfig stores a Set<FlutterFork>, not arbitrary SDK families.
lib/src/commands/fork_command.dart:9-18: fork aliases support custom Flutter repositories via alias/version.
lib/src/models/project_model.dart:112-120: project SDK path is derived from one pinned Flutter version/fork.
docs/pages/documentation/advanced/custom-version.mdx:88-124: docs cover changing the Flutter repository URL, not parallel SDK families.
```

**Files/Code References:**
- [../../lib/src/models/config_model.dart](../../lib/src/models/config_model.dart) - config model and fork definitions.
- [../../lib/src/commands/fork_command.dart](../../lib/src/commands/fork_command.dart) - current custom repository workflow.
- [../../lib/src/models/project_model.dart](../../lib/src/models/project_model.dart) - one local Flutter SDK path model.
- [../../docs/pages/documentation/advanced/custom-version.mdx](../../docs/pages/documentation/advanced/custom-version.mdx) - current custom SDK docs.

## Current Status in v4.x
- [x] Still reproducible
- [ ] Already fixed
- [ ] Not applicable to v4.x
- [ ] Needs more information
- [ ] Cannot reproduce

## Troubleshooting/Implementation Plan

### Root Cause Analysis
FVM models "the Flutter SDK" as a single SDK family with optional fork aliases and one pinned project version. That works for custom repositories like `fork/stable`, but it does not support project configs that pin multiple SDK families such as official Flutter plus Flutter-Tizen or Flutter-TVOS at the same time.

### Proposed Solution
1. Start with a design/spec before coding. This needs a clear contract for SDK families, cache namespaces, project config shape, CLI UX, and backward compatibility.
2. Evaluate whether current fork aliases are sufficient for single-family custom SDK usage, and document that as the current workaround.
3. Design a future project config shape. Prefer an explicit map such as `sdks` over arbitrary top-level `.fvmrc` keys to avoid config collisions:
   ```json
   {
     "flutter": "stable",
     "sdks": {
       "flutter-tizen": "stable",
       "flutter-tvos": "stable"
     }
   }
   ```
4. Define cache layout and project references for multiple SDK families, such as `.fvm/sdks/<family>/<version>` or another namespaced structure.
5. Define command UX, for example `fvm use --sdk flutter-tizen stable`, `fvm sdk add`, or a dedicated SDK-family command group.
6. Add tests covering config parsing, SDK-family validation, cache path isolation, project reference updates, and migration from existing `.fvmrc` files.
7. Update docs to distinguish:
   - custom Flutter fork aliases already supported today
   - multi-SDK-family management proposed by #1042

### Alternative Approaches
- Close as already partially supported by `fvm fork add` if the maintainers only want one custom SDK family at a time.
- Implement docs-only guidance for Flutter-Tizen/TVOS using existing fork aliases, without adding multi-SDK project config.

### Dependencies & Risks
- Multi-SDK support affects config compatibility, cache layout, command semantics, IDE integration, and generated project references.
- Arbitrary top-level `.fvmrc` keys could conflict with future config fields.
- Platform-specific SDKs may not share official Flutter release metadata behavior.

### Related Code Locations
- [../../lib/src/models/flutter_version_model.dart](../../lib/src/models/flutter_version_model.dart) - version/fork parsing.
- [../../lib/src/workflows/validate_flutter_version.workflow.dart](../../lib/src/workflows/validate_flutter_version.workflow.dart) - fork validation.
- [../../lib/src/services/flutter_service.dart](../../lib/src/services/flutter_service.dart) - install path selection and fork URL usage.

## Recommendation
**Action**: validate-p2

**Reason**: Valid architecture enhancement with existing partial workaround through fork aliases. It should be planned deliberately before implementation because it changes FVM's project configuration model and cache/reference assumptions.

## Notes
This overlaps conceptually with #1009 and #757, but #1042 is broader: it asks for multiple named SDK families in one project, not only a custom Flutter fork URL.

---
**Validated by**: Code Agent
**Date**: 2026-06-19
