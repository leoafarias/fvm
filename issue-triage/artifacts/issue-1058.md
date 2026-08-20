# Issue #1058: [BUG] FVM not compatible with dart-sdk v3.13.0 (Chocolatey)

## Metadata
- **Reporter**: stan-at-work
- **Created**: 2026-08-17
- **Reported Version**: 4.1.2 (Chocolatey, Windows)
- **Issue Type**: bug
- **URL**: https://github.com/leoafarias/fvm/issues/1058

## Problem Summary
Chocolatey refuses to upgrade the `dart-sdk` package while `fvm` is installed:

```
'fvm 4.1.2 constraint: dart-sdk (= 3.9.0)'
```

The FVM Chocolatey package declares an **exact** dependency on the Dart SDK version it was
built with, so any user who installs FVM through Chocolatey is pinned to that Dart SDK and
cannot move to 3.13.0 without removing FVM.

## Version Context
- Reported against: v4.1.2
- Current version: v4.1.4
- Version-specific: no
- Reason: The pin is generated at package time by the release tooling, so every Chocolatey
  release carries the same constraint against whatever Dart SDK CI used.

## Validation Steps
1. Checked the repository's `fvm.nuspec` for a hand-written `dart-sdk` dependency.
2. Traced Chocolatey packaging to the release workflow task.
3. Inspected the `cli_pkg` implementation that generates the nuspec to find the source of the
   exact-version bracket.
4. Confirmed which Dart SDK version CI pins for release builds.

## Evidence

The repository's own nuspec does **not** declare the dependency — the entire `<dependencies>`
block is commented out:

```xml
<!-- fvm.nuspec:58 -->
<!--<dependencies>
  <dependency id="" version="__MINIMUM_VERSION__" />
  ...
</dependencies>-->
```

Chocolatey deployment runs through `cli_pkg`:

```yaml
# .github/workflows/release.yml:84
run: dart run grinder pkg-chocolatey-deploy
```

`cli_pkg` injects the dependency itself, with an exact-version bracket, and documents why:

```dart
// ~/.pub-cache/hosted/pub.dev/cli_pkg-2.14.0/lib/src/chocolatey.dart:166
dependencies.children.add(
  XmlElement(XmlName("dependency"), [
    XmlAttribute(XmlName("id"), "dart-sdk"),
    // Unfortunately we need the exact same Dart version as we built with,
    // since we ship a snapshot which isn't cross-version compatible. Once
    // we switch to native compilation this won't be an issue.
    XmlAttribute(XmlName("version"), "[$chocolateyDartVersion]"),
  ]),
);
```

`[3.9.0]` is NuGet's exact-version syntax, which matches the error text the reporter saw. The
`3.9.0` value comes from the release toolchain pin (`RELEASE_DART_SDK`, documented in
`.github/workflows/README.md`).

The upstream comment also states the exit condition: the constraint exists only because the
Chocolatey package ships a **Dart snapshot** rather than a native executable. FVM has shipped
native standalone executables since v4.0.1, and native Windows ARM64 archives were added in
#1049, so the snapshot is no longer the only option for this platform.

**Files/Code References:**
- [fvm.nuspec:58](../../fvm.nuspec#L58) - dependency block is commented out locally
- [.github/workflows/release.yml:84](../../.github/workflows/release.yml#L84) - `pkg-chocolatey-deploy`
- `cli_pkg-2.14.0/lib/src/chocolatey.dart:166` - generated exact `dart-sdk` pin
- [.github/workflows/README.md](../../.github/workflows/README.md) - `RELEASE_DART_SDK` toolchain pin

## Current Status in v4.1.4
- [x] Still reproducible
- [ ] Already fixed
- [ ] Not applicable
- [ ] Needs more information
- [ ] Cannot reproduce

## Troubleshooting/Implementation Plan
**IMPORTANT**: Plan only. Do not implement during triage.

### Root Cause Analysis
The Chocolatey artifact is a Dart snapshot, which is not compatible across Dart SDK versions.
`cli_pkg` therefore emits `<dependency id="dart-sdk" version="[<build version>]" />`. NuGet
treats the bracket as an exact requirement, so upgrading `dart-sdk` past the build version
conflicts with the installed `fvm` package. Nothing in this repository overrides it.

### Proposed Solution
1. Decide the packaging model for Chocolatey. Preferred: ship the existing native Windows
   executable instead of the snapshot, which removes the need for any `dart-sdk` dependency —
   this is the resolution `cli_pkg` itself anticipates.
2. If staying on `cli_pkg` snapshots short term, post-process the generated nuspec to relax
   the bracket to a minimum-version range (`3.9.0`) and verify FVM actually runs under newer
   Dart SDKs before publishing that claim. Do not relax the constraint without that proof —
   snapshot format incompatibility is real and is what produces
   `Can't load Kernel binary: Invalid kernel binary format version`.
3. Coordinate with #1050, which already covers architecture-aware Winget/Chocolatey delivery
   of the native archives; native Chocolatey packaging is the same workstream.
4. Verify on a clean Windows box: install FVM via Chocolatey, then `choco upgrade dart-sdk`,
   and confirm both packages resolve and `fvm --version` still runs.

### Alternative Approaches
- Bump `RELEASE_DART_SDK` each release so the pin tracks the newest Dart SDK. Rejected as a
  fix: it only moves the pin, still blocking users on any other Dart SDK version.
- Document the constraint and recommend the standalone installer for users who manage
  `dart-sdk` through Chocolatey. Worth doing as an interim mitigation regardless.

### Dependencies & Risks
- Changing the Chocolatey artifact affects the release pipeline and must be validated on
  Windows x64 and ARM64.
- Users who currently rely on the FVM package pulling in `dart-sdk` would no longer get it;
  that is desirable but should be called out in release notes.
- Related packaging issues: #1050 (Winget/Chocolatey ARM64 delivery), #826 (Winget manifests),
  #933 (historical Chocolatey report).

### Related Code Locations
- [.github/workflows/release.yml:84](../../.github/workflows/release.yml#L84) - Chocolatey deploy step
- [tool/release_tool/](../../tool/release_tool/) - release grinder tasks

## Recommendation
**Action**: validate-p2

**Reason**: Confirmed packaging defect with a clear upstream root cause, but it affects only
the Chocolatey install channel and has practical workarounds (standalone installer, or keeping
the pinned `dart-sdk`), so it does not block FVM usage itself.

## Notes
- The reporter's log is Chocolatey/NuGet output rather than FVM output; no FVM code change is
  implied beyond packaging.
- This is the same underlying constraint that produces snapshot/kernel mismatch errors when a
  pub-global-activated FVM is run against a different Dart SDK.

---
**Validated by**: Code Agent
**Date**: 2026-08-19
