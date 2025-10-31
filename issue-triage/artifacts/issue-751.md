# Issue #751: [Feature Request] Support range versions

## Metadata
- **Reporter**: @MiniSuperDev
- **Created**: 2024-07-10
- **Issue Type**: feature request
- **URL**: https://github.com/leoafarias/fvm/issues/751

## Problem Summary
Request support for version ranges (e.g., `3.22.*`) to avoid installing every patch explicitly.

## Proposed Solution
- Allow `.fvmrc` to specify semver constraints (use `pub_semver` constraints) and resolve to the latest installed version or fetch the newest matching release.
- Update `fvm use/install` to accept constraints and expand them.
- Add tests and documentation.

## Classification Recommendation
- Priority: **P3 - Low**
- Suggested Folder: `validated/p3-low/`
