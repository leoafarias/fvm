# Issue #762: [Feature Request] Support arm64 docker images

## Metadata
- **Reporter**: @AngeloAvv
- **Created**: 2024-08-23
- **Issue Type**: feature request
- **URL**: https://github.com/leoafarias/fvm/issues/762

## Problem Summary
Docker image currently built for amd64 only. Need arm64 variant for Ampere cloud machines.

## Proposed Implementation Plan
1. Update `.github/workflows/deploy_docker.yml` to build multi-arch images (`platforms: linux/amd64,linux/arm64`) using Buildx.
2. Ensure Dockerfile is architecture neutral (no prebuilt binaries). If necessary, download correct Dart SDK/Flutter packages for each arch.
3. Consider tag naming (e.g., include `-arm64`).

## Classification Recommendation
- Priority: **P2 - Medium**
- Suggested Folder: `validated/p2-medium/`
