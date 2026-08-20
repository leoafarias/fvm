# Issue #751: [Feature Request] Support range versions

## Metadata
- **Reporter**: @MiniSuperDev
- **Created**: 2024-07-10
- **Issue Type**: feature request
- **URL**: https://github.com/conceptadev/fvm/issues/751

## Problem Summary
Request support for version ranges (e.g., `3.22.*`) to avoid installing every patch explicitly.

## Validation Steps
1. Inspected current Flutter version parsing and validation on `origin/main`.
2. Confirmed project config stores one concrete Flutter version/channel/fork reference.
3. Confirmed no command resolves a `pub_semver` range to the newest matching Flutter release.

## Evidence
```text
.fvmrc `flutter` is parsed as one FlutterVersion value.
Current accepted forms are channels, exact versions, commits, and [fork/]version[@channel].
No VersionConstraint-based release resolver is used by install/use.
```

## Current Status in v4.1.2
- [x] Still unresolved
- [ ] Already implemented
- [ ] Needs more information

## Troubleshooting/Implementation Plan

### Proposed Solution
- Allow `.fvmrc` to specify semver constraints (use `pub_semver` constraints) and resolve to the latest installed version or fetch the newest matching release.
- Update `fvm use/install` to accept constraints and expand them.
- Add tests and documentation.

## Recommendation
- Priority: **P3 - Low**
- Suggested Folder: `validated/p3-low/`
