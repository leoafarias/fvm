# Issue #904: Update usage in kotlin files

## Metadata
- **Reporter**: @daedaevibin
- **Created**: 2025-09-05
- **Reported Version**: Flutter 3.29.3 (via FVM)
- **Issue Type**: upstream (Flutter SDK)
- **URL**: https://github.com/leoafarias/fvm/issues/904

## Problem Summary
The warning originates from `packages/flutter_tools/gradle/src/main/kotlin/DependencyVersionChecker.kt` inside the Flutter SDK (`minSdkVersion` deprecation). FVM only downloads Flutter releases; it does not maintain or patch Flutter’s Gradle sources.

## Version Context
- Reported against: Flutter stable channel (3.29.x)
- Current version: v4.0.0 of FVM (no change in scope)
- Version-specific: Applies to the upstream Flutter repository, not the FVM CLI.

## Validation Steps
1. Confirmed that the referenced Kotlin file lives in the Flutter repo (`flutter_tools`), not in FVM.
2. Reviewed the FVM codebase—no Kotlin/Gradle sources or build scripts exist here that could be updated.
3. Checked Flutter’s master branch; the deprecation warning is tracked upstream (should be handled in Flutter repo).

## Evidence
```
$ ls versions/stable/packages/flutter_tools/gradle/src/main/kotlin | grep DependencyVersionChecker.kt
DependencyVersionChecker.kt  # part of Flutter checkout

$ rg "minSdkVersion" lib -n
# no occurrences inside FVM sources
```

## Current Status in v4.0.0
- [ ] Still reproducible (in FVM) — N/A
- [x] Not applicable to FVM — Flutter upstream issue

## Recommendation
Close this issue on the FVM tracker and file/track it with the Flutter team. There is no FVM change required.

## Classification Recommendation
- Folder: `resolved/` (not an FVM defect)

## Notes for Follow-up
- Respond to the reporter suggesting they reference Flutter issue tracker (and optionally link to any existing Flutter bug ID).
