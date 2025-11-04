# Issue #825: [BUG] Link to documentation links to homepage, not documentation page.

## Metadata
- **Reporter**: @AMDphreak
- **Created**: 2025-02-25
- **Reported Version**: Documentation (README)
- **Issue Type**: documentation bug
- **URL**: https://github.com/leoafarias/fvm/issues/825

## Problem Summary
`README.md` links to https://fvm.app instead of the documentation landing page. The reporter suggests linking directly to `https://fvm.app/documentation/getting-started`.

## Version Context
- Reported against: Repository docs (February 2025)
- Current version: v4.0.0
- Version-specific: no — README ships with each release

## Validation Steps
1. Checked README (`line 23`) – the link still points to `https://fvm.app`.
2. Navigated to https://fvm.app; it’s a marketing landing page, not the docs. Direct docs link would improve discoverability.

## Evidence
```
README.md:23
For more information, read [FVM documentation](https://fvm.app).
```

## Current Status in v4.0.0
- [x] Still applicable

## Troubleshooting/Implementation Plan

### Root Cause Analysis
The README predates the docs site restructure and still points to the marketing homepage, so users must click again to reach the installation instructions.

### Proposed Solution
1. Update README link to `https://fvm.app/documentation/getting-started`.
2. Review other prominent docs (e.g., `docs/pages/index.mdx`, website footer) for the same outdated URL and align as needed.
3. After merging, mention the tweak in the docs changelog to encourage contributors to use the direct link going forward.

## Classification Recommendation
- Priority: **P3 - Low** (documentation tweak)
- Suggested Folder: `validated/p3-low/`

## Notes for Follow-up
- PR opened to update the README link; close the issue once it merges and confirm the rendered README shows the docs URL.
