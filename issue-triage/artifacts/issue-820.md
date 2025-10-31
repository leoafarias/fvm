# Issue #820: [Feature Request] setup-flutter-fvm action - mainly for aarch64/arm64 builds.

## Metadata
- **Reporter**: @jochumdev
- **Created**: 2025-02-05
- **Reported Version**: GitHub Actions integration
- **Issue Type**: feature request
- **URL**: https://github.com/leoafarias/fvm/issues/820

## Problem Summary
The reporter built a custom `setup_fvm.sh` script for CI and proposes collaborating on an official `setup-flutter-fvm` GitHub Action, especially with ARM support.

## Version Context
- Current repo already uses a local `.github/actions/prepare` composite action for internal workflows, but no reusable marketplace action exists.

## Validation Steps
1. Inspect `.github/actions/prepare` – installs Dart, runs `dart pub get`, etc., but tailored for internal release workflows.
2. No packaged GitHub Marketplace action currently advertised.

## Proposed Implementation Plan
1. Create a composite action under `.github/actions/setup-fvm` or separate repo to:
   - Install system dependencies (curl/git) if needed.
   - Download/install FVM binary for the requested version (default latest).
   - Optionally install a Flutter channel/version via inputs.
   - Add FVM bin to PATH and cache the `~/.fvm` directory using GitHub cache action.
2. Provide inputs: `fvm-version`, `flutter-version`, `architecture`, `cache`, etc.
3. Add documentation in `docs/pages/documentation/guides/ci.mdx` covering usage.
4. Publish the action on the GitHub Marketplace (tag semver). Add integration tests via workflow dispatch.
5. Coordinate with reporter to incorporate arm64 compatibility patterns from their script.

## Classification Recommendation
- Priority: **P2 - Medium** (improves CI usability)
- Suggested Folder: `validated/p2-medium/`

## Notes for Follow-up
- Consider bundling with existing release automation or providing separate repo for easier maintenance.
