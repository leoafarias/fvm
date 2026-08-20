# Issue #794: Feedback for “Installation” (Raspberry Pi support)

## Metadata
- **Reporter**: @vanlooverenkoen
- **Created**: 2024-11-06
- **Issue Type**: feature request (distribution)
- **URL**: https://github.com/conceptadev/fvm/issues/794

## Problem Summary
Install script and Homebrew don’t support ARM (Raspberry Pi). Request for easier installation path.

## Validation Steps
1. Checked current `docs/public/install.sh`; `map_uname_arch` recognizes `aarch64|arm64` and `armv7l|armv7|armv6l|armv6|armhf`.
2. Checked FVM 4.1.2 release assets.
3. Confirmed native `linux-arm64` and `linux-arm` archives now ship, including musl variants.

## Evidence
```text
FVM 4.1.2 assets:
  fvm-4.1.2-linux-arm64.tar.gz
  fvm-4.1.2-linux-arm.tar.gz
  fvm-4.1.2-linux-arm64-musl.tar.gz
  fvm-4.1.2-linux-arm-musl.tar.gz

docs/public/install.sh maps ARM uname values to arm64/arm.
```

## Current Status in v4.1.2
- [ ] Still reproducible
- [x] Already fixed
- [ ] Needs more information

## Troubleshooting/Implementation Plan
1. Ask the reporter to retry the current install script on the Raspberry Pi and provide `uname -m` if it still fails.
2. Close as completed once the shipped ARM/ARM64 asset and installer mapping are acknowledged.
3. If a specific Pi architecture still fails, open a narrower follow-up with its exact `uname -m` and libc variant.

## Recommendation
- Action: **ready-to-close / resolved in v4.1.2**
- Keep in the active folder only until the still-open GitHub issue is closed.

## Notes for Follow-up
- This is no longer implementation work; it is a maintainer closure/retest action.

## Closure Outcome

Closed on GitHub on 2026-08-11 as completed. FVM 4.1.2 publishes Linux ARM/ARM64 archives and the installer recognizes Raspberry Pi ARM architectures.
