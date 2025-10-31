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
- [x] Still reproducible
- [ ] Already fixed
- [ ] Not applicable to v4.0.0
- [ ] Needs more information
- [ ] Cannot reproduce

## Troubleshooting/Implementation Plan

### Root Cause Analysis
The container image assumes x86_64 and Alpine’s glibc compatibility layer. On Apple Silicon (or any arm64 host), Docker runs an arm64 variant of the base image, but we still install x86_64 artifacts, breaking the toolchain.

### Proposed Solution
1. **Migrate to a glibc-based base image** (e.g., `debian:bookworm-slim`):
   - Avoid the sgerrand glibc shim entirely.
   - Install required packages (`curl`, `git`, `unzip`, `xz-utils`, etc.).
2. **Publish multi-arch images (amd64 + arm64):**
   - Use `docker buildx build --platform linux/amd64,linux/arm64`.
   - Ensure we download the matching FVM binary (`fvm-<ver>-linux-x64` or `-linux-arm64`) for each architecture.
   - Update release automation to build and push to GHCR/Docker Hub on every tag.
3. **Verify Flutter install in both variants:**
   - Run `fvm install stable` in the container during CI to catch regressions.
4. **Update documentation:**
   - Mention the new image name/location and provide sample usage (`docker run --rm ghcr.io/leoafarias/fvm:latest fvm install stable`).

### Alternative Approaches
- Keep Alpine but add `qemu-user-static` to emulate x86_64. Adds complexity/performance cost; switching to Debian is simpler.

### Dependencies & Risks
- Need to produce and host arm64 FVM binaries (ensure release pipeline already does this or add build step).
- Multi-arch build increases CI runtime; cache layers appropriately.

### Related Code Locations
- `.github/workflows/release.yml` (or equivalent) – extend to build/publish Docker images.
- `docs/pages/documentation/getting-started/installation.mdx` – update Docker instructions.

## Recommendation
**Action**: validate-p1

**Reason**: The official Docker image is broken on Apple Silicon (increasingly common); fixing/publishing multi-arch images restores expected functionality.

## Notes
- Consider adding a minimal Alpine-based image later if size matters, but ensure both architectures are supported.

---
**Validated by**: Code Agent
**Date**: 2025-10-31
