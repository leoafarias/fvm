# Issue #797: env: bash\r: No such file or directory

## Metadata
- **Reporter**: @zakblacki
- **Created**: 2024-11-12
- **Issue Type**: bug (needs info)
- **URL**: https://github.com/conceptadev/fvm/issues/797

## Problem Summary
1. `fvm flutter --version` exits with `env: bash\r: No such file or directory`.
2. IDE doctor warning about SDK path.

## Observations
- The error indicates the Flutter wrapper script has Windows line endings. Need confirmation of the file contents (`file ~/.fvm/versions/stable/bin/flutter`).
- IDE warning already documented (configure path to `.fvm/flutter_sdk`).

## Validation Steps
1. Reviewed the supplied FVM 3.2.1 doctor output and exact `bash\r` error.
2. Confirmed the signature is consistent with CRLF in the managed Flutter shell script, not an FVM argument parser failure.
3. No current 4.1.2 reproduction or file inspection was supplied, so the source of the CRLF conversion remains unknown.

## Evidence
```text
env: bash\r: No such file or directory

This error occurs when a shebang such as #!/usr/bin/env bash contains CRLF.
Required confirmation: file and line-ending output for <managed-sdk>/bin/flutter.
```

## Troubleshooting/Implementation Plan
Request reporter to:
- Run `file ~/.fvm/versions/stable/bin/flutter` and `head -n5` to check line endings.
- Remove/reinstall the version (`fvm remove stable && fvm install stable --setup`).
- Confirm if the issue persists outside the project.
- Follow docs for IDE setup.
- If reproducible on 4.1.2, trace whether Git configuration (`core.autocrlf`), cache cloning, or an external sync tool converts the SDK script.

## Recommendation
- Folder: `needs_info/`
