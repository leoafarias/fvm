# Issue #1047: [Feature Request] Support Windows on arm64

## Metadata
- **Reporter**: cmpbedes
- **Created**: 2026-07-03
- **Reported Version**: Not specified (Flutter 3.44+ arm support context)
- **Issue Type**: feature / platform support
- **URL**: https://github.com/conceptadev/fvm/issues/1047

## Problem Summary
On Windows 11 arm64, the reporter believes FVM is only available as x64, and using FVM installs an x64 Flutter SDK rather than arm64. They want native windows-arm64 FVM binaries and correct Flutter SDK architecture selection so they can drop x64 emulation.

## Version Context
- Reported against: post–Flutter 3.44 Windows arm tooling era
- Current FVM release checked: **4.1.2**
- Version-specific: no
- Reason: Platform gap / incomplete install path, not a v3-only issue.

## Validation Steps
1. Listed GitHub release assets for `4.1.2`: **`fvm-4.1.2-windows-arm64.zip` already exists** alongside `windows-x64`.
2. Inspected `scripts/install.ps1`: architecture detection is only `x64`/`x86`; download URL **hardcodes** `$OS-x64.zip` and ignores detected `$ARCH`.
3. Inspected Flutter `releases_windows.json`: **no arm64 entries** (only `x64` / null). Official archive metadata is still x64-only for Windows.
4. Inspected FVM arch filtering in `flutter_releases_model.dart`: **macOS-only** filtering by `dart_sdk_arch`; Windows has no equivalent filter (and Flutter does not publish multi-arch windows releases in that JSON today).
5. FVM installs primarily via **git clone**, not Windows zip archives; host arch for Dart/engine is decided later by Flutter tooling during setup — often influenced by whether FVM/Dart itself is running as arm64 or x64 (emulated).
6. Rechecked GitHub on 2026-07-23: PR #1049 merged successfully on 2026-07-18, the Windows ARM64 smoke workflow passed on a `windows-11-arm` runner, and issue #1047 was closed as completed. Remaining package-manager delivery is tracked separately in #1050.

## Evidence
```
# Release assets (4.1.2)
fvm-4.1.2-windows-arm64.zip   # ALREADY SHIPPED
fvm-4.1.2-windows-x64.zip

# scripts/install.ps1
$ARCH = if ([Environment]::Is64BitOperatingSystem) { 'x64' } else { 'x86' }
$URL = ".../fvm-$FVM_VERSION-$OS-x64.zip"   # hard-coded x64

# lib/.../flutter_releases_model.dart
if (Platform.isMacOS && systemArch != null) { /* filter dart_sdk_arch */ }
# Windows: no arch filter; releases_windows.json has no arm entries

# Live GitHub status, rechecked 2026-07-23
PR #1049: MERGED (2026-07-18)
Issue #1047: CLOSED / COMPLETED
Windows ARM64 smoke: PASS
```

**Files/Code References:**
- [scripts/install.ps1:45](../../scripts/install.ps1#L45) – incomplete arch detection
- [scripts/install.ps1:73](../../scripts/install.ps1#L73) – hardcoded x64 asset URL
- [lib/src/services/releases_service/models/flutter_releases_model.dart:113](../../lib/src/services/releases_service/models/flutter_releases_model.dart#L113) – macOS-only arch filter
- [docs/public/install.sh](../../docs/public/install.sh) – reference for proper arch detection (Unix)

## Current Status in v4.0.0 / 4.1.x
- [ ] Still reproducible
- [x] Already fixed
- [ ] Not applicable to v4.0.0
- [ ] Needs more information
- [ ] Cannot reproduce

## Troubleshooting/Implementation Plan
**IMPORTANT**: Research and plan only — do not implement during triage.

### Root Cause Analysis
Two separate concerns are conflated:

1. **FVM CLI binary on Windows arm64**  
   Native assets are already built and published (`windows-arm64.zip`), but `install.ps1` (and likely docs/Chocolatey/Winget paths) always install **x64**, so users land on emulated FVM.

2. **Flutter SDK architecture**  
   FVM clones the Flutter git repo (arch-agnostic). Engine/Dart SDK architecture comes from Flutter’s own first-run download. Official `releases_windows.json` still lists only x64 archives. On an emulated x64 FVM/Dart host, Flutter is very likely to pull x64 tooling. Native arm64 FVM may improve this; archive-based installs cannot select arm64 until Flutter publishes it.

### Proposed Solution
1. **Fix `scripts/install.ps1`**
   - Detect ARM64 (e.g. `PROCESSOR_ARCHITECTURE` / `PROCESSOR_IDENTIFIER` / `RuntimeInformation.OSArchitecture`).
   - Map to `arm64` vs `x64` vs `x86`.
   - Build URL with `$OS-$ARCH.zip`, fall back to x64 with a clear warning if arm64 asset missing.
2. **Docs**: Windows arm64 install section — prefer release asset `windows-arm64`, note that `install.ps1` must be updated, document verification (`fvm --version`, process architecture).
3. **Verify Flutter SDK under native arm64 FVM**
   - On Windows arm64 device/VM: install arm64 FVM, `fvm install stable`, run `fvm flutter doctor -v`, confirm Dart/Flutter host arch.
   - If Flutter still downloads x64: document as upstream limitation until Flutter ships windows-arm64 release metadata; FVM cannot invent archives.
4. **Optional**: extend `_currentSystemArch()` for Windows when multi-arch windows releases appear (mirror macOS filter).
5. **Packaging follow-ups**: ensure Chocolatey/Winget (#826) and any release notes mention windows-arm64; fvm_mcp still documents windows-x64 only.
6. **Tests**: PowerShell arch unit/smoke similar to `scripts/test-install-arch.sh` for Unix.

### Alternative Approaches
- Tell users to manually download `fvm-*-windows-arm64.zip` today — works for the binary gap without a release.
- Continue under x64 emulation — functional but not what reporter wants.

### Dependencies & Risks
- Hardcoding wrong arch detection on WoA devices (x64 process under emulation vs native ARM OS).
- Over-promising Flutter native arm64 if upstream archives remain x64-only.
- Winget/Chocolatey matrix expansion.

### Related Code Locations
- [scripts/install.ps1](../../scripts/install.ps1)
- [lib/src/services/releases_service/models/flutter_releases_model.dart](../../lib/src/services/releases_service/models/flutter_releases_model.dart)
- [issue-triage issue #826](../validated/p2-medium/issue-826.json) – Winget packaging
- Related: Linux/macOS arm already supported in install.sh and release matrix

## Recommendation
**Action**: resolved  
**Reason**: PR #1049 closed the reported discoverability and native-runtime validation gaps. Native Windows ARM64 release assets are documented and smoke-tested; the remaining Winget/Chocolatey architecture work is a separate P2 enhancement in #1050.

## Notes
- Do not close as “already shipped” solely because `windows-arm64.zip` exists — install path still forces x64.
- Reply should point users at the arm64 release zip as a temporary workaround.
- Confirm with reporter whether they installed via `install.ps1`, Scoop, Chocolatey, or manual zip.
- **Closure update (2026-07-23):** #1047 is now closed as completed. The original triage notes above describe the pre-#1049 state; package-manager delivery moved to #1050.
