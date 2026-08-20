# Issue #720: [Feature Request] Automatically install required Flutter version

## Metadata
- **Reporter**: @Islam-alshiki
- **Created**: 2024-05-06
- **Issue Type**: feature request
- **URL**: https://github.com/conceptadev/fvm/issues/720

## Problem Summary
Request for command that reads project and automatically installs required Flutter version.

## Validation Steps
1. Inspected `InstallCommand` on current `origin/main`.
2. Confirmed `fvm install` with no version already reads the nearest project's pinned `.fvmrc` version, installs it, and runs the use workflow.
3. Confirmed it does not fall back to a Flutter constraint in `pubspec.yaml`; that remaining request overlaps #577.

## Evidence
```text
lib/src/commands/install_command.dart
  if argResults.rest is empty:
    project = ProjectService.findAncestor()
    version = project.pinnedVersion
    ensureCache(... shouldInstall: true)
    useVersion(...)

No pubspec Flutter-constraint fallback exists.
```

## Current Status in v4.1.2
- [x] Partially implemented for `.fvmrc`
- [ ] Implemented for pubspec constraints
- [ ] Needs more information

## Troubleshooting/Implementation Plan

### Proposed Solution
- Do not add a redundant `fvm sync` for `.fvmrc`; document the existing no-argument `fvm install` behavior.
- Track pubspec constraint resolution with #577 and define how a range resolves to one concrete Flutter release.

## Recommendation
- Priority: **P3 - Low**
- Suggested Folder: `validated/p3-low/`

## Closure Outcome

Closed on GitHub on 2026-08-11 with the `duplicate` label and a not-planned state reason. Current FVM implements the `.fvmrc` portion through no-argument `fvm install`; the remaining `pubspec.yaml` fallback is tracked in #577.
