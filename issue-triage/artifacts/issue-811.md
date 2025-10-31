# Issue #811: [Feature Request] Nix package

## Metadata
- **Reporter**: @AdrienLemaire
- **Created**: 2025-01-09
- **Issue Type**: feature request
- **URL**: https://github.com/leoafarias/fvm/issues/811

## Problem Summary
Request for an official Nix/NixOS package for FVM following nixpkgs conventions.

## Validation Steps
1. Confirmed no official Nix package exists in repo.
2. Reporter provided template based on existing packages (e.g., Volta).

## Proposed Implementation Plan
1. Produce a Nix derivation (e.g., `nix/package.nix`) that downloads the release tarball and installs the binary.
2. Provide instructions/flake for nix-shell usage.
3. Optionally upstream to nixpkgs by submitting PR referencing new derivation.

## Classification Recommendation
- Priority: **P2 - Medium** (extends distribution to Nix ecosystems)
- Suggested Folder: `validated/p2-medium/`

## Notes for Follow-up
- Need to maintain sha256 for each release or automate via `nix flake`.
