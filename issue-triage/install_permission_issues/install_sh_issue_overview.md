# Install.sh Issue Themes and User Complaints (as of 2025-11-06)

## Scope and Method
- Source set: 17 GitHub issues/PRs in `issue-triage/install_permission_issues/` filtered to threads focussing on the behaviour of `scripts/install.sh`.
- Data captured on 2025-11-06 using `gh issue view --json` (see `issue-<number>.json` for verbatim details and full comment histories).
- This report synthesises recurring complaints, affected environments, and remediation efforts described across those issues.

## High-Level Complaint Themes
| Theme | Impacted Issues | Summary of User Feedback |
| --- | --- | --- |
| **Permissions & Symlink Targeting** | #699, #785, #796, #816, #830, #832, #864, #909 | Users on Linux and macOS repeatedly hit `ln: failed to create symbolic link '/usr/local/bin/fvm': Permission denied` or missing target errors. Reports note that `/usr/local/bin` often requires sudo, that the script should default to `$HOME/.local/bin`, auto-create the directory, or allow overrides. Root-only environments (CI/containers) complain about the root block (`This script should not be run as root`). |
| **Script Configurability & PATH Management** | #700, #830, #857, #862, #909, #932 | Requests/PRs aim to automate PATH updates, add an `update.sh`, skip redundant installs, and provide `SYMLINK_DIR`/`FVM_DIR` knobs so users can avoid privileged paths while keeping shell profiles in sync. |
| **Download/Version Resolution Reliability** | #818, #907, #908, #909, #932, #949 | Reports of `Failed to fetch latest FVM version`, 404s when passing `v`-prefixed tags, stale fallback downloads, and inconsistent version/tag handling prompted fixes for version normalization, better curl flags, retries, and clearer errors. |
| **Platform & Architecture Coverage Gaps** | #832, #864, #907, #908, #932, #946, #949 | Complaints stem from Alpine/musl containers, Codex root environments, missing RISC-V binaries, and general Linux distro variance. Follow-up work adds musl detection, Alpine CI, root-handling overrides, and RISC-V architecture support. |

## Issue-by-Issue Commentary
| Issue | Title | State | Reporter | Created |
| --- | --- | --- | --- | --- |
| #699 | [BUG] The `install.sh` script uses `/usr/local/bin/fvm` as a link target which requires sudo privileges | CLOSED | Nidal-Bakir | 2024-03-22 |
| #700 | feat: automatically add `~/.fvm_flutter/bin` to the PATH var in `install.sh` and introduce `update.sh` | MERGED | Nidal-Bakir | 2024-03-22 |
| #785 | Update install.sh | MERGED | gaetan1903 | 2024-09-30 |
| #796 | [BUG] Failed to create symlink. | CLOSED | khoirul-mustofa | 2024-11-10 |
| #816 | [BUG] MacOs installation with install.sh throws "error: Failed to create symlink." | CLOSED | alestiago | 2025-01-28 |
| #818 | [BUG] error: Failed to fetch latest FVM version. | CLOSED | victorteokw | 2025-02-05 |
| #830 | feat: accept bin dir as variable to installation script | CLOSED | alexandradeas | 2025-03-13 |
| #832 | [BUG] fails to install on linux | CLOSED | sgehrman | 2025-03-21 |
| #857 | Add upgrade logic to install.sh | CLOSED | leoafarias | 2025-06-06 |
| #862 | feat: enhance install script with comprehensive improvements and testing | MERGED | leoafarias | 2025-06-06 |
| #864 | [BUG] install.sh now fails in docker images that run as root | CLOSED | Peetee06 | 2025-06-07 |
| #907 | [WIP] Improve install.sh robustness (version tag normalization, musl support, symlink dir creation, precise uninstall) + add Alpine CI validation | CLOSED | app/copilot-swe-agent | 2025-09-12 |
| #908 | Improve install.sh robustness and compatibility | CLOSED | leoafarias | 2025-09-12 |
| #909 | Fix essential install.sh issues | CLOSED | leoafarias | 2025-09-12 |
| #932 | feat: upgrade installation scripts to v3.0.0 | CLOSED | leoafarias | 2025-09-30 |
| #946 | Add RISC-V (riscv64) architecture support | MERGED | leoafarias | 2025-10-30 |
| #949 | fix: Enhance install.sh with Alpine/musl support and better error handling | MERGED | leoafarias | 2025-10-31 |

### Detailed Notes
- **#699** – Original permission-denied report for Ubuntu. Highlights the conflict between `/usr/local/bin` and non-root installs, with users later confirming the problem persists into 2025. Workarounds involve patched scripts, creating `$HOME/.local/bin`, and manually exporting PATH.
- **#700** – Companion PR responding to #699. Adds PATH automation (`~/.fvm_flutter/bin`) and introduces `update.sh` so future updates do not require manual edits. Comments include deployment coordination.
- **#785** – Linux complaint emphasising that using sudo places files under `/root/.fvm`, leaving the invoking user without a working binary. Reinforces the need for non-root-friendly target directories.
- **#796** – Pop!_OS user reiterates the symlink permission failure. Even `sudo curl … | bash` fails because the pipe executes without sustained elevation. Workaround: download first, then run `sudo bash` on the local script.
- **#816** – macOS 15.3 report where `/usr/local/bin` does not exist by default on Apple Silicon, yielding `ln: … No such file or directory`. Shows the script must ensure the directory exists on macOS too.
- **#818** – macOS user hits `error: Failed to fetch latest FVM version.` immediately, implying brittle latest-version detection or silent fallback behaviour.
- **#830** – Enhancement PR allowing installers to set `SYMLINK_DIR` to something other than `/usr/local/bin`, directly addressing the “need sudo” complaint. Documentation examples included.
- **#832** – Linux user logs the exact permission denied output even under sudo, matching the #699/#796 failures. Multiple commenters ask whether the project is still active, underscoring frustration over unresolved installs.
- **#857** – Adds skip/upgrade logic so rerunning the script does not reinstall unnecessarily and warns when another version is present. Exercises the workflow in CI.
- **#862** – Large refactor focussing on code quality, security, input validation, download verification, and comprehensive tests. Temporarily removes lesser-used architectures (armv7l, ia32, riscv64).
- **#864** – Codex (root container) regression: install script aborts with “This script should not be run as root,” blocking automation. Reporter details attempted workarounds (creating a dedicated user, copying binaries) and notes that the issue only appeared after a script update.
- **#907** – Draft plan with six improvements: version/tag normalization, musl detection with fallbacks, privileged directory creation, fish shell improvements, precise uninstall logic, and Alpine CI coverage. Serves as roadmap for subsequent fixes.
- **#908** – Implements robustness improvements: musl detection, version fallback URLs, auto `mkdir -p`, privilege escalation, improved messaging, `chmod +x`, and expanded validation.
- **#909** – Minimal-risk PR focussed on four urgent fixes: fish PATH syntax, safe symlink removal, auto-create `/usr/local/bin`, and enforcing execute permissions.
- **#932** – Major v3.0.0 upgrade: richer environment detection, Rosetta awareness, multi-shell PATH configuration, new uninstall script, Alpine tests, and Grinder tasks to keep docs/public scripts in sync.
- **#946** – Adds RISC-V (riscv64) architecture detection across the install scripts and documentation, acknowledging new binary availability.
- **#949** – Comprehensive bugfix covering version normalization (`v` prefix), musl asset selection, stale fallback installations, and adds 32-bit ARM support plus defensive checks. Validates download URLs and notes shellcheck/test coverage.

## Observations & Gaps
- Permission-related pain points dominated user complaints from March 2024 through early 2025. Comments in #699 (May 2025) suggest the hosted script lagged behind merged fixes, indicating a release/deployment gap.
- Root/CI usage is common. Strict root blocking caused regressions (#864). Later work references `FVM_ALLOW_ROOT`, but the behaviour should remain documented and tested.
- Architecture and libc support evolved: older PRs removed speculative platforms, while later fixes reintroduced musl and RISC-V when concrete demand emerged (#949, #946).
- Users expect deterministic behaviour: normalised version tags, reliable error messaging, and explicit PATH management reduce confusion during first-time installs.

## Recommended Follow-Ups
1. **Deployment Audit** – Ensure `docs/public/install.sh` and the hosted `https://fvm.app/install.sh` update immediately after script changes to prevent the divergence noted in #699.
2. **Root/CI Strategy** – Document and test the intended behaviour for root installations (e.g., via `FVM_ALLOW_ROOT=1`) so Codex and other CI users have a sanctioned path.
3. **Permission-Free Defaults** – Confirm `$HOME/.local/bin` (or configurable `SYMLINK_DIR`) is now the default in hosted scripts, and highlight prerequisites (creating the directory) in docs.
4. **Version Fetch Diagnostics** – Verify that latest-version detection fails loudly and never falls back silently to stale versions (#818, #949).
5. **Compatibility Matrix** – Maintain automated testing across musl, RISC-V, and standard glibc environments to prevent regressions like those seen in #832/#864.

For verbatim discussions, consult the individual JSON artifacts in `issue-triage/install_permission_issues/`.
