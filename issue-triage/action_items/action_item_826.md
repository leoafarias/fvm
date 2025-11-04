# Action Item: Issue #826 – Add Winget Distribution

## Objective
Ship an official Winget package so Windows users can install/update FVM through Microsoft’s package manager, reducing reliance on Chocolatey.

## Current State (v4.0.0)
- `.github/workflows/release.yml` deploys to Pub, Homebrew, Chocolatey, Docker only.
- No Winget manifest exists in the repository or in the `microsoft/winget-pkgs` index for FVM.

## Root Cause
Release automation never produces Winget manifests or submits them to the Winget community repo, leaving Windows users dependent on slower Chocolatey updates.

## Implementation Steps
1. Create Winget manifests (portable or installer) following the official schema:
   - Add files under `.winget/Fvm/Fvm/<version>/` (or similar) containing `installer`, `defaultLocale`, and `version` manifests.
   - Point the installer URL to the existing Windows zip asset published on each GitHub release.
2. Extend `release.yml` with a Windows job after Chocolatey deploy that:
   - Downloads the new release artifact.
   - Uses `wingetcreate update` (or `wingetcreate submit`) to regenerate manifests with the new version/sha256.
   - Opens a PR against `microsoft/winget-pkgs` using a PAT stored in repo secrets (Winget review is manual, expect delays).
3. Update documentation (`docs/pages/documentation/getting-started/installation.mdx`) with Winget install instructions (`winget install --id Fvm.Fvm -e`).
4. Consider adding a fallback manual script explaining how to install from GitHub while Winget PR is pending review.
5. Ensure licensing and silent install requirements are met; Winget portable installers must support unattended install.

## Files to Add/Modify
- `.winget/**` (new manifest directory)
- `.github/workflows/release.yml`
- `docs/pages/documentation/getting-started/installation.mdx`

## Validation & Testing
- Run `wingetcreate validate` locally (or in CI) to confirm manifests are well-formed.
- Perform a `winget install --manifest <local path>` dry run to ensure the installer works.
- Verify the release workflow successfully opens a PR to `microsoft/winget-pkgs`.

## Completion Criteria
- Winget manifests added, automated update path in place, and documentation updated.
- Issue #826 updated with timeline + link to Winget PR and closed once merged.

## References
- Planning artifact: `issue-triage/artifacts/issue-826.md`
- GitHub issue: https://github.com/leoafarias/fvm/issues/826
