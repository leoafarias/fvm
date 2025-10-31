# Issue Triage Log

**Started**: 2025-10-30
**Current Version**: v4.0.0
**Total Issues**: 81

## Progress Tracker

### P0 - Critical (Documentation/Setup Blockers)
- [x] #944 – Documentation install link 404 (triaged 2025-10-30)
- [x] #915 – Getting Started links 404 / Quick Start guidance (triaged 2025-10-30)

### P1 - High (Installation/Major Issues)
- [x] #940 – Homebrew build fails with Dart 3.2.6 (triaged 2025-10-30)
- [x] #938 – `fvm doctor` crashes resolving missing symlink (triaged 2025-10-30)
- [x] #914 – Windows git safe.directory error surfaced as “git not found” (triaged 2025-10-30)
- [x] #897 – Nix/Home Manager read-only shell profile triggers PathAccessException (triaged 2025-10-30)
- [x] #893 – VS Code terminal still resolves global Flutter (triaged 2025-10-30)
- [x] #881 – SSH URLs rejected by fork/config validation (triaged 2025-10-30)
- [x] #801 – FVM fish shell Ctrl+C leaves terminal unusable (triaged 2025-10-30)
- [x] #783 – Use full commit hashes in configs to avoid collisions (triaged 2025-10-30)

### P2 - Medium (Standard Bugs/Enhancements)
- [x] #935 – Request RISC-V install support (triaged 2025-10-30)
- [x] #894 – Shared cache permissions for multi-user hosts (triaged 2025-10-30)
- [x] #880 – Add `--force` to spawn for CI support (triaged 2025-10-30)
- [x] #826 – Publish Winget package (triaged 2025-10-30)
- [x] #821 – VS Code `getFlutterSdkCommand` integration (triaged 2025-10-30)
- [x] #820 – Publish a reusable GitHub Action (`setup-flutter-fvm`) (triaged 2025-10-30)
- [x] #811 – Provide official Nix package support (triaged 2025-10-30)
- [x] #794 – Raspberry Pi installation support (triaged 2025-10-30)
- [x] #786 – Upgrade `dart_console` after removing `interact` (triaged 2025-10-30)
- [x] #771 – Suppress semver warnings for fork/custom names (triaged 2025-10-30)
- [x] #764 – Preserve .fvm/versions symlinks for branch switching (triaged 2025-10-30)
- [x] #762 – Build multi-arch Docker images (triaged 2025-10-30)
- [x] #743 – Simplify VS Code Flutter SDK path management (triaged 2025-10-30)
- [x] #738 – Provide Codespaces devcontainer / Marketplace Docker (`triaged 2025-10-30`)
- [x] #702 – VS Code multi-root workspace should not collapse SDK paths (triaged 2025-10-31)
- [x] #696 – Allow relocating `.fvm` via project config to keep SDK outside repo (triaged 2025-10-31)
- [x] #689 – Provide plain CLI output mode to restore shell completions (triaged 2025-10-31)

### P3 - Low (Minor Issues/Feature Requests)
- [x] #933 – Chocolatey title should spell out Flutter Version Manager (triaged 2025-10-30)
- [x] #839 – `.gitignore` entry missing trailing newline (triaged 2025-10-30)
- [x] #833 – Wildcard support for `fvm remove` (triaged 2025-10-30)
- [x] #825 – README doc link should point to getting-started (triaged 2025-10-30)
- [x] #787 – Optional wrapper scripts for direct `flutter` usage (triaged 2025-10-30)
- [x] #784 – Provide temporary shell env command (triaged 2025-10-30)
- [x] #761 – Surface unknown-command errors (triaged 2025-10-30)
- [x] #751 – Evaluate semver range support (triaged 2025-10-30)

### Already Resolved
- [x] #904 – Kotlin deprecation warning belongs to Flutter (no FVM change)
- [x] #895 – 4.0.0 release now live across package managers
- [x] #884 – `.gitignore` now updated automatically by v4.0.0
- [x] #841 – `fvm global` requires PATH update; working as intended
- [x] #812 – Guidance provided for global vs project configuration
- [x] #807 – FVM cache directory configurable via env vars
- [x] #805 – Auto hot reload is out of FVM scope
- [x] #799 – Duplicate of shell profile permission issue (#897)
- [x] #791 – Fork versions already namespaced via alias/version
- [x] #719 – Rerouting docs already published in “Running Flutter” guide (triaged 2025-10-31)
- [x] #715 – Older Flutter versions need a system JDK; FVM works as designed (triaged 2025-10-31)
- [x] #697 – Android Studio must target `.fvm/default`; document the global workflow (triaged 2025-10-31)

### Version Specific (v3.x only)
- [ ] Needs triage

### Needs More Info
- [x] #906 – Android Studio terminal slow after `fvm use` (awaiting logs)
- [x] #809 – Sidekick upgrade blocked by alleged local changes (awaiting reproduction)
- [x] #797 – Investigate `env: bash\r` error & IDE PATH warning
- [x] #781 – Chocolatey install missing fvm.exe (awaiting verbose logs)
- [x] #767 – Windows Android Studio path keeps reverting (awaiting details)
- [x] #759 – Need VSCode settings when global Flutter conflicts (`needs_info`)
- [x] #748 – Screenshot-only Windows issue (awaiting details)
- [x] #731 – Screenshot-only cache.git error (awaiting details)

---

## Detailed Triage Results

### Session 1: 2025-10-30
- #944: Confirmed `/documentation/installation` returns 404 while `/documentation/getting-started/installation` resolves. Root cause traced to relative links in `docs/pages/documentation/getting-started/index.md`; implementation plan captured in `artifacts/issue-944.md`.
- #915: Quick Start instructions already include `brew tap`, but the “Next Steps” links still hit `/documentation/installation` 404. Fix piggybacks on #944 (`artifacts/issue-915.md`).
- #940: Homebrew formula bundles Dart 3.2.6 causing `pub get` failure once FVM depends on `pubspec_parse 1.5.0`. Plan recorded in `artifacts/issue-940.md` to raise SDK floor and update tap.
- #938: Reproduced `fvm doctor` stack trace when `android/local.properties` exists but no pinned version. Plan in `artifacts/issue-938.md` to guard missing symlinks.
- #914: Documented automation plan to add git safe.directory entries so Windows installs stop failing (`artifacts/issue-914.md`).
- #935: Install script rejects `riscv64`; outlined plan to add architecture support and ship new binaries (`artifacts/issue-935.md`).
- #933: Chocolatey nuspec shows only “fvm”; documented metadata update to expose “Flutter Version Manager” (`artifacts/issue-933.md`).
- #906: Could not reproduce Android Studio terminal delay; requested timing data and shell config (`artifacts/issue-906.md`).
- #904: Determined Kotlin warning is upstream in Flutter’s Gradle tooling; no FVM fix (`artifacts/issue-904.md`).
- #897: Plan to skip/guard shell profile edits when permissions are managed by Home Manager (`artifacts/issue-897.md`).
- #895: Confirmed FVM 4.0.0 is published (Homebrew + docs) and issue can be closed (`artifacts/issue-895.md`).
- #894: Documented approach for group-writable shared caches (core.sharedRepository, chmod) (`artifacts/issue-894.md`).
- #893: Plan to merge PATH updates into VS Code terminal settings so `flutter` resolves to project SDK (`artifacts/issue-893.md`).
- #884: Confirmed new workflow silently updates `.gitignore`; feature request obsolete (`artifacts/issue-884.md`).
- #881: Expand git URL validation to accept SSH/scp formats for forks and config (`artifacts/issue-881.md`).
- #880: Add `--force` flag to spawn command to propagate non-interactive behavior (`artifacts/issue-880.md`).
- #841: Confirmed PATH configuration requirement; advised documentation reminder (`artifacts/issue-841.md`).
- #839: Ensure `.gitignore` workflow writes a final newline (`artifacts/issue-839.md`).
- #833: Outline wildcard expansion for `fvm remove` (`artifacts/issue-833.md`).
- #826: Plan Winget manifests and automation (`artifacts/issue-826.md`).
- #821: Integrate VS Code command-based SDK resolution (`artifacts/issue-821.md`).
- #820: Author official GitHub Action wrapper (`artifacts/issue-820.md`).
- #811: Draft Nix derivation and upstream plan (`artifacts/issue-811.md`).
- #812: Answered configuration question (docs reference) (`artifacts/issue-812.md`).
- #807: Highlighted existing environment variables for cache path (`artifacts/issue-807.md`).
- #805: Not pursuing hot-reload integration (`artifacts/issue-805.md`).
- #799: Duplicate of shell profile guard (#897) (`artifacts/issue-799.md`).
- #825: Update README documentation link (`artifacts/issue-825.md`).
- #801: Default to inheriting stdio so Ctrl+C works in fish (`artifacts/issue-801.md`).
- #794: Add Linux ARM binaries and install script support (`artifacts/issue-794.md`).
- #791: Confirmed fork namespaced handling already exists (`artifacts/issue-791.md`).
- #786: Replace interact prompts and upgrade dart_console (`artifacts/issue-786.md`).
- #783: Persist 40-char commit hashes in config (`artifacts/issue-783.md`).
- #782: Correct docs for rerouted flutter/dart shims (`artifacts/issue-782.md`).
- #774: Document requirement to expose FVM's dart on PATH (`artifacts/issue-774.md`).
- #771: Adjust version weighting to tolerate custom fork names (`artifacts/issue-771.md`).
- #764: Keep project symlinks stable across git checkouts (`artifacts/issue-764.md`).
- #762: Produce docker images for arm64 via Buildx (`artifacts/issue-762.md`).
- #761: Throw UsageException when command not found (`artifacts/issue-761.md`).
- #751: Investigate semver range constraints (`artifacts/issue-751.md`).
- #743: Point VS Code to .fvm/flutter_sdk or dynamic command (`artifacts/issue-743.md`).
- #738: Publish devcontainer template leveraging FVM Docker image (`artifacts/issue-738.md`).
- #720: Explore auto-install command (`artifacts/issue-720.md`).
- #769: Clarify .fvmrc ancestor lookup behavior (`artifacts/issue-769.md`).
- #768: Declined adding external AI badge (`artifacts/issue-768.md`).
- #757: Documented custom flutter URL support (`artifacts/issue-757.md`).
- #754: Provide install.sh workaround for outdated Xcode (`artifacts/issue-754.md`).
- #724: Clarify Android Studio SDK path configuration (`artifacts/issue-724.md`).

### Session 2: 2025-10-31
- #719: Verified the “Running Flutter” guide documents rerouting bare `flutter`/`dart` commands through FVM; issue can be closed as resolved (`artifacts/issue-719.md`).
- #715: Determined Java toolchain errors stem from missing system JDK when using Flutter 3.7.x; documented workaround and marked as environment issue (`artifacts/issue-715.md`).
- #702: Confirmed multi-root VS Code workspaces get a single `dart.flutterSdkPath`; outlined fix to skip workspace override and document the workflow (`artifacts/issue-702.md`).
- #697: Clarified that `fvm global` only manages the `.fvm/default` symlink and Android Studio must be pointed there; planned doc updates (`artifacts/issue-697.md`).
- #696: Validated request to move `.fvm` outside the project and proposed honoring `.fvmrc cachePath` with docs/tests (`artifacts/issue-696.md`).
- #689: Documented grid-table regression in CLI output and plan for configurable/plain mode to fix shell completions (`artifacts/issue-689.md`).

---

## Summary Statistics
- **Total Triaged**: 63/81
- **P0 Critical**: 2
- **P1 High**: 8
- **P2 Medium**: 17
- **P3 Low**: 9
- **Resolved**: 19
- **Version Specific**: 0
- **Needs Info**: 8
