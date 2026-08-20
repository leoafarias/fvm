# Issue #781: Cannot find file at '..\lib\fvm\bin\fvm.exe' after Chocolatey install

## Metadata
- **Reporter**: @RNOVOSELOV
- **Created**: 2024-09-16
- **Issue Type**: installation bug (needs info)
- **URL**: https://github.com/conceptadev/fvm/issues/781

## Problem Summary
Chocolatey install reports `Cannot find file at '..\lib\fvm\bin\fvm.exe'`. Need more detail about the version and logs.

## Validation Steps
1. Reviewed the live report; it predates FVM 4.x and contains no Chocolatey package version or verbose install log.
2. Confirmed current FVM publishes Windows x64/arm64 zip assets, but Chocolatey packaging is external to the core install script.
3. Could not establish whether the current Chocolatey package still creates the broken shim target.

## Evidence
```text
Reported missing path:
C:\ProgramData\chocolatey\lib\fvm\bin\fvm.exe

Missing: choco package version, install transcript, package directory listing,
and a reproduction on the current FVM/Chocolatey package.
```

## Troubleshooting/Implementation Plan
- Ask for `choco install fvm --force --verbose` output and `dir C:\ProgramData\chocolatey\lib\fvm\` listing.
- Verify whether latest package (v4.0.0) resolves the issue.
- If current, inspect the Chocolatey shim target and package install script; otherwise close as obsolete after reporter confirmation.

## Recommendation
- Folder: `needs_info/`
