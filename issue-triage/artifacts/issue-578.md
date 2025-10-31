# Issue #578: [Feature Request] Add MacPorts as an installation method

## Metadata
- **Reporter**: Isuru Nanayakkara (@Isuru-Nanayakkara)
- **Created**: 2023-12-03
- **Reported Version**: 3.0.x
- **Issue Type**: enhancement (distribution)
- **URL**: https://github.com/leoafarias/fvm/issues/578

## Problem Summary
FVM is distributed via Homebrew on macOS. Some environments (multi-user Macs, corporate setups) prefer or require MacPorts. Users would like an official MacPorts port so they can `sudo port install fvm`.

## Version Context
- Reported against: 3.0.x
- Current version: v4.0.0
- Version-specific: no — distribution gap.

## Validation Steps
1. Verified the repository: no MacPorts Portfile or automation exists.
2. Checked MacPorts ports tree — FVM is not present.
3. Homebrew formula already exists (`brew install fvm`), so we can repurpose release assets for MacPorts.

## Evidence
```
$ brew search fvm
fvm ✔

$ port search fvm
-- no results --
```

**Files/Code References:**
- Release assets provide prebuilt macOS binaries (`fvm-<ver>-macos-x64.tar.gz`, etc.) suitable for packaging.

## Current Status in v4.0.0
- [x] Still reproducible (feature absent)
- [ ] Already fixed
- [ ] Not applicable to v4.0.0
- [ ] Needs more information
- [ ] Cannot reproduce

## Troubleshooting/Implementation Plan

### Proposed Solution
1. Author a MacPorts Portfile:
   - Category: `devel`.
   - Fetch the GitHub release tarball.
   - Install the binary to `${prefix}/libexec/fvm` (or similar) and symlink into `${prefix}/bin`.
   - Declare dependencies (none beyond system libs, but ensure `git`, `curl` instructions documented).
2. Submit the Portfile to the MacPorts ports repository via PR.
3. Set up a release checklist to update the Portfile’s version/hash for each FVM release (could automate via GitHub Actions that opens a MacPorts PR).
4. Update installation docs with MacPorts instructions.

### Alternative Approaches
- Encourage the community to maintain the port (document how to do it) instead of maintaining it internally.

### Dependencies & Risks
- MacPorts maintainers must approve port submissions; expect review cycle.
- Need to provide both x86_64 and arm64 binaries (already shipped in releases).

### Related Code Locations
- `.github/workflows/release.yml` – Could automate hash updates.
- `docs/pages/documentation/getting-started/installation.mdx` – Add MacPorts section.

## Recommendation
**Action**: validate-p3

**Reason**: Improves macOS coverage but existing install methods (Homebrew, install script) still work; treat as distribution backlog.

## Notes
- Consider aligning release automation for Homebrew and MacPorts to share metadata (version/hashes).

---
**Validated by**: Code Agent
**Date**: 2025-10-31
