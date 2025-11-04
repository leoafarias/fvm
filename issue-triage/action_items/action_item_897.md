# Action Item: Issue #897 – Handle Read-Only Shell Profiles (Nix/Home Manager)

## Objective
Prevent `PathAccessException` errors when FVM encounters read-only shell profile files managed by Nix/Home Manager (e.g., `/Users/me/.bash_profile`).

## Current State (v4.0.0)
- `scripts/install.sh` appends to `.bashrc` / `.bash_profile` without checking writability beyond simple shell tests.
- Runtime Dart code may still attempt to open profile files, triggering `PathAccessException` when profiles live in the Nix store.
- Users must manually suppress the warnings or avoid automatic configuration.

## Root Cause
FVM assumes shell profiles are user-writable. In Nix-managed environments, profile files reside in read-only paths, so attempts to open or write to them fail.

## Implementation Steps
1. Reproduce the scenario:
   - On macOS/Linux, simulate read-only profiles (`chmod 444 ~/.bash_profile`, etc.) or use a Nix/Home Manager environment.
   - Capture stack traces to confirm the failing code path (installer vs. runtime).
2. Harden installer/runtime logic:
   - Wrap all profile reads/writes in try/catch and skip when `FileSystemException` indicates lack of permissions.
   - Introduce `FVM_SKIP_SHELL_CONFIG=true` (or `fvm config --skip-shell-config`) so users can opt out entirely.
   - Detect Home Manager-managed paths (e.g., by checking parent directories or `stat` info) and log a friendly warning instead of failing.
3. Update `scripts/install.sh` to run explicit checks (`test -w`, `stat -f %Su`) before editing, and provide actionable messaging when skipping.
4. Document the new flag/workflow in `docs/pages/documentation/getting-started/installation.mdx` (Nix/Home Manager section) including manual PATH export instructions.
5. Add automated tests:
   - Unit tests covering the new skip logic.
   - Integration test that simulates read-only files via temporary directories with restricted permissions.

## Files to Modify
- `scripts/install.sh`
- `lib/src/environment/shell_service.dart` (or relevant config writers)
- `lib/src/runner/runner.dart` (catch and downgrade exceptions)
- `docs/pages/documentation/getting-started/installation.mdx`

## Validation & Testing
- Run installer in a simulated read-only environment and ensure no exceptions are thrown and messaging is informative.
- Execute `dart test` for new unit tests.

## Completion Criteria
- FVM gracefully skips shell profile updates when profiles are read-only, offering opt-out guidance.
- Documentation updated; issue #897 closed after users confirm fix.

## References
- Planning artifact: `issue-triage/artifacts/issue-897.md`
- GitHub issue: https://github.com/leoafarias/fvm/issues/897
