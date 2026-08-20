# Issue #748: [Question] I cannot to setup fvm global stable in windows

## Metadata
- **Reporter**: @Bellukchips
- **Created**: 2024-07-01
- **Issue Type**: needs info
- **URL**: https://github.com/conceptadev/fvm/issues/748

## Problem Summary
Issue description contains only an image; need textual details/logs to help.

## Validation Steps
1. Re-read the live issue and confirmed it still contains only an image.
2. Checked current global/install workflows; several distinct Windows failures could produce a setup problem, so the target cannot be inferred safely.

## Evidence
```text
Missing from the issue: FVM version, Windows version, shell, command,
exit code, textual error, fvm doctor output, and privilege configuration.
```

## Troubleshooting/Implementation Plan
1. Request `fvm --version`, `fvm doctor --verbose`, and the exact `fvm global stable --verbose` output.
2. Ask whether Windows Developer Mode is enabled and whether `privilegedAccess` is configured.
3. Ask the reporter to confirm the installed stable SDK appears in `fvm list`.
4. Keep in needs-info until a current reproduction distinguishes installation, symlink privilege, and PATH failures.

## Recommendation
Request steps, commands, and error output.

## Classification Recommendation
- Folder: `needs_info/`

## Closure Outcome

Closed on GitHub on 2026-08-11 as answered/working as intended. The reply reiterates the Windows global PATH setup and invites a new textual reproduction if current FVM still fails.
