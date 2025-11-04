# Issue #933: [Feature Request] give fvm a full name in package manager

## Metadata
- **Reporter**: @AMDphreak
- **Created**: 2025-10-04
- **Reported Version**: Not specified (Chocolatey package)
- **Issue Type**: feature (packaging polish)
- **URL**: https://github.com/leoafarias/fvm/issues/933

## Problem Summary
The Chocolatey package metadata shows the title simply as “fvm”, making it unclear to users browsing the gallery. The reporter requests that we expose the full product name (Flutter Version Manager) in the package name/title field.

## Version Context
- Reported against: Chocolatey package (latest as of Oct 2025)
- Current version: v4.0.0
- Version-specific: no — change affects metadata for all future releases

## Validation Steps
1. Inspected `fvm.nuspec`, which controls Chocolatey metadata. The `<title>` element is currently `fvm (Install)`.
2. Verified that the summary/description mention “Flutter Version Management”, but the display title does not include the full name, matching the screenshot from the issue.
3. Confirmed our release workflow (`grinder` + `pkg-chocolatey-…` tasks) reuses `fvm.nuspec` each release, so updating the file will propagate to future packages.

## Evidence
```
$ nl -ba fvm.nuspec | sed -n '20,60p'
    28     <title>fvm (Install)</title>
    29     <authors>leochocolatey</authors>
    30     <projectUrl>https://github.com/leoafarias/fvm</projectUrl>
    31     ...
    37     <summary>Flutter Version Management: A simple cli...</summary>
```

## Current Status in v4.0.0
- [ ] Still reproducible
- [x] Already fixed (issue closed on 2025-11-03 after updating `fvm.nuspec`)
- [ ] Not applicable to v4.0.0
- [ ] Needs more information

## Troubleshooting/Implementation Plan

### Root Cause Analysis
The Chocolatey metadata hard-codes a short title, so the gallery UI displays “fvm” instead of “Flutter Version Manager”. Nothing in the automation overrides the nuspec, so the title has remained unchanged.

### Proposed Solution
1. Update `fvm.nuspec`:
   - Set `<title>` to something like `Flutter Version Manager (FVM)` so the gallery shows the full name.
   - Optionally adjust `<summary>` to start with “Flutter Version Manager” for consistency.
2. Run the release workflow (`dart run grinder pkg-chocolatey-deploy`) in a dry run to confirm the nuspec update is embedded, or manually run `choco pack` in CI to validate metadata.
3. Document the change in `CHANGELOG.md` (under packaging) so users know the Chocolatey listing has been updated.

### Alternative Approaches
- Add a Chocolatey `title` override via `cli_pkg` configuration if we want to keep the nuspec untouched, but modifying the nuspec directly is straightforward.

### Dependencies & Risks
- Minimal; only impacts package metadata. Ensure Chocolatey moderation guidelines are still satisfied (title must include the package id, so keep “FVM” in parentheses).

## Classification Recommendation
- Priority: **P3 - Low** (cosmetic improvement)
- Suggested Folder: `validated/p3-low/`

## Notes for Follow-up
- After the next Chocolatey publish, verify the gallery page reflects the new title and close the GitHub issue with a screenshot for confirmation.
