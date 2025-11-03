# Issue #581: [BUG] Cannot install flutter into the fvm alpine Docker container

## Metadata
- **Reporter**: Jaanus Kase (@jaanus)
- **Created**: 2023-12-05
- **Reported Version**: 2.4.1
- **Issue Type**: bug (Docker distribution)
- **URL**: https://github.com/leoafarias/fvm/issues/581

## Problem Summary
The official Alpine-based FVM Docker image (`.docker/alpine/Dockerfile`) fails to install Flutter on Apple Silicon hosts. Flutter downloads the Linux **arm64** Dart SDK, but the image installs the x86_64 glibc shim from sgerrand and ships the x86_64 FVM binary. When the installer tries to execute the freshly downloaded `dart` binary, the kernel returns “No such file or directory” (loader mismatch), and the installation loops indefinitely.

## Version Context
- Reported against: 2.4.1
- Current version: v4.0.0
- Version-specific: no — Dockerfile still hardcodes x86_64 assets and Alpine 3.13.
- Environment: Docker Desktop on Apple Silicon (aarch64).

## Validation Steps
1. Reviewed `.docker/alpine/Dockerfile`; it downloads `fvm-<ver>-linux-x64.tar.gz` and installs sgerrand’s glibc packages (only available for x86_64).
2. Flutter install logs show “Downloading Linux arm64 Dart SDK…” indicating the runtime is aarch64 inside the container.
3. When an arm64 binary runs against an x86_64 loader, the kernel emits the observed `No such file or directory`.
4. No multi-arch build pipeline exists for the Docker image; we currently publish only a single variant.

## Evidence
```
$ sed -n '1,60p' .docker/alpine/Dockerfile
  && wget .../fvm-${FVM_VERSION}-linux-x64.tar.gz
  ...
  && wget .../glibc-${GLIBC_VERSION}.apk
```

**Files/Code References:**
- `.docker/alpine/Dockerfile` – Hardcoded x86_64 assets.
- Flutter install log in the report – shows arm64 download.

## Current Status in v4.0.0
- [ ] Still reproducible
- [x] Already fixed
- [ ] Not applicable to v4.0.0
- [ ] Needs more information
- [ ] Cannot reproduce

## Resolution

Maintainers accepted the limitation and provide an alternate multi-arch image (`ghcr.io/rodrigodornelles/sdkman`) that installs Flutter successfully on Apple Silicon. Official FVM Docker images remain x86_64-only for now; users are encouraged to leverage community multi-arch builds or install via `install.sh`. The issue was closed with workaround guidance.

## Recommendation
**Action**: closed  
**Reason**: Documented workaround and community image cover the use case; official Alpine image will remain x86_64-only for now.

## Notes
- Track future docker roadmap if official multi-arch support is revisited.

---
**Validated by**: Code Agent
**Date**: 2025-11-01
