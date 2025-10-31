# Issue #754: Feedback for “Installing FVM in Mac Issue”

## Metadata
- **Reporter**: @devaashis
- **Created**: 2024-07-25
- **Reported Version**: n/a (installer feedback)
- **Issue Type**: support
- **URL**: https://github.com/leoafarias/fvm/issues/754

## Problem Summary
Homebrew installation fails on macOS Monterey when Xcode ≤13 is installed. Homebrew refuses to build the formula without Xcode 14.2+, so users on older macOS versions need an alternative installation method.

## Version Context
- Reported against: Homebrew installer (mid-2024)
- Current version: v4.0.0
- Version-specific: no
- Reason: The limitation comes from Homebrew’s Xcode requirement, not from the FVM codebase.

## Validation Steps
1. Reviewed the Homebrew error—`CompilerSelectionError` triggered by outdated Xcode.
2. Confirmed the official install script downloads prebuilt binaries without relying on Xcode (`docs/pages/documentation/getting-started/installation.mdx:73-133`).
3. Verified GitHub releases provide universal macOS binaries bypassing Homebrew builds.

## Evidence
```
docs/pages/documentation/getting-started/installation.mdx:73-133  // Install script instructions and supported platforms
docs/pages/documentation/getting-started/installation.mdx:90-93   // Callout to GitHub Releases as an alternative
```

**Files/Code References:**
- [docs/pages/documentation/getting-started/installation.mdx:73](../docs/pages/documentation/getting-started/installation.mdx#L73) – Install script workflow (no Xcode dependency).
- [docs/pages/documentation/getting-started/installation.mdx:90](../docs/pages/documentation/getting-started/installation.mdx#L90) – Link to download prebuilt binaries.

## Current Status in v4.0.0
- [ ] Still reproducible
- [x] Already fixed
- [ ] Not applicable to v4.0.0
- [ ] Needs more information
- [ ] Cannot reproduce

## Troubleshooting/Implementation Plan

### Root Cause Analysis
Homebrew enforces minimum Xcode versions for formula compilation. FVM cannot change that requirement; users on older macOS builds must install via script or manual download.

### Proposed Solution
1. Close the issue with guidance to use the official install script or GitHub release tarball on older macOS versions.
2. Mention that the script supports arm64/x64 and works without Xcode.
3. Optionally add an FAQ snippet “Homebrew requires newer Xcode” to the installation doc.

### Alternative Approaches
- Publish a cask that ships binaries, but the install script already covers this path and is featured in docs.

### Dependencies & Risks
- Documentation / support only.

### Related Code Locations
- [docs/public/install.sh](../docs/public/install.sh) – Script delivering prebuilt binaries.

## Recommendation
**Action**: resolved  
**Reason**: Users can install FVM without Homebrew by using the official script or release binaries; no FVM changes required.

## Draft Reply
```
Thanks for the report! The Homebrew build path requires Xcode 14.2+, so on Monterey you can install FVM using the official script instead:

```bash
curl -fsSL https://fvm.app/install.sh | bash
```

The script downloads our notarized binary—no Xcode or toolchain build is needed. If you prefer a manual download, the latest `.tar.xz` macOS bundles are also available on the Releases page.

Given that FVM itself doesn’t depend on the newer Xcode, I’ll close this out, but feel free to follow up if the script path gives you trouble.
```

## Notes
- Consider adding an FAQ entry pointing Monterey users to the install script.

---
**Validated by**: Code Agent  
**Date**: 2025-10-31
