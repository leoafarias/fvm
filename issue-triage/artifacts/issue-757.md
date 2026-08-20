# Issue #757: [Feature Request] Add support to shorebird

## Metadata
- **Reporter**: @SamuelGadiel
- **Created**: 2024-07-31
- **Reported Version**: n/a (feature request)
- **Issue Type**: enhancement
- **URL**: https://github.com/conceptadev/fvm/issues/757

## Problem Summary
The reporter wants to point FVM at Shorebird’s Flutter fork. They were unsure whether `fvm config --flutter-url` could swap the SDK source, and requested a first-party way to configure alternative repositories.

## Version Context
- Reported against: v3.x
- Current version: v4.1.2
- Version-specific: no
- Reason: FVM already supports custom Git remotes both globally (`fvm config --flutter-url`) and per-project flavors/forks.

## Validation Steps
1. Confirmed `fvm config --flutter-url <git>` updates the global repository URL (`lib/src/services/app_config_service.dart:128-134`, `lib/src/utils/context.dart:149`).
2. Verified docs demonstrate using custom Git remotes and fork aliases (`docs/pages/documentation/guides/basic-commands.mdx:400-434`, `docs/pages/documentation/advanced/custom-version.mdx:96-129`).
3. Re-read the issue discussion: Shorebird releases its own CLI and manages modified Flutter SDK binaries/directories; it is not merely a Flutter Git remote.
4. Correlated with #1042, where an alternate SDK executable also breaks FVM's standard-`flutter` assumptions.

## Evidence
```
lib/src/services/app_config_service.dart:128-135  // Applies --flutter-url to the persistent config
lib/src/utils/context.dart:149-153               // CLI resolves flutterUrl with fallback to official repo
docs/pages/documentation/guides/basic-commands.mdx:400-434  // Documented config options including --flutter-url
docs/pages/documentation/advanced/custom-version.mdx:96-129 // Detailed example of custom Flutter forks
```

**Files/Code References:**
- [lib/src/services/app_config_service.dart:128](../../lib/src/services/app_config_service.dart#L128) – Persists `--flutter-url` option.
- [docs/pages/documentation/advanced/custom-version.mdx:96](../../docs/pages/documentation/advanced/custom-version.mdx#L96) – Example of configuring an alternate Flutter repo.

## Current Status in v4.1.2
- [x] Still unresolved as a first-class Shorebird integration
- [ ] Already fixed
- [ ] Not applicable to v4.0.0
- [ ] Needs more information
- [ ] Cannot reproduce

## Troubleshooting/Implementation Plan

### Root Cause Analysis
Generic Flutter Git forks are supported, but Shorebird owns a separate CLI, distribution flow, modified SDK binaries, and cache layout. `--flutter-url` cannot point at a releases page or make Shorebird consume an FVM-managed SDK automatically.

### Proposed Solution
1. Document that `--flutter-url` expects a Flutter-compatible Git repository, not a release page or third-party CLI distribution.
2. Define whether FVM wants to manage external SDK families/providers at all; coordinate this decision with #1042.
3. If supported, design a provider contract for download metadata, executable names, cache paths, setup, and version detection rather than hard-coding Shorebird.
4. If out of scope, close with explicit rationale and point users to Shorebird's own SDK management.

### Alternative Approaches
- Provide shorthand `fvm config --source shorebird` aliases, but current flexibility is broader and already available.

### Dependencies & Risks
- Documentation only.

### Related Code Locations
- [lib/src/services/flutter_service.dart:174-195](../../lib/src/services/flutter_service.dart#L174) – Uses the configured URL when cloning/downloads.

## Recommendation
**Action**: validate-p3
**Reason**: Generic forks do not fully solve Shorebird's separate CLI/SDK distribution lifecycle. This is valid ecosystem design work, but not core FVM urgency.

## Draft Reply
```
Appreciate the suggestion! FVM can already target Shorebird (or any other Flutter fork).

Global override:
```bash
fvm config --flutter-url https://github.com/shorebirdtech/shorebird.git
```

Per-project/fork workflow:
```bash
fvm fork add shorebird https://github.com/shorebirdtech/shorebird.git
fvm use shorebird/stable
```

Docs for reference:
- Config command options: https://fvm.app/documentation/guides/basic-commands#config
- Custom versions guide: https://fvm.app/documentation/advanced/custom-version

Because the feature is already available I’m going to close the issue, but let us know if you hit any problems using the Shorebird repo.
```

## Notes
- Consider adding a Shorebird example to the custom versions doc during the next docs pass.

---
**Validated by**: Code Agent  
**Date**: 2025-10-31
