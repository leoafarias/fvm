# FVM 5 binary-first migration plan

> Move FVM 5 to a standalone-CLI distribution without stranding existing
> pub.dev users, then validate every supported release channel before the
> stable cutover.

- Status: Checkpoint A implemented; release and platform milestones proposed
  for review
- Base: `origin/release/5.0` at `0453eb80`
- Working branch: `fvm-5-binary-migration`
- Reviewed: 2026-07-20
- Checkpoint A environment: Dart `3.10.7` on macOS arm64

## Objective

- Ship the FVM 5 CLI as a standalone binary. Users must not need a Dart SDK to
  run the released CLI.
- Use the latest stable Dart SDK as the FVM 5 source and build floor. As of this
  review, that is Dart `3.12.2`, so the initial FVM 5 constraint is
  `>=3.12.2 <4.0.0` and release jobs are pinned to `3.12.2`.
- Publish one final FVM 4 bridge release to pub.dev. It keeps the FVM 4 Dart
  compatibility floor, discovers updates from GitHub Releases, and directs
  users to the standalone installation path when FVM 5 becomes stable.
- Preserve FVM configuration, Flutter SDK caches, project references, command
  exit codes, and command behavior while changing update discovery and
  distribution.
- Treat the CLI as the minimum FVM 5 deliverable. The separately versioned
  `fvm_mcp` package remains compatible with the CLI but does not block the CLI
  migration or get embedded into `fvm` in this plan.

### Out of scope

- A pub.dev bootstrap or wrapper package for FVM 5.
- An in-place `fvm update` command or automatic binary replacement. Package
  managers and the install scripts remain responsible for installation.
- New Flutter SDK-management behavior, cache layouts, Git operations, or
  project configuration formats.
- Embedding the MCP server into the CLI.
- Replacing `cli_pkg` merely for cleanup. Its archive-building behavior can be
  retained while the workflow around it is made deterministic.

## Decisions already made

1. **Binary-only FVM 5:** the root package will use `publish_to: none`; there is
   no Dart-dependent wrapper.
2. **Staged bridge:** a final FVM 4 release is published before FVM 5 stable.
3. **CLI-first execution:** application code and tests are migrated first. The
   GitHub-release, installer, package-manager, and per-platform checks are a
   later mandatory gate, not part of the first implementation slice.
4. **Stable updates only:** automatic checks ignore drafts and prereleases. A
   prerelease is installed only when the user explicitly chooses it.
5. **Inform, do not mutate:** update checks print guidance and never modify the
   installed executable.

## Verified current state

| Area | Evidence | Planning consequence |
| --- | --- | --- |
| Root package | `pubspec.yaml` is `4.1.2`, requires Dart `>=3.6.0 <4.0.0`, declares `fvm: main`, and depends on `pub_updater`. | The GitHub client must land while the old Dart floor is still intact so it can be reused by the final FVM 4 release. Keep the executable declaration because `cli_pkg` reads it. |
| Update behavior | `FvmCommandRunner._checkForUpdates()` in `lib/src/runner.dart` uses pub.dev, the `disableUpdateCheck` and `lastUpdateCheck` fields, a one-day interval, debug-only failure reporting, and a check that runs alongside the requested command. | Preserve opt-out, daily cadence, non-fatal failures, concurrency, and command exit codes. Replace only the release source and notification content. |
| Update state | `LocalAppConfig.read(requireValid: true)` protects malformed configuration from overwrite; `test/src/runner_test.dart` locks this down. | Keep the strict read before persisting an attempt timestamp and retain the malformed-config regression test. No config schema change is needed. |
| Release build | `.github/workflows/release.yml` creates the GitHub release, uploads Linux archives, publishes to pub.dev, then runs Windows, macOS/Homebrew, and Docker jobs. `tool/release_tool/tool/grind.dart` configures `cli_pkg`. | FVM 5 must remove the pub step. Before that, asset creation and validation must complete before a release becomes the latest stable release. |
| Dart toolchains | Root CI uses Dart `3.10.0`; release jobs use `3.9.0`; the prepare action defaults to `3.10.0`; the release tool declares `>=3.8.0`. | FVM 5 needs one explicit `3.12.2` CLI/release toolchain. The final FVM 4 bridge retains the older floor and is tested separately. |
| Current public release | GitHub redirects the project to `conceptadev/fvm`. Release `4.1.2` uses the unprefixed tag `4.1.2` and has 12 binary archives: Linux arm/arm64/riscv64/x64 in glibc and musl variants, macOS arm64/x64, and Windows arm64/x64. No `SHA256SUMS` asset is present. | Preserve the public asset names for the first FVM 5 release, add a checksum manifest, and validate all 12 archives before publication. |
| Repository identity | Live code and docs contain `leoafarias/fvm`, `fluttertools/fvm`, and the canonical `conceptadev/fvm`. GitHub currently redirects old repository URLs after the transfer. | Canonicalize live updater, installer, workflow, and package metadata URLs. Do not rely on redirects for release infrastructure. Historical changelog links need not be rewritten. |
| Installers | `docs/public/install.sh` already installs GitHub archives for macOS/Linux. `scripts/install.ps1` uses a different repository slug, saves a ZIP as `fvm.tar.gz`, extracts it as gzip, and requires admin rights. | Keep the shell installer as the Unix baseline; replace or substantially harden the PowerShell path before Windows is declared supported for FVM 5. |
| Release precedent | `.github/workflows/release-fvm-mcp.yml` builds first, gathers artifacts, generates `SHA256SUMS`, and publishes after all builds succeed. | Reuse this release shape for the CLI while retaining `cli_pkg` as the archive builder. |
| Migration coverage | `test/integration/migration_from_v3_test.dart`, `scripts/manual-migration-test.sh`, and `docs/pages/documentation/guides/manual-smoke-test.md` already exercise isolated config, cache, links, and command flows. | Extend these patterns to cover final-FVM-4-to-FVM-5 installation without touching a developer's real home or cache. |

Current external facts were checked against the [Dart SDK documentation](https://dart.dev/tools/sdk),
the [GitHub Releases API contract](https://docs.github.com/en/rest/releases/releases),
and GitHub's [repository-transfer guidance](https://docs.github.com/en/repositories/creating-and-managing-repositories/transferring-a-repository).
Recheck the latest stable Dart patch immediately before the FVM 5 constraint is
committed; a pubspec cannot express “whatever is latest.”

## Recommended architecture

Add a small **FvmReleaseService** under the existing service layer and make
`FvmCommandRunner` depend on it. The service performs one unauthenticated GitHub
API request per eligible check, parses only FVM CLI release tags matching an
optional `v` followed by semantic version text, excludes drafts and
prereleases, and returns the greatest stable `pub_semver.Version`.

Do not use GitHub's `/releases/latest` endpoint. GitHub defines “latest” using
release metadata rather than the greatest CLI semantic version, and this
repository can also contain independently versioned MCP releases. Query the
published release list with `per_page=100`, reject tags such as
`fvm-mcp-v...`, and choose the maximum valid FVM CLI version. A response with
no valid CLI releases is a non-fatal update-check failure.

The runner owns policy:

- when enabled, check at most once in 24 hours;
- make a first-run check eligible, which is required for the bridge to reach
  users whose config has no timestamp;
- persist the attempt timestamp through the caller's `appConfigPath` before the
  network call, preserving the current “do not retry every command” behavior;
- bound the network operation to five seconds;
- run it concurrently with the requested command and never replace that
  command's exit code;
- notify only when `latest > current`, never for a downgrade or equal version;
- retain the existing compact message for same-major updates;
- for a greater major version, link to the FVM 5 migration guide and explain
  that pub.dev no longer carries the new CLI;
- never download or execute release assets.

The shared service and runner changes must compile on Dart 3.6 so they can be
cherry-picked into the final FVM 4 bridge. Dart-3.12-only syntax and dependency
updates begin only after that bridge is prepared.

### Alternatives considered

- **Hard cut directly to FVM 5:** rejected because existing FVM 4 installations
  discover updates through pub.dev and would never learn about a GitHub-only
  FVM 5 release.
- **Thin pub.dev bootstrap package:** rejected because it still requires Dart,
  adds download/execution and supply-chain behavior, and creates two update
  systems for one CLI.
- **Publish FVM 5 to both pub.dev and native channels:** rejected because it
  keeps the Dart compatibility constraint and installation conflicts that the
  binary-only decision is intended to remove.
- **Rewrite all release packaging immediately:** rejected for the first cut.
  Keep the proven `cli_pkg` archive generation, but move release publication
  after artifact validation and checksumming.

## Compatibility invariants

- The final FVM 4 bridge keeps `>=3.6.0 <4.0.0` unless its current dependency
  graph proves that floor is already invalid. It must be tested at the declared
  minimum before publication.
- FVM 5's Dart `3.12.2` floor applies to source development and compilation.
  Released standalone archives include what they need to run and must work on a
  machine with no standalone Dart SDK on `PATH`.
- The global config path and JSON fields remain unchanged. Existing
  `disableUpdateCheck` and `lastUpdateCheck` values continue to work.
- The cache root, Git cache, installed Flutter SDKs, global link, `.fvmrc`,
  project SDK reference, VS Code settings, and Melos settings are neither moved
  nor rewritten by this migration.
- `completion` and `api` retain their current update-check bypass, update
  failures remain debug-only, and all CLI exit-code contracts remain intact.
- The first implementation milestone does not change `GitService`,
  `FlutterService`, `EnsureCacheWorkflow`, or project-reference workflows.
- `fvm_mcp` keeps its own version and source compatibility declaration for the
  CLI-first milestone. It is tested against FVM 5, but raising its declared Dart
  floor requires its own release decision.

## Work breakdown

### Milestone A — shared application code (start here)

- [x] **Task 1: Add stable GitHub release discovery**
  - Dependencies: none
  - Files: add the planned paths
    lib/src/services/fvm_release_service.dart and
    test/src/services/fvm_release_service_test.dart; register the service in
    `lib/src/utils/context.dart`; add canonical repository/API constants to
    `lib/src/utils/constants.dart`.
  - Behavior: send the recommended GitHub API headers and an FVM user agent;
    accept `X.Y.Z` and `vX.Y.Z`; skip drafts, prereleases, malformed tags, and
    non-CLI tags; select the greatest stable semantic version independent of
    response order; expose the release page URL for the notice.
  - Test cases: empty response, out-of-order versions, optional `v`, an MCP tag,
    draft, prerelease, malformed JSON, non-2xx response, timeout, and a valid
    response mixed with invalid entries.
  - Acceptance: the service makes no filesystem changes and returns a typed
    release or a typed failure that the runner can suppress.
  - Verification:

    ```bash
    dart test test/src/services/fvm_release_service_test.dart
    ```

  - Scope: S

- [x] **Task 2: Replace `pub_updater` without changing command contracts**
  - Dependencies: Task 1
  - Files: update `lib/src/runner.dart`, `test/src/runner_test.dart`,
    `pubspec.yaml`, and `pubspec.lock`.
  - Behavior: inject **FvmReleaseService**; remove `pub_updater`; make a null
    timestamp eligible; persist through `context.appConfigPath`; enforce the
    five-second bound; compare with `pub_semver`; keep opt-out, 24-hour
    throttling, concurrency, debug-only failures, and existing bypasses.
  - Notice: same-major updates keep the current version arrow; greater-major
    updates link to the migration guide and state that FVM 5 is installed as a
    standalone CLI. Do not print installation commands that assume one package
    manager.
  - Regression cases: disabled checks, recent timestamp, first run, older
    timestamp, equal/lower/latest versions, same-major update, major migration,
    network failure, timeout, malformed global config, `--version`, API and
    completion commands, and preservation of the requested command's non-zero
    exit code.
  - Acceptance: the following search returns no production or test references;
    update checks issue at most one GitHub lookup per eligible invocation; no
    update path invokes a process.

    ```bash
    rg pub_updater lib test pubspec.yaml
    ```

  - Verification:

    ```bash
    dart test test/src/runner_test.dart test/src/services/fvm_release_service_test.dart
    ```

  - Scope: M

- [x] **Checkpoint A — requested first slice:** run the targeted tests plus full
  analysis and unit tests under the current FVM 4-compatible SDK. Review the
  diff specifically for config writes, network failure handling, output, and
  exit codes. Stop here before changing publication, installers, or platform
  release jobs.

  Completed on 2026-07-20. `dart analyze --fatal-infos` and `dcm analyze lib`
  reported no issues; the focused service/runner suite passed 22 tests; the
  full `dart test` run passed 522 tests; generated-code validation succeeded;
  and the `pub_updater` acceptance search returned no matches. Milestones B-E
  remain intentionally unimplemented.

### Milestone B — GitHub and platform release gate (later, but mandatory)

- [ ] **Task 3: Make the CLI release atomic and verifiable**
  - Dependencies: Checkpoint A
  - Files: `.github/workflows/release.yml`,
    `tool/release_tool/tool/grind.dart`,
    `tool/release_tool/test/grind_test.dart`, and
    `.github/workflows/README.md`.
  - Retain `cli_pkg` archive building, but upload Actions artifacts first. Only
    create or publish the GitHub release after every expected archive exists,
    archive contents pass inspection, and `SHA256SUMS` is generated.
  - Keep public release and asset versions unprefixed (`X.Y.Z`) for installer
    compatibility. If a `vX.Y.Z` trigger tag is retained, create or verify the
    unprefixed tag at the exact same commit before publishing.
  - Validate that the tag, `pubspec.yaml`, generated
    `lib/src/version.dart`, changelog heading, release target SHA, and archive
    filenames all contain the same version.
  - Expected archive matrix for the initial cut:
    - Linux: `arm`, `arm64`, `riscv64`, and `x64`, each with glibc and musl
      archives.
    - macOS: `arm64` and `x64`.
    - Windows: `arm64` and `x64`.
  - Publish Homebrew, Chocolatey, and Docker only after the GitHub release and
    checksum verification succeed.
  - Acceptance: no partially populated release can become the highest stable
    CLI version seen by the updater.
  - Verification: release-tool analysis/tests, a dry-run artifact build on all
    three runner OSes, archive listing checks, SHA-256 verification, and
    `fvm --version` from each runnable native artifact.
  - Scope: M

- [ ] **Task 4: Canonicalize and validate every installation channel**
  - Dependencies: Task 3
  - Files: `docs/public/install.sh`, `scripts/install.ps1`,
    `.github/workflows/test-install.yml`, `scripts/test-install.sh`,
    `scripts/test-install-arch.sh`, `test/install_script_validation_test.dart`,
    `tool/fvm.template.rb`, `fvm.nuspec`, `.docker/Dockerfile`,
    `.docker/alpine/Dockerfile`, and live repository links in maintainer/install
    documentation.
  - Use `conceptadev/fvm` for live release infrastructure. Leave historical
    changelog links alone.
  - Unix installer: preserve user-local installation and cache-preserving
    uninstall behavior; download and verify `SHA256SUMS`; test every advertised
    OS/architecture/libc mapping with stubbed metadata before a live smoke.
  - PowerShell installer: use the canonical repository, normalize optional `v`,
    download a ZIP as a ZIP, create an isolated temporary directory, verify its
    checksum, extract with the correct primitive, install user-locally, update
    or clearly explain `PATH`, verify the binary, and clean up on failure. The
    Chocolatey path remains separate.
  - Homebrew/Chocolatey/Docker: verify metadata URLs, checksums, version output,
    and installation from the candidate GitHub release. Pin Docker's Dart build
    image for reproducible source builds.
  - Acceptance: each advertised channel installs the requested version without
    an existing Dart SDK, and a reinstall does not delete FVM's Flutter cache.
  - Verification: shellcheck, Bash fixture tests, Windows PowerShell tests,
    Homebrew formula test, Chocolatey package test, Docker build/smoke, and the
    `test-install.yml` OS matrix against a candidate release.
  - Scope: M

- **Checkpoint B:** use a prerelease or private candidate release to run the
  entire asset and installer matrix. Do not publish the final FVM 4 bridge or
  change `publish_to` until this checkpoint passes.

### Milestone C — final FVM 4 bridge

- [ ] **Task 5: Publish one last pub.dev migration release**
  - Dependencies: Checkpoint B
  - Branching: prepare a maintenance branch from the current FVM 4 release line
    and cherry-pick the compatibility-safe updater/release commits. Do not
    cherry-pick FVM-5-only Dart-floor or `publish_to` changes.
  - Version: recommend `4.2.0` because the GitHub update source and migration
    notice are user-visible features; confirm the final number during release
    preparation.
  - Keep the FVM 4 Dart constraint and pub.dev deployment. Add release notes and
    a migration guide covering pub deactivation, standalone installation,
    package-manager choices, cache preservation, and rollback to FVM 4.
  - Publish to pub.dev and all native channels. Initially, the GitHub client
    should resolve the new FVM 4 release as current and print no migration
    notice. Once FVM 5 stable exists, the same binary must discover FVM 5 and
    print the major-version guidance without another FVM 4 publication.
  - Acceptance: using the recommended version, `dart pub global activate fvm
    4.2.0` works on the declared minimum Dart SDK; if release preparation picks
    a different final 4.x number, substitute that exact version in the same
    check. Update checks no longer contact pub.dev, and all FVM 4
    config/cache/project smoke tests pass.
  - Verification: minimum-SDK and latest-SDK CI jobs, pub publish dry run,
    post-publish pub activation in an isolated `PUB_CACHE`, Checkpoint B's
    release matrix, and the repository's manual branch smoke test.
  - Scope: M

### Milestone D — FVM 5 source and publication cutover

- [ ] **Task 6: Apply the FVM-5-only Dart and pub changes**
  - Dependencies: Task 5 is published and verified
  - Files: `pubspec.yaml`, `pubspec.lock`, `lib/src/version.dart`,
    `CHANGELOG.md`, `.pubignore`, `tool/release_tool/pubspec.yaml`,
    `tool/release_tool/pubspec.lock`, `.github/actions/prepare/action.yml`,
    `.github/workflows/test.yml`, `.github/workflows/release.yml`, standalone
    deploy workflows, `README.md`, `AGENTS.md`, and maintainer documentation.
  - Set the root SDK constraint to `>=3.12.2 <4.0.0`, after rechecking the
    then-current stable Dart patch. Set the CLI/release CI pins and release-tool
    floor to the same version. Test `fvm_mcp` on that SDK but do not raise its
    declared floor in this CLI-only change.
  - Add `publish_to: none`, remove pub credentials and the pub deployment job,
    remove publication-only `.pubignore`, and add a CI assertion that a tagged
    FVM 5 release cannot invoke `dart pub publish`.
  - Keep the root `executables` map because release packaging uses it. Remove
    the obsolete `bin/compile.dart` helper rather than retain its hard-coded
    `/usr/local/bin` move and pub-global deactivation behavior.
  - Set the first FVM 5 prerelease version and regenerate
    `lib/src/version.dart`. Run build generation after every version or
    mappable-model change and commit only intentional generated output.
  - Acceptance: source validation uses Dart 3.12.2; the compiled CLI runs with
    Dart absent from `PATH`; no FVM 5 workflow or package metadata can publish
    the root package to pub.dev.
  - Verification: root, release-tool, and MCP dependency resolution; analyzers;
    DCM; full unit tests; build verification; native compile; and execution in
    a Dart-free container/shell environment.
  - Scope: M

- [ ] **Task 7: Cut documentation and channel metadata over to binary-first**
  - Dependencies: Task 6 and Checkpoint B
  - Files: `README.md`,
    `docs/pages/documentation/getting-started/installation.mdx`,
    `docs/pages/documentation/getting-started/faq.md`,
    `docs/pages/documentation/guides/workflows.mdx`,
    `docs/pages/documentation/guides/global-configuration.mdx`,
    `.github/workflows/README.md`, Homebrew/Chocolatey metadata, and the new FVM
    4-to-5 migration guide.
  - Make the standalone script/package-manager path primary, remove FVM 5 pub
    activation instructions and pub badges, and clearly separate “Dart needed
    to build from source” from “Dart not needed to run FVM.”
  - Keep the final FVM 4 migration instructions available at a stable URL used
    by the CLI notice.
  - Acceptance: every documented command corresponds to a tested installation
    path and no page implies that FVM 5 is published on pub.dev.
  - Verification: docs build, link check, command copy/paste review, and
    candidate-install smoke tests from the rendered instructions.
  - Scope: S

### Milestone E — rollout

- [ ] **Task 8: Rehearse, publish, observe, and discontinue pub**
  - Dependencies: Tasks 6 and 7
  - Publish an FVM 5 prerelease first. Because prereleases are excluded from the
    bridge updater, this cannot redirect stable FVM 4 users.
  - Run Checkpoint B against the actual prerelease assets and verify config,
    cache, global link, project link, VS Code, Melos, and command proxy behavior
    in an isolated home.
  - Publish FVM 5 stable only after every required asset, checksum, installer,
    package manager, Docker image, and migration instruction is ready.
  - From a clean isolated pub installation of the final FVM 4 release, confirm
    the next eligible update check discovers FVM 5 and prints the migration URL.
    Then install FVM 5 and verify that the same isolated FVM state still works.
  - Observe the stable release before marking the pub.dev package discontinued.
    When discontinuing it, link pub.dev to the migration guide; do not remove
    old versions.
  - Acceptance: the GitHub release is the only FVM 5 source of truth, all
    supported installation paths resolve the same stable version, and legacy
    users receive actionable migration guidance.
  - Scope: M

## Test strategy

### Unit and contract tests

- test/src/services/fvm_release_service_test.dart: HTTP/JSON/tag filtering,
  semantic ordering, headers, error handling, and timeout.
- `test/src/runner_test.dart`: cadence, opt-out, first run, config persistence,
  same-major and major notices, no downgrade notice, non-fatal failures,
  bypasses, and exit-code preservation.
- `tool/release_tool/test/grind_test.dart`: canonical repository, version/tag
  consistency, expected asset manifest, release target SHA, and GitHub failures.
- Installer tests: version normalization, exact asset selection, checksum
  verification, archive safety, cleanup, cache preservation, and PATH guidance.

### Required commands

Run these with the SDK appropriate to the checkpoint; FVM 5 runs use Dart
`3.12.2`.

```bash
dart pub get
dart format --output=none --set-exit-if-changed .
dart analyze --fatal-infos
dcm analyze lib
dart test
dart run build_runner build --delete-conflicting-outputs

(cd tool/release_tool && dart pub get && dart analyze && dart test)
(cd fvm_mcp && dart pub get && dart analyze && dart test)

shellcheck docs/public/install.sh scripts/test-install.sh scripts/test-install-arch.sh
./scripts/test-install.sh
./scripts/test-install-arch.sh
git diff --check origin/release/5.0...
```

After build generation, verify that `git diff` contains only expected mapper and
version output. Before final release, also run the pre-commit checks and the
manual smoke test in
`docs/pages/documentation/guides/manual-smoke-test.md` with isolated `HOME`,
`FVM_CACHE_PATH`, and `FVM_GIT_CACHE_PATH` values.

### Migration smoke

The end-to-end migration smoke must prove all of the following without using a
developer's real state:

1. Activate the final FVM 4 package into an isolated `PUB_CACHE`.
2. Seed global config, a global Flutter version, a project `.fvmrc`, a cached
   release/channel, VS Code settings, and Melos settings under an isolated home.
3. Make the update check eligible and confirm it resolves the FVM 5 stable
   GitHub release without changing CLI state or command exit codes.
4. Deactivate the pub package, install the platform FVM 5 archive, and ensure
   executable resolution now selects the standalone binary.
5. Run `fvm list`, `fvm doctor`, `fvm use`, `fvm global`, `fvm flutter
   --version`, and `fvm dart --version`; confirm all seeded state and project
   references remain valid.
6. Remove only the sandbox state created by the test.

## Risks and mitigations

- **GitHub API rate limits or outages:** an unauthenticated lookup can fail for
  users behind a shared network. Mitigation: one lookup at most daily, a
  five-second total bound, debug-only failure, and no effect on the requested
  command. If prerelease telemetry or issue reports show this is insufficient,
  publish a small signed/static release manifest as a separately reviewed
  follow-up rather than adding fallback parsing to the first bridge.
- **Old pub executable shadows the new binary:** a successful install can still
  resolve the pub-cache shim first. Mitigation: the migration guide explicitly
  deactivates the pub package, installers print the selected path, and the
  migration smoke asserts executable resolution before and after cutover.
- **Trigger and public tags diverge:** current releases use both `vX.Y.Z` and
  `X.Y.Z`. Mitigation: the release workflow resolves both to the same immutable
  SHA before creating assets and fails on any mismatch.
- **A non-CLI release pollutes update discovery:** MCP releases share the
  repository. Mitigation: strict CLI tag parsing plus draft/prerelease and
  semantic-version tests; never trust release ordering or name alone.
- **A new Dart stable patch appears during implementation:** “latest” can drift
  between plan approval and cutover. Mitigation: recheck the official Dart SDK
  page at the FVM-5-only checkpoint and update the constraint, lockfiles, CI,
  and release-tool pins together.
- **Cross-built archives behave differently from native archives:** `cli_pkg`
  can package a runtime and snapshot for non-host targets. Mitigation: retain
  the current artifact names, inspect archive contents, execute every available
  native artifact on its target runner, and do not advertise a target whose
  candidate cannot run.

## Release order and stop conditions

Release order is strict:

1. Merge and verify the compatibility-safe GitHub updater.
2. Pass the GitHub/platform release gate.
3. Publish and verify the final FVM 4 bridge on pub.dev and native channels.
4. Apply FVM-5-only Dart and no-pub changes.
5. Publish and validate an FVM 5 prerelease.
6. Publish FVM 5 stable.
7. Verify the final FVM 4-to-5 notification and state-preserving migration.
8. Update remaining channel metadata and discontinue the pub.dev package.

Stop the rollout if any of these is true:

- the final FVM 4 package cannot run on its declared minimum Dart SDK;
- a GitHub request can select an MCP, draft, prerelease, malformed, or lower
  version as an FVM CLI update;
- the release tag, target SHA, pubspec version, generated version, changelog, or
  archive version disagree;
- any required platform archive or `SHA256SUMS` is absent or invalid;
- a documented installer needs an undeclared runtime, deletes cache state, or
  installs a different version;
- a standalone binary fails with Dart removed from `PATH`;
- the final FVM 4 bridge does not discover FVM 5 stable;
- config/cache/project-reference smoke behavior differs from the FVM 4
  baseline.

## Rollback posture

- Before FVM 5 stable, leave the final FVM 4 release as the latest stable CLI
  release and fix the prerelease; no stable users are redirected.
- If an FVM 5 release is published prematurely, make it non-latest/unpublished
  while preserving its artifacts for investigation, restore the final FVM 4
  release as latest, and pause package-manager promotion.
- Do not publish FVM 5 to pub.dev as a rollback. Fix forward with a corrected
  GitHub release after the full release gate passes.
- No data rollback is expected because this plan does not migrate config or
  cache formats. If the smoke test detects a state mutation, stop and design a
  separate reversible state migration before continuing.

## Review result

This plan deliberately separates the low-risk application-code seam from the
high-risk distribution cutover. Milestone A is the next implementation scope.
Milestones B–E remain required before FVM 5 stable and explicitly cover the
GitHub-release and platform-specific work requested for later review.
