# Issue #738: [Feature Request] publish fvm DockerFile to github marketplace

## Metadata
- **Reporter**: @Alvish0407
- **Created**: 2024-06-10
- **Issue Type**: feature request
- **URL**: https://github.com/conceptadev/fvm/issues/738

## Problem Summary
Request for a preconfigured Dockerfile/devcontainer for GitHub Codespaces. FVM already ships a Dockerfile (`.docker/Dockerfile`) but not a published devcontainer template.

## Version Context
- Current target: FVM 4.1.2 / current `origin/main`.
- The repository still has `.docker/Dockerfile`, but no `.devcontainer/` template or Codespaces configuration.

## Validation Steps
1. Checked current `origin/main` for Docker and devcontainer files.
2. Confirmed `.docker/Dockerfile` exists and is used by release workflows.
3. Confirmed no `.devcontainer/devcontainer.json` or published template metadata exists.

## Evidence
```text
.docker/Dockerfile                         present
.github/workflows/deploy_docker.yml       present
.devcontainer/devcontainer.json           absent
```

## Current Status in v4.1.2
- [x] Still applicable
- [ ] Already implemented
- [ ] Needs more information

## Troubleshooting/Implementation Plan
- Create `.devcontainer/devcontainer.json` referencing FVM Docker image and publish to GitHub Marketplace.
- Add a smoke workflow that opens a sample Flutter project, installs its pinned SDK, and runs `flutter --version`.
- Document image tags, supported architectures, cache persistence, and Codespaces usage.

## Recommendation
- Priority: **P2 - Medium**
- Suggested Folder: `validated/p2-medium/`
