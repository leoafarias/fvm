# Issue #794: Feedback for “Installation” (Raspberry Pi support)

## Metadata
- **Reporter**: @vanlooverenkoen
- **Created**: 2024-11-06
- **Issue Type**: feature request (distribution)
- **URL**: https://github.com/leoafarias/fvm/issues/794

## Problem Summary
Install script and Homebrew don’t support ARM (Raspberry Pi). Request for easier installation path.

## Validation Steps
1. Checked `scripts/install.sh`; architecture switch only accepts `x86_64` and `arm64`.
2. Release pipeline currently ships macOS x64/arm64, Windows, Linux x64 (no arm variants).

## Proposed Implementation Plan
1. Extend CI to produce Linux arm64 (and optionally armv7) binaries via `cli_pkg` (requires running release job on ARM runner or cross-compiling).
2. Update install script to recognize `armv7l`, `armhf`, etc., and download appropriate tarball.
3. Document alternative fallback (`dart pub global activate fvm`) until native binary ready.

## Classification Recommendation
- Priority: **P2 - Medium** (broadens platform support)
- Suggested Folder: `validated/p2-medium/`

## Notes for Follow-up
- Evaluate demand before investing in armv7 vs arm64.
