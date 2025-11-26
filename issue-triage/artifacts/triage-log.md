# Issue Triage Log

**Started**: 2025-10-30
**Current Version**: v4.0.0
**Total Open Issues**: 54
**Historical Issues Triaged**: 81

## Progress Tracker

### P0 - Critical (Documentation/Setup Blockers)
- _No open issues_

### P1 - High (Installation/Major Issues)
- [ ] #688 - FVM still performs Git installs; need archive-based strategy honoring FLUTTER_STORAGE_BASE_URL/FLUTTER_RELEASES_URL mirrors with checksum validation and docs.
- [ ] #783 - Store full 40-char commit hashes in configs; add regression tests.
- [ ] #897 - Home Manager makes ~/.bash_profile read-only; add guards/skip flag so FVM doesn't throw PathAccessException.
- [ ] #914 - Windows installs still require manual git safe.directory config; plan to auto-run git config in GitService.

### P2 - Medium (Standard Bugs/Enhancements)
- [ ] #577 - Allow `fvm install` to read `environment.flutter` from pubspec.yaml (via a new flag or fallback), resolve the constraint to a concrete release, and install that version automatically.
- [ ] #583 - Add an `fvm upgrade` workflow (with `--force`/`--remove-old`) that resolves the latest channel release, installs it, and switches the global SDK without manual remove/global steps.
- [ ] #635 - Stop rewriting VS Code settings with JsonEncoder; update only the dart.flutterSdkPath property while preserving existing comments, indentation, and tabs.
- [ ] #648 - Add constraint-aware tooling: resolve Flutter versions from Dart SDK ranges, run commands against min/max pubspec constraints, and make `fvm dart` fall back to Flutter's bundled Dart instead of a standalone PATH binary.
- [ ] #674 - Introduce command-scoped options in FvmContext so flags like --force/--skip-setup don't need to be threaded through every workflow; add helpers, reset per command, and update docs/tests.
- [ ] #681 - Stop deleting .fvm/versions on each switch; preserve per-version symlinks so branch checkouts keep working, add cleanup tooling, and update docs.
- [ ] #689 - Rich table output lacks a plain/text mode. Add console style toggle (config + CLI flag), auto-fallback for non-TTY, and update docs/tests.
- [ ] #696 - Project.localFvmPath ignores .fvmrc cachePath overrides. Add support for relative/absolute overrides, update docs, and test multi-project scenarios.
- [ ] #697 - Android Studio must be pointed at .fvm/default; FVM already creates the global symlink and does not manage IDE settings.
- [ ] #702 - Workspace-level dart.flutterSdkPath overrides folder-specific settings. Skip writing it when multi-root, rely on per-folder configs, and update docs.
- [ ] #724 - Set Android Studio Flutter SDK path to .fvm/flutter_sdk or rely on FVM automation.
- [ ] #738 - Provide Codespaces devcontainer leveraging existing Docker image.
- [ ] #743 - Consider pointing VS Code to .fvm/flutter_sdk or using getFlutterSdkCommand.
- [ ] #762 - Build Docker image for linux/amd64 and linux/arm64 via Buildx.
- [ ] #764 - Retain per-project version symlinks instead of wiping .fvm/versions.
- [ ] #774 - Docs need a PATH section showing how to expose ~/.fvm/default/bin so global commands like rps can find Dart; update guides before closing.
- [ ] #782 - Update running-flutter docs to replace ${@:1} with "$@" (or add a bash shebang) so rerouted scripts work under /bin/sh; leave open until docs merged.
- [ ] #794 - Add Linux ARM artifacts and update install script to detect Pi architectures.
- [ ] #811 - Create official Nix derivation/flake and upstream to nixpkgs.
- [ ] #820 - Create reusable GitHub Action to install FVM/Flutter with arm support.
- [ ] #821 - Add fvm path command + configure dart.getFlutterSdkCommand / dart.getDartSdkCommand in VS Code workflow.
- [ ] #826 - Add Winget manifests and release automation to mirror Windows binaries.
- [ ] #894 - Add group-shared cache support (git core.sharedRepository, chmod g+rwX, optional cache group config).

### P3 - Low (Minor Issues/Feature Requests)
- [ ] #575 - `fvm flavor <name> <command>` already proxies Flutter commands with the flavor's version without switching; document usage and close.
- [ ] #578 - Create a MacPorts Portfile that installs FVM from GitHub releases, submit it to the MacPorts ports tree, and update docs so macOS users have a Homebrew alternative.
- [ ] #584 - Document the custom Flutter remote feature (`fvm config --flutter-url`, `FVM_FLUTTER_URL`, `FLUTTER_GIT_URL`) and enhance CLI help so users know how to override the clone source.
- [ ] #600 - Expand Android Studio/IntelliJ docs with step-by-step guidance, screenshots, and troubleshooting so users point to `.fvm/flutter_sdk` and understand how dynamic updates work.
- [ ] #607 - Package FVM as a Snap (classic confinement) and evaluate Flatpak viability; update release automation and installation docs accordingly.
- [ ] #720 - Consider `fvm sync` command to auto-install missing versions.
- [ ] #751 - Explore semver constraint parsing for version ranges.
- [ ] #754 - Use install.sh or GitHub release binaries when Homebrew requires newer Xcode.
- [ ] #757 - Use fvm config --flutter-url or fvm fork add to point to Shorebird repo.
- [ ] #761 - Detect leftover args and show unknown command usage error.
- [ ] #784 - Consider `fvm env` command to print PATH exports for temporary sessions.
- [ ] #787 - Assess packaging wrapper scripts; document current PATH-based workflow.
- [ ] #791 - Fork names already namespace versions (alias/version syntax).

### Needs More Info
- [ ] #731 - Screenshot only; request commands and logs.
- [ ] #748 - Screenshot only; request steps and error text.
- [ ] #759 - Need VSCode settings and error output.
- [ ] #767 - Request .idea config and symlink info for Windows.
- [ ] #781 - Request Chocolatey verbose logs and directory listing.
- [ ] #797 - Suspect CRLF line endings in Flutter script; awaiting diagnostics.
- [ ] #809 - Request verbose logs and reproduction outside Sidekick.
- [ ] #906 - Unable to reproduce without timing/log data; need shell config and measurements.

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
- #587: Determined tar ownership errors stem from upstream Flutter behavior on restricted filesystems. Documented TAR_OPTIONS workaround and marked as not planned for FVM changes. **Closed on GitHub** with maintainer comment (`artifacts/issue-587.md`).

### Session 6: 2025-11-01 (Post-Release Sync)
- #940: Homebrew tap now ships Dart 3.6.0 via PR #22; reinstalling from the tap resolves the solver failure. **Closed on GitHub** (`artifacts/issue-940.md`).
- #881: PR #954 loosens git URL validation so SSH/scp remotes work in `fvm fork add` and `fvm config`. **Closed on GitHub** (`artifacts/issue-881.md`).
- #666: Cache integrity check now normalizes version labels (PR #955). **Closed on GitHub** (`artifacts/issue-666.md`).
- #683: Upstream pubspec fix allows hosted overrides without version; FVM no longer crashes. **Closed on GitHub** (`artifacts/issue-683.md`).
- #581: Alpine docker bug closed with documented workaround/community image (`artifacts/issue-581.md`).
- #421: Partial-version install request declined; please use exact releases. **Closed with comment** (`https://github.com/leoafarias/fvm/issues/421#issuecomment-3476844567`).
- #388: IntelliJ multi-package limitation documented; no change planned. **Closed with comment** (`https://github.com/leoafarias/fvm/issues/388#issuecomment-3476845312`).
- #801: Fish shell Ctrl+C fixed in FVM 4.0.0. **Closed with comment** (`https://github.com/leoafarias/fvm/issues/801#issuecomment-3476846075`).

### Session 7: 2025-11-04 (Open Issue Sync)
- Re-ran `gh issue list --state open` (48 issues) and removed closed #771 from the pending queue.
- Regenerated `pending_issues/open_issues.json` via GraphQL so titles/bodies/labels reflect the latest GitHub data.
- Moved reopened items (#575, #697, #724, #754, #757, #791) back into the validated folders and archived closed ones (#771, #786, #825, #833, #880, #933).
- Rebuilt the Progress Tracker and Summary Statistics so action items only list currently open issues.

### Session 8: 2025-11-24 (Open Issue Sync)
- Ran `issue-triage/scripts/sync_github.sh`; pending lists now show 54 open issues and 15 open PRs from GitHub.

### Session 9: 2025-11-24 (PR Alignment)
- PR #972 improves version detection and “Need setup” status; addresses open issue #970 (3.38.x not listed/flagged).
- PR #967 (installer v2, user-local default) mitigates cross-user install/security concerns raised in #974; monitor until merged.
- PR #966 (archive installs) explicitly resolves #688 once merged.
- PR #964 adds read-only shell profile handling; fixes #897.
- PR #962 forces full commit hashes; fixes #783 security concern.
- PR #845 builds arm64 Docker images; fixes #762 multi-arch image gap.
---

## Summary Statistics
- **Open Issues**: 54
- **P0 Critical**: 0
- **P1 High**: 4
- **P2 Medium**: 23
- **P3 Low**: 13
- **Needs Info**: 8
- **Resolved/Archived**: 9
