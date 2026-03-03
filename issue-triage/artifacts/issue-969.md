# Issue #969: [BUG] RISC-V: Download the right dart SDK (and engine ?) for real RISC-V support

## Metadata
- **Reporter**: @vhaudiquet
- **Created**: 2025-11-12
- **Reported Version**: 4.0.1
- **Issue Type**: bug / platform support gap
- **URL**: https://github.com/leoafarias/fvm/issues/969

## Problem Summary
On Linux RISC-V, running setup after install downloads an `arm64` Dart SDK, causing runtime failure (`Exec format error`). Reporter later noted the download decision appears to happen inside Flutter tooling, not directly in FVM.

## Version Context
- Reported against: v4.0.1
- Current version: v4.0.0+
- Version-specific: no
- Reason: architecture behavior depends on Flutter toolchain support, and FVM currently delegates setup to Flutter itself.

## Validation Steps
1. Reviewed setup execution path in FVM.
2. Reviewed release/install architecture handling paths in repository.
3. Reviewed issue thread updates indicating upstream Flutter tooling behavior.

## Evidence
```text
lib/src/services/flutter_service.dart:126-128
- Setup is delegated to `flutter --version` inside installed SDK.

scripts/install.sh:242-251
- Installer script still hard-codes x64/arm64 architecture mapping.

lib/src/services/releases_service/models/flutter_releases_model.dart:76-101
- Release filtering uses fixed `systemArch = 'x64'` and only applies arch filtering on macOS.
```

**Files/Code References:**
- [lib/src/services/flutter_service.dart:126](../lib/src/services/flutter_service.dart#L126) - Delegated setup call.
- [scripts/install.sh:242](../scripts/install.sh#L242) - Current architecture mapping in installer script.
- [lib/src/services/releases_service/models/flutter_releases_model.dart:76](../lib/src/services/releases_service/models/flutter_releases_model.dart#L76) - Architecture filtering assumptions.

## Current Status in v4.0.0
- [x] Still reproducible (for RISC-V environments)
- [ ] Already fixed
- [ ] Not applicable to v4.0.0
- [ ] Needs more information
- [ ] Cannot reproduce

## Troubleshooting/Implementation Plan

### Root Cause Analysis
FVM can install/use a RISC-V FVM binary, but SDK setup remains dependent on Flutter tooling behavior for that architecture. Current repo code also has architecture assumptions in installer/release parsing paths that can confuse the support story.

### Proposed Solution
1. Add explicit guardrails when running on RISC-V: if setup output indicates architecture mismatch (`Exec format error`), show a dedicated message that Flutter engine/tooling support is currently limited.
2. Update docs to separate "FVM binary availability" from "Flutter SDK/engine availability" on RISC-V.
3. Align installer/release architecture handling to avoid conflicting signals (for example, support matrix and script logic should match published artifacts).
4. Add a regression test for architecture detection/parsing behavior in release metadata.

### Alternative Approaches (if applicable)
- Mark RISC-V as experimental with a prominent warning instead of attempting automatic workarounds.

### Dependencies & Risks
- Final fix depends on upstream Flutter engine/toolchain availability for RISC-V.
- Over-promising support without engine binaries will increase support noise.

### Related Code Locations
- [docs/pages/documentation/getting-started/installation.mdx](../docs/pages/documentation/getting-started/installation.mdx) - Support matrix should match actual behavior.
- [docs/public/install.sh](../docs/public/install.sh) - Public script mirror needs to stay in sync with `scripts/install.sh`.

## Recommendation
**Action**: validate-p3

**Reason**: Real user impact on a niche platform, but mostly upstream/toolchain constrained; prioritize documentation and guardrails over core logic changes.

## Notes
- Reporter explicitly acknowledged this may be upstream Flutter behavior and invited close/wontfix if FVM scope remains limited.

---
**Validated by**: Code Agent  
**Date**: 2026-03-03
