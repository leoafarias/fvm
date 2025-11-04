# Action Item: Issue #811 – Publish an Official Nix Package

## Objective
Provide and maintain an official Nix/NixOS package (and optional flake) so Nix users can install FVM without crafting custom derivations.

## Current State (v4.0.0)
- Repository contains no `.nix` files (`rg -g"*.nix" --files` returns empty).
- `.github/workflows/release.yml` ships to Pub, Homebrew, Chocolatey, Docker; no Nix step exists.
- Users rely on community gists to build FVM in Nix, which requires manual hash updates per release.

## Root Cause
The release automation never produces or publishes a Nix derivation, so there is no authoritative package or automation to keep Nix installs current.

## Implementation Steps
1. Author an official derivation (e.g., `nix/fvm.nix` or a flake) that:
   - Fetches the GitHub release tarball for the current version.
   - Installs the CLI binary and shell completions into the Nix store.
   - Declares metadata (`pname`, `version`, `src`, `license = licenses.mit`).
2. Add automation to keep the derivation updated:
   - Extend `release.yml` with a job (Windows or Linux runner) that computes the new tarball SHA via `nix hash file` and updates the derivation/flake version.
   - Commit the updated derivation as part of the release pipeline or open an automated PR.
3. Publish / upstream:
   - Option A: Maintain `nix` artifacts in this repository and document `nix registry add fvm git+https://...` for immediate use.
   - Option B: Submit the package to `nixpkgs` (`pkgs/development/tools/flutter/fvm.nix`) and keep it in sync post-release (preferred long-term).
4. Document the installation path in `docs/pages/documentation/getting-started/installation.mdx` (Windows/Linux tab) referencing the new Nix option.
5. (Optional) Configure a binary cache (e.g., Cachix) for faster installs; out of scope for MVP but note trade-offs.
6. Add basic CI verification (e.g., `nix build ./nix#fvm` or `nix flake check`) to ensure the derivation stays valid.

## Files to Add/Modify
- `nix/fvm.nix` (and/or `flake.nix` / `flake.lock` if using flakes)
- `.github/workflows/release.yml`
- `docs/pages/documentation/getting-started/installation.mdx`
- (Optional) `nix/README.md` explaining usage

## Validation & Testing
- Run `nix build` (for derivation) or `nix flake check` to ensure the package builds on Linux.
- Smoke-test the installed CLI (`nix shell` → `fvm --version`).
- Confirm release workflow updates hashes automatically during a dry-run release.

## Completion Criteria
- Official derivation committed and documented, with automation updating version + sha256 per release.
- Installation instructions for Nix present in docs.
- Issue #811 updated with release details and closed.

## References
- Planning artifact: `issue-triage/artifacts/issue-811.md`
- GitHub issue: https://github.com/leoafarias/fvm/issues/811
