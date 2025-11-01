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
- [ ] Still reproducible
- [x] Already fixed
- [ ] Not applicable to v4.0.0
- [ ] Needs more information

## Resolution
Homebrew tap PR #22 (merged 2025-11-01) now bundles Dart SDK 3.6.0 alongside FVM 4.0.0. After running `brew update`, reinstalling from the tap succeeds:

```
brew reinstall --build-from-source leoafarias/fvm/fvm
$(brew --prefix fvm)/libexec/bin/dart --version  # reports 3.6.0
fvm --version                                   # reports 4.0.0
```

For future maintenance, keep the tap’s Dart version aligned with the SDK minimum noted in `pubspec.lock`.

## Recommendation
**Action**: closed  
**Reason**: Homebrew formula now ships Dart 3.6.0+, eliminating the solver error.
