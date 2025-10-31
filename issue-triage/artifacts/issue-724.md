# Issue #724: SDK Path does not point to the project directory. "fvm use" will not make IntelliJ switch Flutter version

## Metadata
- **Reporter**: @Haidar0096
- **Created**: 2024-04-01? (should check createdAt) but use from JSON.
- **Issue Type**: support
- **URL**: https://github.com/leoafarias/fvm/issues/724

## Summary
Android Studio warning occurs because IDE uses global `~/fvm/versions/stable` path. Recommendation: configure Flutter SDK path to `.fvm/flutter_sdk` or use `fvm config --update-vscode-settings`. No code change required.

## Classification Recommendation
- Folder: `resolved/`
