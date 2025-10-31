# Issue #825: [BUG] Link to documentation links to homepage, not documentation page.

## Metadata
- **Reporter**: @AMDphreak
- **Created**: 2025-02-25
- **Reported Version**: Documentation (README)
- **Issue Type**: documentation bug
- **URL**: https://github.com/leoafarias/fvm/issues/825

## Problem Summary
`README.md` links to https://fvm.app instead of the documentation landing page. The reporter suggests linking directly to `https://fvm.app/documentation/getting-started`.

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
1. Update README link to `https://fvm.app/documentation/getting-started`.
2. Review other docs (e.g., `docs/public/install.sh`?) for similar root links and align as needed.

## Classification Recommendation
- Priority: **P3 - Low** (documentation tweak)
- Suggested Folder: `validated/p3-low/`

## Notes for Follow-up
- After updating README, close issue with reference to commit.
