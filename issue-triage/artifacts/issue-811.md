# Issue #811: [Feature Request] Nix package

## Metadata
- **Reporter**: @AdrienLemaire
- **Created**: 2025-01-09
- **Reported Version**: Distribution gap (no official package)
- **Issue Type**: feature request
- **URL**: https://github.com/leoafarias/fvm/issues/811

## Problem Summary
FVM ships official installers for Brew, Chocolatey, Docker, etc., but there is no maintained package for Nix/NixOS. Users on Nix must hand-roll derivations, which undermines reproducibility and discourages adoption in that ecosystem.

## Version Context
- Reported against: v3.x distribution tooling
- Current version: v4.0.0
- Version-specific: no — the release pipeline still lacks Nix integration

## Validation Steps
1. Searched the repository for existing Nix manifests (`rg -g'*.nix' --files`); none found.
2. Reviewed `.github/workflows/release.yml` — deploy pipeline covers Pub, Homebrew, Chocolatey, Docker but no Nix publishing step.
3. Checked the reporter’s linked gist and confirmed it compiles a custom derivation, demonstrating the manual effort currently required.

## Evidence
```
$ rg -g"*.nix" --files
# (no results)

$ rg "winget" -n .github/workflows/release.yml
# confirms only existing distribution targets
```

## Current Status in v4.0.0
- [x] Still reproducible (no official Nix package)
- [ ] Already fixed
- [ ] Not applicable to v4.0.0
- [ ] Needs more information

## Troubleshooting/Implementation Plan

### Root Cause Analysis
The release automation never produces or publishes a Nix derivation. Without an official manifest, Nix users must create ad-hoc packages pointing at GitHub releases, which is brittle and unmaintainable across updates.

### Proposed Solution
1. Author a canonical derivation (e.g., `nix/fvm.nix` or a flake) that fetches the GitHub release tarball and installs the binary plus bash/zsh completions.
2. Extend the release workflow to update the derivation’s `version` and `sha256` on each release (can run `nix hash file` in CI) and publish it to a dedicated repo or as part of this repository.
3. Submit the manifest upstream to `nixpkgs` so users can `nix-env -iA nixpkgs.fvm`. Provide instructions in `docs/pages/documentation/getting-started/installation.mdx` for enabling the package before upstream inclusion.
4. Add lightweight integration checks (nix build/test) to ensure the derivation stays valid across releases.

### Alternative Approaches
- Host an official Nix flake repository outside the main repo and document how to `nix registry add` it. This avoids touching nixpkgs but still gives users a maintained source.
- Offer a prebuilt binary cache (e.g., Cachix) alongside the derivation to speed installs, though not strictly required for MVP.

### Dependencies & Risks
- Maintaining `sha256` hashes per release requires automation; failing to update breaks installs.
- Need to ensure license metadata matches nixpkgs requirements (`license = licenses.mit;`).

## Classification Recommendation
- Priority: **P2 - Medium** (extends distribution to Nix ecosystems)
- Suggested Folder: `validated/p2-medium/`

## Notes for Follow-up
- Coordinate with existing release automation maintainers to avoid duplication with Homebrew/Chocolatey steps.
- Once upstreamed, document how to pin FVM via flakes for reproducible builds.
