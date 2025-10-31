# Issue #757: [Feature Request] Add support to shorebird

## Metadata
- **Reporter**: @SamuelGadiel
- **Created**: 2024-07-31
- **Reported Version**: n/a (feature request)
- **Issue Type**: enhancement
- **URL**: https://github.com/leoafarias/fvm/issues/757

## Problem Summary
The reporter wants to point FVM at Shorebird’s Flutter fork. They were unsure whether `fvm config --flutter-url` could swap the SDK source, and requested a first-party way to configure alternative repositories.

## Version Context
- Reported against: v3.x
- Current version: v4.0.0
- Version-specific: no
- Reason: FVM already supports custom Git remotes both globally (`fvm config --flutter-url`) and per-project flavors/forks.

## Validation Steps
1. Confirmed `fvm config --flutter-url <git>` updates the global repository URL (`lib/src/services/app_config_service.dart:128-134`, `lib/src/utils/context.dart:149`).
2. Verified docs demonstrate using custom Git remotes and fork aliases (`docs/pages/documentation/guides/basic-commands.mdx:400-434`, `docs/pages/documentation/advanced/custom-version.mdx:96-129`).
3. Checked that Shorebird instructions align with pointing to a custom Git repo—no code changes required.

## Evidence
```
lib/src/services/app_config_service.dart:128-135  // Applies --flutter-url to the persistent config
lib/src/utils/context.dart:149-153               // CLI resolves flutterUrl with fallback to official repo
docs/pages/documentation/guides/basic-commands.mdx:400-434  // Documented config options including --flutter-url
docs/pages/documentation/advanced/custom-version.mdx:96-129 // Detailed example of custom Flutter forks
```

**Files/Code References:**
- [lib/src/services/app_config_service.dart:128](../lib/src/services/app_config_service.dart#L128) – Persists `--flutter-url` option.
- [docs/pages/documentation/advanced/custom-version.mdx:96](../docs/pages/documentation/advanced/custom-version.mdx#L96) – Example of configuring an alternate Flutter repo.

## Current Status in v4.0.0
- [ ] Still reproducible
- [x] Already fixed
- [ ] Not applicable to v4.0.0
- [ ] Needs more information
- [ ] Cannot reproduce

## Troubleshooting/Implementation Plan

### Root Cause Analysis
Feature already exists; confusion stems from lack of explicit Shorebird example in docs.

### Proposed Solution
1. Close the issue with instructions showing how to point `fvm config --flutter-url` at the Shorebird repo and/or add a fork alias.
2. Optionally add a Shorebird example to the custom version docs.

### Alternative Approaches
- Provide shorthand `fvm config --source shorebird` aliases, but current flexibility is broader and already available.

### Dependencies & Risks
- Documentation only.

### Related Code Locations
- [lib/src/services/flutter_service.dart:174-195](../lib/src/services/flutter_service.dart#L174) – Uses the configured URL when cloning/downloads.

## Recommendation
**Action**: resolved  
**Reason**: Custom Flutter repositories are already supported; respond with usage guidance and close.

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
