# Issue #1050: Windows: deliver native arm64 builds through package managers (winget, Chocolatey)

## Metadata
- **Reporter**: leoafarias
- **Created**: 2026-07-18
- **Reported Version**: FVM 4.0.5+
- **Issue Type**: enhancement / distribution
- **URL**: https://github.com/conceptadev/fvm/issues/1050

## Problem Summary
FVM publishes native Windows ARM64 release archives, but the promoted package-manager path is not architecture-aware. Chocolatey compiles FVM during installation with an x64 Dart SDK, so Windows ARM64 users receive an emulated x64 process. That can also lead Flutter's setup process to select x64 SDK artifacts. The requested outcome is native ARM64 delivery through Winget and/or an architecture-aware Chocolatey package.

## Version Context
- Reported against: FVM 4.0.5+ release packaging
- Current release context: FVM 4.1.2
- Version-specific: no
- Reason: this is an ongoing Windows distribution gap, not a v3-only behavior.

## Validation Steps
1. Confirmed issue #1047 is closed as completed after PR #1049 documented and smoke-tested the existing native Windows ARM64 GitHub release archive.
2. Confirmed PR #1049 merged on 2026-07-18 with successful CLI tests and a passing native Windows ARM64 smoke run.
3. Inspected the checked-out release workflow: Windows publishing still delegates GitHub and Chocolatey packaging to `cli_pkg`; there is no Winget publish step.
4. Inspected the installation documentation in this checkout: Chocolatey remains the package-manager path and no Winget command is present. The live docs changes from PR #1049 cover manual native archives, not package-manager delivery.
5. Compared open issue #826: it already tracks general Winget availability. Issue #1050 is the architecture-specific continuation and also covers replacing Chocolatey's compile-from-source behavior.
6. Rechecked the full live issue queue on 2026-07-23. There are no P0 issues; #688 is the only P1. Native ARM64 users have a documented manual archive path, so #1050 is not a complete installation blocker.

## Evidence
```text
GitHub issue #1047: CLOSED / COMPLETED
GitHub PR #1049: MERGED 2026-07-18
Windows ARM64 smoke run: PASS on windows-11-arm

.github/workflows/release.yml:
  pkg-github-windows
  pkg-chocolatey-deploy
  # no Winget publish step

tool/release_tool/pubspec.yaml:
  cli_pkg: 2.14.0

Open overlap:
  #826 - Add package to Winget
  #1050 - Native arm64 package-manager delivery
```

**Files/Code References:**
- [.github/workflows/release.yml](../../.github/workflows/release.yml) - Windows GitHub/Chocolatey release jobs; no Winget delivery.
- [tool/release_tool/tool/grind.dart](../../tool/release_tool/tool/grind.dart) - delegates release packaging to `cli_pkg`.
- [tool/release_tool/pubspec.yaml](../../tool/release_tool/pubspec.yaml) - pins the packaging dependency.
- [docs/pages/documentation/getting-started/installation.mdx](../../docs/pages/documentation/getting-started/installation.mdx) - Windows installation documentation.
- [issue #826 artifact](issue-826.md) - existing general Winget distribution plan.
- [issue #1047 artifact](issue-1047.md) - completed native Windows ARM64 binary/discoverability work.

## Current Status in v4.0.0 / 4.1.x
- [x] Still reproducible
- [ ] Already fixed
- [ ] Not applicable to v4.0.0
- [ ] Needs more information
- [ ] Cannot reproduce

## Troubleshooting/Implementation Plan

### Root Cause Analysis
The Windows release pipeline has two paths with different architecture behavior:

1. GitHub Releases already contain native x64 and ARM64 archives.
2. Chocolatey's `cli_pkg` flow compiles at install time using the Dart SDK available to Chocolatey. On Windows ARM64 that SDK is x64, so the resulting FVM process runs under emulation.

FVM does not publish Winget manifests, so Windows cannot automatically choose the existing release archive that matches the host architecture. Once FVM runs as x64, Flutter's own architecture detection can inherit the emulated `AMD64` process environment and install x64 components.

### Proposed Solution
1. Consolidate #826 and #1050 into one delivery workstream while retaining #1050 as the ARM64 acceptance criteria.
2. Prefer Winget as the first implementation:
   - Create portable installer manifests for both `x64` and `arm64`.
   - Point each architecture entry at the matching GitHub release archive.
   - Record release SHA-256 values and validate manifests with Winget tooling.
3. Add release automation after GitHub artifacts are available:
   - Generate or update Winget manifests for the new version.
   - Submit a PR to `microsoft/winget-pkgs`.
   - Make submission failures visible without invalidating already-published GitHub assets.
4. Update Windows installation docs with Winget commands and explain that Winget selects the native architecture.
5. Decide whether Chocolatey remains compile-from-source or becomes archive-based:
   - Preferred: download the matching, already-published FVM archive using reliable native-OS architecture detection.
   - If retained as compile-from-source, explicitly document that Windows ARM64 receives x64 emulation until Chocolatey provides a native Dart toolchain.
6. Extend `.github/workflows/windows-arm64-smoke.yml` on current `main`:
   - Install FVM through the candidate package-manager path on `windows-11-arm`.
   - Verify the PE machine type of the executed Dart/FVM runtime is ARM64.
   - Run `fvm --version`.
   - Install a Flutter version with Windows ARM64 support and verify `fvm flutter doctor -v` reports the expected architecture.
7. Close #826 and #1050 only after the package-manager manifest is accepted, the smoke test passes, and documentation points users to the native path.

### Alternative Approaches
- Keep manual GitHub archive installation as the documented workaround. This is functional today but does not provide package-manager updates.
- Make Chocolatey archive-based first. This preserves the existing package name but requires careful host-architecture detection and changes to the current `cli_pkg` delivery model.

### Dependencies & Risks
- Winget community-repository review can delay release availability.
- Chocolatey may expose x64 process environment variables on ARM64, so architecture detection must identify the native OS rather than the current emulated process.
- GitHub artifacts must exist before package manifests can calculate stable URLs and checksums.
- Older Flutter releases may remain x64-only even when FVM itself runs natively.
- #826 and #1050 can drift or duplicate effort unless one issue is named as the canonical implementation tracker.

### Related Code Locations
- [.github/workflows/release.yml](../../.github/workflows/release.yml)
- [.github/workflows/deploy_windows.yml](../../.github/workflows/deploy_windows.yml)
- [tool/release_tool/tool/grind.dart](../../tool/release_tool/tool/grind.dart)
- [docs/pages/documentation/getting-started/installation.mdx](../../docs/pages/documentation/getting-started/installation.mdx)

## Recommendation
**Action**: validate-p2

**Reason**: This is a real native-distribution gap with a clear implementation path, but it is not an urgent installation outage because native Windows ARM64 archives are already published, documented, and smoke-tested. It overlaps #826 and should be planned as standard release-engineering work.

## Notes
- Suggested GitHub relationship: keep #1050 open as the architecture-specific acceptance tracker and cross-link #826, or close #826 as superseded once maintainers choose a canonical issue.
- No GitHub labels or issue state were changed during this triage pass.

---
**Validated by**: Code Agent
**Date**: 2026-07-23
