# Issue #826: [Feature Request] Add package to Winget

## Metadata
- **Reporter**: @AMDphreak
- **Created**: 2025-02-25
- **Reported Version**: Packaging request
- **Issue Type**: feature request
- **URL**: https://github.com/leoafarias/fvm/issues/826

## Problem Summary
FVM currently distributes Windows packages via Chocolatey. The reporter notes Chocolatey lag and asks for a native Winget package.

## Version Context
- Current version: v4.0.0
- Winget support does not exist yet.

## Validation Steps
1. Reviewed `.github/workflows/release.yml`: deploy jobs cover Pub, GitHub, Homebrew, Chocolatey, Docker. No Winget pipeline.
2. A search of the Winget manifest repository shows no FVM entry (manual check required during implementation).

## Evidence
```
.github/workflows/release.yml  // no winget step
```

## Troubleshooting/Implementation Plan

### Root Cause Analysis
The release automation only targets Pub, Homebrew, Chocolatey, and Docker, so Windows users who prefer Winget cannot install or update FVM through their native package manager. Chocolatey delays prompted the request.

### Proposed Implementation Plan
1. Create Winget manifest(s) under a new `.winget` directory or integrate into release automation.
2. Use `wingetcreate` or the official Winget YAML schema. Manifests reside in `manifests/f/Fvm/Fvm/`. Define installer (portable .zip or MSI) referencing GitHub release assets.
3. Add GitHub Action step (Windows runner) after Chocolatey deploy to:
   - Download latest release asset.
   - Run `wingetcreate update` or `wingetcreate submit` with manifest updates.
   - Submit PR to `microsoft/winget-pkgs` repo (requires PAT and automation similar to `pkg-homebrew-update`).
4. Document Winget install instructions in `docs/pages/documentation/getting-started/installation.mdx` (Windows section).
5. Coordinate version bump process (Winget requires manual PR review; include fallback instructions if automation blocked).

## Classification Recommendation
- Priority: **P2 - Medium** (expands distribution reach)
- Suggested Folder: `validated/p2-medium/`

## Notes for Follow-up
- Ensure licensing compliant; Winget requires silent install support (portable is fine). Might reuse Windows `.zip` shipped today.
