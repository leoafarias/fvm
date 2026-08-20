# Issue #1055: How to check latest version of fvm and how to update fvm to latest version?

## Metadata
- **Reporter**: wyatt-wong
- **Created**: 2026-08-04
- **Reported Version**: Not specified
- **Issue Type**: support / documentation
- **URL**: https://github.com/conceptadev/fvm/issues/1055

## Problem Summary
The reporter asks how to check the installed and latest FVM versions and how to update FVM. The correct update command depends on whether FVM was installed with the official install script, Homebrew, Chocolatey, Pub, or a standalone archive.

## Version Context
- Reported against: current FVM distribution
- Current release: **4.1.2** (published 2026-06-25)
- Version-specific: no
- Reason: Version inspection and installation-method-specific updates apply across FVM 4.x releases.

## Validation Steps
1. Checked the live GitHub release: `4.1.2` is the latest non-prerelease release as of 2026-08-11.
2. Confirmed `fvm --version` is the supported installed-version check and is used by install verification and repository smoke tests.
3. Inspected `origin/main` installation documentation: it documents installation and uninstallation for the supported methods, but it does not provide one consolidated update section.
4. Confirmed rerunning `dart pub global activate fvm` selects the latest version compatible with the installed Dart SDK; the FAQ already documents this compatibility behavior.
5. Confirmed the official install script resolves the latest GitHub release when no explicit version is supplied.

## Evidence
```text
Latest GitHub release: 4.1.2
Published: 2026-06-25

Installed version:
  fvm --version

Latest release page:
  https://github.com/conceptadev/fvm/releases/latest

Update by install method:
  Official script: curl -fsSL https://fvm.app/install.sh | bash
  Homebrew:        brew update && brew upgrade fvm
  Chocolatey:      choco upgrade fvm
  Pub:             dart pub global activate fvm
  Standalone:      download and replace with the latest release archive
```

**Files/Code References:**
- [docs/pages/documentation/getting-started/installation.mdx](../../docs/pages/documentation/getting-started/installation.mdx) - installation and uninstallation methods, but no consolidated update guidance.
- [docs/pages/documentation/getting-started/faq.md](../../docs/pages/documentation/getting-started/faq.md) - explains Pub/Dart compatibility when installing the latest FVM.
- [scripts/install.ps1](../../scripts/install.ps1) - verifies the installed binary using `fvm --version`.
- [docs/public/install.sh](../../docs/public/install.sh) - resolves the latest GitHub release when no version is provided.

## Current Status in v4.1.2
- [ ] Still reproducible as a product bug
- [x] Already answerable with existing commands
- [ ] Not applicable to v4.1.2
- [ ] Needs more information
- [ ] Cannot reproduce

## Troubleshooting/Implementation Plan

### Root Cause Analysis
FVM supports several installation mechanisms, each owned by a different package manager or installer. The documentation explains how to install and uninstall with each method, but does not gather the installed-version check, latest-release lookup, and update commands into one place. That makes a straightforward support question look like a missing CLI capability.

### Proposed Solution
1. Reply to #1055 with `fvm --version`, the latest-release page, and the method-specific update commands listed above.
2. Add an **Updating FVM** section to [installation.mdx](../../docs/pages/documentation/getting-started/installation.mdx) immediately before Uninstallation.
3. State that users should update through the same mechanism they used to install FVM; mixing package managers can leave multiple binaries on `PATH`.
4. Include `which -a fvm` on macOS/Linux and `where.exe fvm` on Windows as troubleshooting commands when the version does not change after an update.
5. Verify each documented command against its package manager and confirm `fvm --version` reports the expected release afterward.

### Alternative Approaches
- Add a native `fvm self-update` command. This would be misleading for package-manager installations and is unnecessary for answering the current issue.
- Only link to GitHub Releases. That does not explain how package-manager installations should be upgraded.

### Dependencies & Risks
- Homebrew and Chocolatey repositories can lag behind GitHub Releases.
- Pub installs are constrained by the user's Dart SDK version.
- Users may have multiple FVM binaries on `PATH`; update guidance should include path diagnosis.
- Standalone archive replacement needs platform-specific PATH/file replacement guidance.

### Related Code Locations
- [docs/pages/documentation/getting-started/installation.mdx](../../docs/pages/documentation/getting-started/installation.mdx)
- [docs/pages/documentation/getting-started/faq.md](../../docs/pages/documentation/getting-started/faq.md)
- [docs/public/install.sh](../../docs/public/install.sh)

## Recommendation
**Action**: validate-p3

**Reason**: This is an answerable support/documentation question, not an installation outage or runtime bug. A maintainer reply can close it immediately; a small documentation follow-up would prevent repeats.

## Notes
- Ready for an evidence-backed maintainer reply and closure.
- No GitHub comment, label, or state change was made during this triage pass.

---
**Validated by**: Code Agent
**Date**: 2026-08-11

## Closure Outcome

Closed on GitHub on 2026-08-11 as answered after providing the installed-version command, latest-release page, update commands for each installation method, and duplicate-binary PATH diagnostics.
