# Issue #940: [BUG]Because pubspec_parse 1.5.0 requires SDK version ^3.6.0 and no versions of pubspec_parse match >1.5.0

## Metadata
- **Reporter**: @bareycn
- **Created**: 2025-10-19
- **Reported Version**: 4.0.0-beta.2 (Homebrew tap)
- **Issue Type**: bug (installation)
- **URL**: https://github.com/leoafarias/fvm/issues/940

## Problem Summary
Homebrew builds for `fvm@4.0.0-beta.2` vend a Dart 3.2.6 toolchain. When the formula runs `dart pub get`, resolution fails because FVM depends on `pubspec_parse ^1.5.0`, which requires Dart >=3.6.0.

## Version Context
- Reported against: v4.0.0-beta.2 (tap formula)
- Current version: v4.0.0
- Version-specific: no — any build that uses a Dart SDK older than 3.6.0 will hit this failure

## Validation Steps
1. Reviewed the Homebrew formula `fvm.rb` (tap `leoafarias/homebrew-fvm`) and confirmed it downloads Dart SDK 3.2.6 for all platforms.
2. Inspected `pubspec.yaml` and verified we pin `pubspec_parse: ^1.5.0`.
3. Checked `pubspec.lock`, which indicates the package graph now requires `dart: ">=3.6.0 <4.0.0"`.
4. Noted that our `environment.sdk` constraint in `pubspec.yaml` remains `">=2.17.0 <4.0.0"`, so package managers may not realize the higher SDK floor.

## Evidence
```
$ curl -s https://raw.githubusercontent.com/leoafarias/homebrew-fvm/master/fvm.rb | sed -n '1,40p'
  ... release/3.2.6/sdk/dartsdk-...zip

$ nl -ba pubspec.yaml | sed -n '25,36p'
    30  pubspec_parse: ^1.5.0

$ sed -n '892,900p' pubspec.lock
sdks:
  dart: ">=3.6.0 <4.0.0"
```

## Current Status in v4.0.0
- [x] Still reproducible
- [ ] Already fixed
- [ ] Not applicable to v4.0.0
- [ ] Needs more information

## Troubleshooting/Implementation Plan

### Root Cause Analysis
The Homebrew formula bundles Dart SDK 3.2.6, but FVM’s dependency graph (via `pubspec_parse 1.5.0`) requires Dart >=3.6.0. Our own `environment.sdk` constraint does not communicate the new minimum, so the formula continues to vend the older runtime and compilation fails during `pub get`.

### Proposed Solution
1. **Update SDK constraints**: Change `environment.sdk` in `pubspec.yaml` to `">=3.6.0 <4.0.0"` so tooling enforces the new minimum. Regenerate `pubspec.lock` and update `CHANGELOG.md` / docs to document the Dart requirement.
2. **Fix Homebrew formula**:
   - Bump the vendored Dart SDK URLs in `homebrew-fvm/fvm.rb` (and any versioned formulae such as `fvm@4.0.0-beta.2.rb`) to at least Dart 3.6.0 (ideally current stable 3.9.x).
   - Adjust the formula’s test block to validate `fvm --version` so future regressions surface immediately.
3. **Release artifacts**: Ensure CI builds ship precompiled binaries targeting the updated SDK so other installers (install.sh, GitHub releases) remain unaffected.
4. **Verification**:
   - Run `dart pub get` and `dart compile exe` locally with Dart 3.6.x after updating the constraint.
   - In the Homebrew tap, run `brew install --build-from-source ./fvm.rb` on macOS Intel and ARM to confirm the build succeeds.

### Alternative Approaches
- Downgrade to `pubspec_parse 1.4.x` to keep the older SDK floor. This avoids the immediate breakage but forfeits upstream fixes and pushes technical debt forward.

### Dependencies & Risks
- Requires coordination with the `homebrew-fvm` tap (separate repo) and possibly the main Homebrew/core maintainers.
- Users on older Dart SDKs will no longer be able to build from source; communicate the requirement clearly.

## Classification Recommendation
- Priority: **P1 - High** (installer failure)
- Suggested Folder: `validated/p1-high/`

## Notes for Follow-up
- Once formula is updated, prompt users in the GitHub issue to `brew update && brew upgrade fvm` and confirm fix.
