# Issue #767: Android Studio cannot change the project's Flutter SDK path

## Metadata
- **Reporter**: @EthanZhuGit
- **Created**: 2024-08-26
- **Issue Type**: bug (needs info)
- **URL**: https://github.com/leoafarias/fvm/issues/767

## Summary
Android Studio keeps reverting SDK path to previous project after running `fvm global`. Need additional data (logs, `fvm doctor --verbose`, contents of `.idea/libraries/Dart_SDK.xml`). Possibly related to symlink permissions on Windows.

## Next Steps
Request additional info and confirm Developer Mode/symlink permissions.

## Classification Recommendation
- Folder: `needs_info/`
