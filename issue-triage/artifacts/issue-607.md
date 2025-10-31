# Issue #607: Support flatpak or snaps on Linux.

## Metadata
- **Reporter**: @safield
- **Created**: 2024-02-13
- **Reported Version**: 3.0.x
- **Issue Type**: enhancement (distribution)
- **URL**: https://github.com/leoafarias/fvm/issues/607

## Problem Summary
Linux users currently install FVM via Homebrew (or the install script). Homebrew on Linux is uncommon, so providing native packaging (Snap/Flatpak) would simplify onboarding and align with the distribution channels many distros expect.

## Version Context
- Reported against: 3.0.x
- Current version: v4.0.0
- Version-specific: no — release engineering gap.

## Validation Steps
1. Reviewed the repository — no Snapcraft or Flatpak manifests exist.
2. Checked current release docs (`docs/pages/documentation/getting-started/installation.mdx`) — Linux instructions mention Homebrew and shell script only.
3. Audited build tooling — the GitHub Actions release workflow already produces standalone binaries, which can be repackaged for Snap/Flatpak.

## Evidence
```
$ ls snap
ls: snap: No such file or directory

$ rg "flatpak" -n
# no hits besides the issue text
```

**Files/Code References:**
- Release automation lives in `.github/workflows`, but no Linux-native packaging targets.

## Current Status in v4.0.0
- [x] Still reproducible (feature missing)
- [ ] Already fixed
- [ ] Not applicable to v4.0.0
- [ ] Needs more information
- [ ] Cannot reproduce

## Troubleshooting/Implementation Plan

### Proposed Solution
1. **Snap package (preferred first step):**
   - Author `snap/snapcraft.yaml` using `base: core22`, stage the compiled `fvm` binary and dependencies.
   - Request `classic` confinement (FVM needs unrestricted access to `$HOME`, git, and user shells).
   - Add a GitHub Actions job that, on tagged releases, builds the Snap (using `snapcraft --use-lxd`) and pushes to the Snap Store edge channel. Promote to stable once verified.
   - Provide instructions for manual testing (`snap install --dangerous`).
2. **Evaluate Flatpak feasibility:**
   - Draft a manifest (YAML/JSON) targeting `org.freedesktop.Platform//23.08`.
   - Determine sandbox permissions (`--filesystem=home`, `--socket=ssh-auth`?) necessary for git, shell integration, and PATH management. If acceptable, submit to Flathub (requires review).
   - If sandbox restrictions are too tight, document the limitation and consider shipping only Snap + shell script.
3. **Update documentation:**
   - Add Linux installation options to the “Installation” docs.
   - Mention required permissions (`snap install --classic fvm`) and potential Flatpak sandbox flags.
4. **Telemetry/Analytics:**
   - Track adoption by monitoring Snap download metrics; adjust support accordingly.

### Dependencies & Risks
- Snap *classic* confinement needs manual review by the Snap Store team; expect lead time.
- Flatpak’s sandbox may conflict with FVM’s need to edit shell profiles; may need to declare as “not supported” if permissions can’t be granted.
- Release automation must handle signing/credentials securely (store tokens via GitHub Secrets).

### Related Code Locations
- `.github/workflows/release.yml` (or equivalent) — extend to build/publish packages.
- `docs/pages/documentation/getting-started/installation.mdx` — update installation instructions.

## Recommendation
**Action**: validate-p3

**Reason**: Improves distribution ergonomics but doesn’t block existing users (install script and binaries still work). Prioritize after higher-impact fixes.

## Notes
- Consider offering Debian/RPM packages later via `apt`/`dnf` if community demand grows.
- Coordinate with marketing/documentation before Flip to ensure announcements coincide with store availability.

---
**Validated by**: Code Agent
**Date**: 2025-10-31
