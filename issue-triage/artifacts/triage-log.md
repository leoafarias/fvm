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
- [x] #881 – SSH URLs rejected by fork/config validation (triaged 2025-10-30)
- [x] #801 – FVM fish shell Ctrl+C leaves terminal unusable (triaged 2025-10-30)
- [x] #783 – Use full commit hashes in configs to avoid collisions (triaged 2025-10-30)
- [x] #683 – Hosted dependency overrides without versions crash the parser (triaged 2025-10-31)
- [x] #688 – Add archive install strategy honoring `FLUTTER_STORAGE_BASE_URL` mirrors (triaged 2025-10-31)
- [x] #666 – Normalize cache vs requested versions to avoid false mismatch prompts (triaged 2025-10-31)
- [x] #587 – Mirror Flutter’s TAR_OPTIONS so container installs succeed (triaged 2025-10-31)
- [x] #581 – Publish multi-arch Docker images so installs succeed on arm64 (triaged 2025-10-31)

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
- [x] #681 – Preserve project `.fvm/versions` symlinks for branch switching (triaged 2025-10-31)
- [x] #674 – Store command flags in context instead of threading parameters (triaged 2025-10-31)
- [x] #648 – Resolve Flutter versions from Dart constraints and improve Dart fallback (triaged 2025-10-31)
- [x] #635 – Update VS Code settings without stripping comments or tabs (triaged 2025-10-31)
- [x] #583 – Provide an upgrade workflow for the global SDK (triaged 2025-10-31)
- [x] #577 – Let `fvm install` resolve pubspec flutter constraints (triaged 2025-10-31)
- [x] #421 – Resolve partial semver inputs like `fvm install 2` to latest releases (triaged 2025-10-31)

### P3 - Low (Minor Issues/Feature Requests)
- [x] #933 – Chocolatey title should spell out Flutter Version Manager (triaged 2025-10-30)
- [x] #839 – `.gitignore` entry missing trailing newline (triaged 2025-10-30)
- [x] #833 – Wildcard support for `fvm remove` (triaged 2025-10-30)
- [x] #825 – README doc link should point to getting-started (triaged 2025-10-30)
- [x] #787 – Optional wrapper scripts for direct `flutter` usage (triaged 2025-10-30)
- [x] #784 – Provide temporary shell env command (triaged 2025-10-30)
- [x] #761 – Surface unknown-command errors (triaged 2025-10-30)
- [x] #751 – Evaluate semver range support (triaged 2025-10-30)
- [x] #607 – Provide Snap/Flatpak distribution options for Linux (triaged 2025-10-31)
- [x] #600 – Clarify Android Studio/IntelliJ FVM setup in docs (triaged 2025-10-31)
- [x] #584 – Document custom Flutter Git remotes (`flutterUrl`) (triaged 2025-10-31)
- [x] #578 – Publish a MacPorts port so macOS users have a Homebrew alternative (triaged 2025-10-31)

### Already Resolved
- [x] #904 – Kotlin deprecation warning belongs to Flutter (no FVM change)
- [x] #895 – 4.0.0 release now live across package managers
- [x] #893 – VS Code terminal PATH handled by Dart Code extension (working as intended)
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
- [x] #575 – `fvm flavor` already runs commands on flavor-defined SDKs (triaged 2025-10-31)
- [x] #388 – IntelliJ supports only one Flutter SDK per project; document limitation (triaged 2025-10-31)

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
- #688: Planned archive-based installs so mirrored storage URLs work without Git/GCS access (`artifacts/issue-688.md`).
- #683: Identified `pubspec` parser bug for hosted overrides without versions and outlined sanitizer/upstream fix (`artifacts/issue-683.md`).
- #681: Proposed keeping per-version project symlinks instead of deleting `.fvm/versions` so branch switching works seamlessly (`artifacts/issue-681.md`).
- #674: Designed context-based command options to remove repetitive flag plumbing across workflows (`artifacts/issue-674.md`).
- #666: Planned semantic normalization for version mismatch detection so non-numeric tags stop triggering repairs (`artifacts/issue-666.md`).
- #648: Outlined constraint-aware tooling (resolve by Dart version, min/max exec, better dart fallback) (`artifacts/issue-648.md`).
- #635: Proposed comment-preserving JSONC editor so `.vscode/settings.json` keeps user formatting (`artifacts/issue-635.md`).
- #607: Planned Snap packaging (classic confinement) and evaluated Flatpak support for Linux users (`artifacts/issue-607.md`).
- #600: Identified gaps in Android Studio docs and outlined clearer configuration steps with screenshots (`artifacts/issue-600.md`).
- #587: Planned to set `TAR_OPTIONS=--no-same-owner` when running flutter to avoid tar ownership failures in containers (`artifacts/issue-587.md`).
- #584: Will document how to override the Flutter Git remote via config/env (`artifacts/issue-584.md`).
- #583: Designed an `fvm upgrade` command (plus `--force` removal) to streamline global updates (`artifacts/issue-583.md`).
- #581: Migrate Docker image to glibc base and build multi-arch variants to fix arm64 installs (`artifacts/issue-581.md`).
- #578: Planned creation of a MacPorts Portfile and documentation updates (`artifacts/issue-578.md`).
- #577: Planned pubspec constraint resolution for `fvm install --pubspec` (`artifacts/issue-577.md`).
- #421: Planned partial-version resolution so `fvm install 2` picks the newest Flutter 2 release (`artifacts/issue-421.md`).
- #388: Documented Android Studio's single-SDK limitation and suggested workarounds (`artifacts/issue-388.md`).

### Session 3: 2025-10-31 (Closure Session)
- #884: Closed as resolved in v4.0.0 - `.gitignore` auto-update now built-in and working with `--force` and `--skip-setup` flags.
- #807: Closed as already supported - `FVM_CACHE_PATH` (primary) and `FVM_HOME` (legacy) environment variables documented.
- #805: Closed as out of scope - hot reload functionality belongs to Flutter/IDEs, not version management tools.
- #812: Closed with comprehensive answer - FVM automatically uses project `.fvmrc` versions when in project, global otherwise.
- #904: Closed as upstream Flutter issue - Kotlin deprecation warning originates from Flutter's `flutter_tools`, not FVM code.
- #719: Already closed (merged docs) - rerouting `flutter`/`dart` commands documented in running-flutter guide.
- #768: Already closed - external AI badge not aligned with FVM roadmap.
- #769: Already closed - ancestor directory `.fvmrc` lookup is intentional design (monorepo/workspace support).

**Android Studio Research Findings Updated**: Consolidated guidance and action plan for IDE automation now lives at `artifacts/android-studio-research.md`.

### Session 4: 2025-10-31 (Resolved Audit)
- #388: Re-validated Android Studio multi-module limitation; prepared closure guidance and left issue in `resolved/` (`artifacts/issue-388.md`).
- #575: Confirmed `fvm flavor` already proxies flavor-specific SDKs; ready to close with usage examples (`artifacts/issue-575.md`).
- #697: Verified global symlink behavior and doc updates; closure comment drafted to direct Android Studio to `~/.fvm/default` (`artifacts/issue-697.md`).
- #724: Checked IDE workflow docs now highlight `.fvm/flutter_sdk`; closure reply drafted (`artifacts/issue-724.md`).
- #754: Homebrew/Xcode constraint documented with install script workaround; safe to close (`artifacts/issue-754.md`).
- #757: Custom Flutter repository support confirmed via `--flutter-url` / fork workflow; closure reply drafted (`artifacts/issue-757.md`).
- #774: Documentation gap on exporting `~/.fvm/default/bin` persists—moved to `validated/p2-medium` with doc update plan (`artifacts/issue-774.md`).
- #782: `Bad substitution` doc bug still reproducible—moved to `validated/p2-medium` with fix plan (`artifacts/issue-782.md`).
- #801: Fish shell Ctrl+C issue fixed in v4.0.0; ready to close with upgrade guidance (`artifacts/issue-801.md`).
- #791: Fork namespace handling already implemented; closure comment ready (`artifacts/issue-791.md`).
- #799: Duplicate of #897; closure note prepared pointing users to canonical bug (`artifacts/issue-799.md`).

### Session 5: 2025-10-31 (Investigation & Closure)
- #893: Investigated VS Code terminal PATH integration with FVM. Confirmed that Dart Code extension v3.60.0+ handles terminal PATH injection automatically via `dart.addSdkToTerminalPath` setting (enabled by default). FVM correctly updates `dart.flutterSdkPath`, and terminal integration should work with FVM v4 + modern Dart Code versions. Reclassified from P1-High to resolved/working-as-intended. **Closed on GitHub** with upgrade guidance (`artifacts/issue-893.md`).

---

## Summary Statistics
- **Total Triaged**: 81/81
- **P0 Critical**: 2
- **P1 High**: 10
- **P2 Medium**: 26
- **P3 Low**: 13
- **Closed on GitHub**: 17
- **Resolved (not yet closed)**: 9
- **Version Specific**: 0
- **Needs Info**: 8
