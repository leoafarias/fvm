# Action Item: Issue #897 – Handle Read-Only Shell Profiles (Nix/Home Manager)

## Objective
Stop the installer from touching shell profiles that are read-only (Home Manager/Nix), so users no longer see `PathAccessException: .../.bash_profile` when running `fvm`.

## Current State (v4.0.0)
- The *only* place we touch `.bashrc`/`.bash_profile`/`.zshrc` is `scripts/install.sh` (and the copy in `docs/public/install.sh`). Runtime Dart code no longer edits shell profiles.
- `update_shell_config()` merely checks `[[ -w "$config_file" ]]` against the symlink itself; when the symlink points inside the Nix store, the append (`>> file`) still fails and Dart surfaces the `PathAccessException`.
- We also auto-create missing files for bash, which is undesirable for managed environments.

## Root Cause
Installer assumes it can create/append to the profile files. In Nix/Home Manager setups those targets are symlinks into read-only locations, so appending fails even though the symlink looks writable.

## Implementation Steps (Installer Only)
1. **Resolve real target before writing**
   - Inside `update_shell_config`, compute `local resolved=$(python - <<<'import os,sys; print(os.path.realpath(sys.argv[1]))' "$config_file")` (or `readlink`/`perl` equivalent available in POSIX shell).
   - If `resolved` doesn’t exist or isn’t writable, bail out immediately (return 1) so the caller falls back to manual instructions.
   - Also check the parent directory is writable when the file doesn’t exist; otherwise skip instead of creating it.
2. **Skip invisible/managed files**
   - For bash: iterate the two candidates, but only call `update_shell_config` when the file exists **and** passes the resolved-path check. Do *not* create `.bash_profile` if it was absent.
   - For zsh/fish, apply the same resolved-path guard.
3. **Clear warning message**
   - When `update_shell_config` returns 1, log a precise reason (e.g., `warn "Skipping ~/.bash_profile; resolved target is read-only. Add PATH manually."`). Capture the tilde form for readability.
   - Keep the existing manual instructions so users know exactly what to paste.
4. **Parity for `docs/public/install.sh`**
   - Mirror the same logic in the published installer so curl/bash installs behave identically.
5. **Regression test (script)**
   - In `scripts/install.sh`’s integration tests (if any) or manual QA checklist, simulate `ln -s /nix/store/... ~/.bash_profile` and verify the script reports “skipping” and exits zero without throwing.

## Files to Modify
- `scripts/install.sh`
- `docs/public/install.sh`
- `docs/pages/documentation/getting-started/installation.mdx` (brief note pointing Nix/Home Manager users to manual PATH instructions and explaining the new “skipped” message they’ll see)

## Validation & Testing
- Run installer in a simulated read-only environment and ensure no exceptions are thrown and messaging is informative.
- Execute `dart test` for new unit tests.

## Completion Criteria
- Installer never attempts to create/append when the resolved target is read-only; users see a warning plus manual steps instead of a crash.
- Documentation explains what the warning means and how Nix/Home Manager users should update PATH manually.
- Issue #897 (and duplicates like #799) can be closed after confirmation.

## References
- Planning artifact: `issue-triage/artifacts/issue-897.md`
- GitHub issue: https://github.com/leoafarias/fvm/issues/897
