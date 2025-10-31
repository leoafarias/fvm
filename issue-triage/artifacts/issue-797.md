# Issue #797: env: bash\r: No such file or directory

## Metadata
- **Reporter**: @zakblacki
- **Created**: 2024-11-12
- **Issue Type**: bug (needs info)
- **URL**: https://github.com/leoafarias/fvm/issues/797

## Summary
1. `fvm flutter --version` exits with `env: bash\r: No such file or directory`.
2. IDE doctor warning about SDK path.

## Observations
- The error indicates the Flutter wrapper script has Windows line endings. Need confirmation of the file contents (`file ~/.fvm/versions/stable/bin/flutter`).
- IDE warning already documented (configure path to `.fvm/flutter_sdk`).

## Next Steps
Request reporter to:
- Run `file ~/.fvm/versions/stable/bin/flutter` and `head -n5` to check line endings.
- Remove/reinstall the version (`fvm remove stable && fvm install stable --setup`).
- Confirm if the issue persists outside the project.
- Follow docs for IDE setup.

## Classification Recommendation
- Folder: `needs_info/`
