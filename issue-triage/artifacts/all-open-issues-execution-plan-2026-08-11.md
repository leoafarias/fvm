# Plan: Resolve and manage all 57 open FVM issues

> Execute the live queue against FVM 4.1.2 in risk order, while closing solved questions, collecting missing evidence, consolidating overlapping requests, and keeping every engineering change independently testable.

> **Execution update:** the validity cleanup closed #575, #697, #720, #748, #754, #774, #791, #794, and #1055. The live queue now contains 48 issues; see [issue-closure-audit-2026-08-11.md](issue-closure-audit-2026-08-11.md). The matrices below preserve the original audited 57-issue baseline.

## Objective

Success means every issue open on 2026-08-11 has a concrete next action, an owner-ready scope, and a verification or closure condition.

- **Primary outcome:** resolve the sole P1 first, review the active pull requests, clear low-risk queue hygiene, and then implement the remaining P2/P3 work in dependency-aware slices.
- **Out of scope:** implementing all fixes in this triage pass, changing GitHub issue/PR state without maintainer approval, or force-merging `origin/main` over the dirty `issue-triage` worktree.
- **Constraint:** the live queue contains 57 issues: 0 P0, 1 P1, 31 P2, 17 P3, and 8 needs-info. Six pull requests are open.

## Context

- The code audit used a clean detached worktree at `origin/main` commit `2871c7d8ef924210689a10115695d137c9c776cb`, which reports FVM 4.1.2. The active branch is current with `origin/issue-triage`, but its dirty worktree overlaps upstream changes and must be cleaned or committed before merging `main`.
- The 22 newer `main` commits are primarily the 4.1.2 release, Dart MCP documentation, git-cache metadata cleanup, and Windows ARM64 release support. Of the active queue, only #1050 is directly changed by that work; native Windows ARM64 archives now exist, while package-manager delivery remains open.
- Install and cache behavior is centered in [install_command.dart](../../lib/src/commands/install_command.dart), [ensure_cache.workflow.dart](../../lib/src/workflows/ensure_cache.workflow.dart), [flutter_service.dart](../../lib/src/services/flutter_service.dart), and [cache_service.dart](../../lib/src/services/cache_service.dart).
- Project reference behavior is centered in [use_command.dart](../../lib/src/commands/use_command.dart), [update_project_references.workflow.dart](../../lib/src/workflows/update_project_references.workflow.dart), [update_vscode_settings.workflow.dart](../../lib/src/workflows/update_vscode_settings.workflow.dart), and [update_melos_settings.workflow.dart](../../lib/src/workflows/update_melos_settings.workflow.dart).
- CLI process behavior runs through [runner.dart](../../lib/src/runner.dart) and [process_service.dart](../../lib/src/services/process_service.dart). The current process service still combines shell execution with inherited stdio, which is the surface changed by PR #1054 for #1046.
- Existing regression homes include [install_command_test.dart](../../test/commands/install_command_test.dart), [use_command_test.dart](../../test/commands/use_command_test.dart), [flutter_service_test.dart](../../test/services/flutter_service_test.dart), [cache_service_test.dart](../../test/services/cache_service_test.dart), [process_service_test.dart](../../test/src/services/process_service_test.dart), and the project-reference workflow tests under [test/src/workflows](../../test/src/workflows).
- All 57 active issue reports now contain the required problem summary, validation steps, evidence, implementation/troubleshooting plan, and recommendation sections.

## Approach

Use a staged queue rather than a single release-sized project. First stabilize the one P1 and review all code-bearing PRs. In parallel, clear issues that only need an answer, closure, or reporter data. Then create one design decision for each overlapping issue family and implement small vertical slices behind compatibility-preserving defaults. Packaging requests remain independent deliverables rather than additions to the core CLI.

- **Alternative considered: work strictly by issue number** — rejected because duplicate requests would produce conflicting implementations and repeated reviews.
- **Alternative considered: close all stale issues before engineering work** — rejected because age alone does not invalidate reproducible compatibility problems.
- **Alternative considered: combine all project-reference changes** — rejected because VS Code JSONC, Android Studio paths, Melos, global links, and JDK configuration have different compatibility and test surfaces.

## Compatibility and migration

- **Breaking change:** no breaking change is planned by default. New resolution rules, output modes, cache locations, and provider types must be additive or explicitly opted in.
- **Migration path:** preserve `.fvmrc`, existing cache layout, command output defaults, and project symlink behavior until a separately approved major-version proposal says otherwise.
- **Shims:** if persistent project links or provider abstractions replace current behavior, retain the existing path/config interpretation for at least one minor release and emit actionable deprecation guidance.
- **Data migration:** any shared-cache or namespaced-provider change must be reversible and must not move/delete SDKs without a dry-run or explicit confirmation.

## Work breakdown

### Wave 0 — Establish the execution baseline

- [ ] **Task 0.1: integrate current `main` safely**
  - Dependencies: commit/stash the existing triage changes; do not overwrite unrelated work.
  - Acceptance: the implementation branch includes FVM 4.1.2 and the Windows ARM64, git-cache, and release-model changes already on `main`.
  - Verification: `git status --short`, `git log --left-right --count HEAD...origin/main`, then the standard test gates below.
  - Scope: S.
- [ ] **Task 0.2: assign an explicit disposition to every live issue**
  - Dependencies: none.
  - Acceptance: the five matrices below retain all 57 issue numbers exactly once; GitHub labels/milestones reflect P1/P2/P3/needs-info after maintainer review.
  - Verification: compare the matrix issue set with `pending_issues/open_issues.json` and confirm no missing or duplicate number.
  - Scope: XS.

### Wave 1 — P1 and active pull requests

| Order | Issue / PR | Action | Acceptance and verification |
|---|---|---|---|
| 1 | #688 / PR #1013 | Rebase and narrow the archive/mirror installation change; fix the failing Linux test/formatting gate before functional review. | Archive download honors custom storage metadata, stages atomically, survives retries, and does not regress Git installs. Run full tests plus the manual install/use smoke guide. |
| 2 | #1046 / PR #1054 | Review the SIGINT/process-lifecycle patch before starting another process refactor. | Fish regains cooked terminal mode after Ctrl+C; exit and signal behavior remain correct on macOS/Linux; Windows behavior is reviewed; PTY regression and full CLI CI pass. |
| 3 | #1021 / PR #1022 | Rebase the `pub_updater` 0.5 dependency update. | Dependency resolution succeeds on supported Dart versions and the full unit suite passes. |
| 4 | #762 / PR #1053 | Validate multi-architecture Docker publishing. | Published manifest contains amd64 and arm64, and both images start and report the expected FVM version. |
| 5 | #689 / PR #828 | Decide whether the releases-table Dart SDK column solves part of the readability request; rebase, test terminal widths, and merge or close. | Default and machine-readable output contracts are documented; narrow terminals do not become less usable. |
| 6 | Documentation / PR #1051 | Verify the canonical `.gitignore` guidance and merge or close the documentation-only PR. | Documentation names the correct generated FVM path and no obsolete ignore rule is introduced. |

- **Checkpoint:** do not begin overlapping core refactors until PR #1013 and PR #1054 have a clear merge/close decision; their changes touch the install and process foundations used by later work.

### Wave 2 — Queue hygiene and reporter follow-up

#### Answer or close without core code changes

| Issue | Disposition | Concrete next action | Closure condition |
|---|---|---|---|
| #575 | Solved | Explain the existing flavor argument forwarding and add a focused example if documentation is unclear. | Reporter can invoke the flavor; close as already supported. |
| #697 | Documented workflow | Point Android Studio at the FVM global SDK link and distinguish global from per-project setup. | Answer posted; close unless a current reproducible defect is supplied. |
| #754 | Environment prerequisite | Explain that FVM cannot bypass Flutter/Xcode platform prerequisites. | Provide upstream prerequisite guidance and close. |
| #791 | Already supported | Document `fork/version@channel` namespacing. | Answer posted and current parsing test cited; close. |
| #794 | Upstream support delivered | Note current Linux ARM/Raspberry Pi installation support and request a fresh failure only if reproducible. | Close the resolved historical request. |
| #1055 | Question/docs | Answer with `fvm --version` and installation-method-specific update commands; optionally add a consolidated update-doc section. | User has a verified check/update path; close the question. |

#### Request evidence, then close stale reports if no response

| Issue | Missing evidence | Requested reproduction package | Decision rule |
|---|---|---|---|
| #731 | Git-cache error shown only in a screenshot | FVM version, OS, `fvm doctor`, cache/git-cache paths, command, logs, and directory state. | Reclassify if current reproduction exists; otherwise close stale/incomplete. |
| #748 | Windows global setup details | FVM/install method, shell, PATH, `fvm global` output, `where flutter`, and config. | Route to docs or a current Windows bug. |
| #759 | Global/VS Code mismatch | `.fvmrc`, FVM config, workspace settings, expected behavior, and verbose logs. | Merge with #697/#743 if configuration-only; otherwise isolate defect. |
| #781 | Chocolatey missing executable | Current package/version, install log, PATH, `where fvm`, and clean reinstall result. | Escalate to packaging owner only if current package still fails. |
| #797 | `bash\r` failure | Source of the script, raw line endings, OS/shell, installation path, and exact command. | Fix owned script if repository-generated; otherwise document CRLF repair. |
| #809 | Sidekick update failure | Reproduce with the FVM CLI alone, plus Sidekick version and logs. | Move upstream if Sidekick-only; open CLI work only for standalone FVM failure. |
| #906 | Android Studio terminal latency | Startup timing, shell profile, direct-terminal comparison, FVM/IDE/plugin versions, and traces. | Keep only if FVM startup is isolated as the cause. |
| #1017 | `fvm use`/PATH mismatch | OS/shell, install method, PATH, `which/where flutter`, `.fvmrc`, IDE settings, and verbose output. | Consolidate with the relevant IDE/PATH issue or close as configuration. |

### Wave 3 — Core product workstreams

#### A. Version resolution and upgrade semantics

| Issue | Planned slice | Dependency / acceptance |
|---|---|---|
| #577 | Add an opt-in or well-defined fallback from `environment.flutter` in `pubspec.yaml` when no explicit version or `.fvmrc` exists. | Define precedence first; parser and install tests cover exact, range, absent, and invalid constraints. |
| #648 | Design one Flutter/Dart compatibility resolver and expose useful Dart-version metadata. | Must share the resolver with #577/#751/#1016 instead of adding command-specific parsing. |
| #720 | Keep existing no-argument `.fvmrc` behavior; treat only pubspec fallback as remaining scope. | Close as duplicate of #577 after the shared behavior ships. |
| #751 | Add range resolution only after channel/release ordering and prerelease policy are explicit. | Never silently change a pinned version; tests cover satisfiable, unsatisfiable, prerelease, fork, and offline cases. |
| #1016 | Support `major.minor` latest-patch resolution through the same resolver. | Exact versions remain exact; selected patch is shown before install and is deterministic for cached/offline data. |
| #583 | Add an upgrade-current workflow after version resolution is stable. | Preserve rollback information and require confirmation for project mutation; install and use smoke test passes. |

#### B. Project references, IDEs, and local configuration

| Issue | Planned slice | Dependency / acceptance |
|---|---|---|
| #635 | Replace destructive VS Code JSON rewriting with JSONC-aware targeted edits. | Comments, trailing commas, key order, and unrelated settings survive `fvm use`; add fixture regressions. |
| #681 | Design a persistent project reference that remains valid when cache versions switch. | Coordinate with #764; existing `.fvm/flutter_sdk` consumers remain compatible. |
| #696 | Define project-local `cachePath` resolution relative to `.fvmrc` and validate ownership/permissions. | No implicit SDK moves; relative and absolute path tests pass on Windows and POSIX. |
| #702 | Resolve each VS Code workspace folder independently in multi-root workspaces. | No cross-project mutation; multi-root JSONC fixtures pass. |
| #724 | Document and test physical versus symlink SDK paths for IntelliJ-family IDEs. | A supported configuration actually changes SDK per project; otherwise state the IDE limitation clearly. |
| #743 | Provide a stable VS Code SDK discovery path or command contract. | Coordinate with #681/#821; extension restarts and version switches resolve the current SDK. |
| #764 | Add an opt-in branch-switch workflow around the persistent reference from #681. | Never run hidden installs on checkout by default; document hook/setup and failure behavior. |
| #767 | Reproduce against current Android Studio/Flutter plugin and implement only the verified compatibility path. | Test Windows/POSIX link forms and avoid global IDE mutation. |
| #821 | Evaluate/support Dart Code's `getFlutterSdkCommand` contract. | Prefer this for dynamic discovery if it satisfies #743; document fallback for unsupported IDEs. |
| #1008 | Resolve Melos `sdkPath` from the same project-version source, including pubspec fallback if #577 lands. | Preserve explicit Melos config; workflow tests cover monorepos and nested packages. |
| #1026 | Add per-project JDK configuration only where Flutter/IDE tooling has a stable consumable contract. | No global Java mutation; document precedence and platform limits. |
| #600 | Rewrite Android Studio setup documentation after #724/#767 decisions. | Docs contain verified current paths for global and per-project use. |

#### C. Install, cache, and platform reliability

| Issue | Planned slice | Dependency / acceptance |
|---|---|---|
| #968 | Make SDK setup failures fatal and preserve the underlying command/error context. | Highest unassigned P2; add failure-injection tests and confirm no success config/symlink is written after setup failure. |
| #894 | Design a shared read-mostly SDK cache with explicit permissions, locking, and per-user config. | Concurrent install/use tests prove no corruption; migration is opt-in and reversible. |
| #1024 | Remove avoidable Windows admin requirements through user-owned links/junctions or copy fallback. | Test standard-user install/use; surface actionable errors when OS policy blocks links. |

- **Checkpoint:** after each vertical slice, run focused tests plus analysis. After any change to `FlutterService`, `EnsureCacheWorkflow`, install/use behavior, or project SDK references, run the isolated manual smoke test in [manual-smoke-test.md](../../docs/pages/documentation/guides/manual-smoke-test.md).

### Wave 4 — Distribution and provider extensions

#### Packaging and environments

| Issue | Disposition / plan | Acceptance |
|---|---|---|
| #578 | Community-owned MacPorts port; first define release checksum/update automation and ownership. | Clean install/update/uninstall on supported macOS; core release is not blocked by port lag. |
| #607 | Split Snap and Flatpak proposals; require an owner and sandbox/cache design for each. | Package can install SDKs in an approved writable location and receives version updates. |
| #738 | Publish a supported devcontainer/Codespaces artifact or close in favor of maintained docs/template. | Fresh Codespace boots with pinned FVM and documented cache persistence. |
| #811 | Add a Nix package/flake with reproducible source hash and update process. | `nix build` and a clean-shell smoke test pass on supported architectures. |
| #826 | Treat Winget as the canonical Windows package-manager work item. | x64 and ARM64 manifests install, upgrade, and uninstall without stale PATH entries. |
| #1050 | Fold native ARM64 package-manager delivery into #826; track Chocolatey separately if its feed supports the artifact. | Close when package-manager installs select native ARM64; do not duplicate already-shipped GitHub assets. |

#### Forks and alternate SDK families

| Issue | Planned slice | Acceptance |
|---|---|---|
| #584 | Document current custom Flutter URL configuration and validate it before install. | Invalid/unreachable URLs fail clearly; supported mirror/fork use is demonstrated. |
| #1009 | Define provider metadata for custom forks beyond URL and namespace. | Fork versions remain isolated; release discovery/auth/cache identity are explicit. |
| #1042 | Introduce a provider interface only after Tizen/tvOS lifecycle differences are documented. | One alternate provider proves install/list/use without Flutter-specific assumptions leaking into commands. |
| #757 | Implement Shorebird through the provider design if its lifecycle can satisfy the contract; otherwise publish a scoped integration guide. | No claim of support until install/use/update and cache ownership are exercised end to end. |

### Wave 5 — CLI, shell, and documentation polish

| Issue | Planned action | Acceptance |
|---|---|---|
| #674 | Make global flags consistently available at the intended command scopes. | Parser tests cover flags before/after subcommands without ambiguous collisions. |
| #761 | Add typo suggestions for commands/options with bounded edit distance. | Unknown input exits nonzero and suggestions never execute automatically. |
| #774 | Add global-package PATH troubleshooting to the relevant docs. | Examples cover Dart pub global bin on supported shells/platforms. |
| #782 | Remove non-portable shell substitution from owned wrappers/docs and test supported shells. | Bash/Zsh/Fish guidance executes without `Bad substitution`. |
| #784 | Specify a shell-environment command that prints, rather than silently mutates, safe export instructions. | Output is shell-specific, quote-safe, and documented as session-scoped. |
| #787 | Prefer documented aliases/wrappers over installing shadow `flutter` executables by default. | Opt-in wrapper avoids recursion and preserves arguments, exit codes, and completion. |
| #1048 | Downgrade the explicit `updateVscodeSettings: false` warning to debug/quiet behavior. | Intentional disablement emits no warning; unexpected update failures still warn. |

## Test strategy

- **Unit:** add or update tests beside each owned surface. Priority homes are [install_command_test.dart](../../test/commands/install_command_test.dart), [use_command_test.dart](../../test/commands/use_command_test.dart), [config_command_test.dart](../../test/commands/config_command_test.dart), [process_service_test.dart](../../test/src/services/process_service_test.dart), [cache_service_version_match_test.dart](../../test/src/services/cache_service_version_match_test.dart), and the three project-reference workflow test files.
- **Integration:** run install/use/cache workflows against isolated directories. Packaging changes require clean-environment install/update/uninstall tests on every claimed architecture.
- **Manual/e2e:** use fish PTY verification for #1046; real mirror validation for #688; standard-user Windows verification for #1024; IDE restarts/version switches for #724/#743/#767/#821; and multi-user concurrency for #894.
- **Required repository gates:**

  ```bash
  dart run build_runner build --delete-conflicting-outputs  # after @MappableClass changes
  dart analyze --fatal-infos
  dcm analyze lib
  dart test
  ```

- **Integration setup when needed:** run `dart run grinder test-setup` before `dart run grinder integration-test`.
- **Merge rule:** a focused test is evidence, not a substitute for the repository gates. Changes to Git/Flutter/cache/install/use/prompt/project-reference behavior also require the manual branch smoke test.

## Risks and open questions

- **Risk: stale PRs encode obsolete assumptions** — mitigation: rebase first, compare against current services/models, and demand current CI before review approval.
- **Risk: overlapping issues produce incompatible configuration precedence** — mitigation: approve a single precedence contract before #577, #696, #751, #1008, or #1016 implementation.
- **Risk: filesystem and symlink behavior varies by platform/IDE** — mitigation: use platform matrices and never infer compatibility from macOS-only tests.
- **Risk: packaging becomes unowned release debt** — mitigation: require a named maintainer and automated update path before advertising a distribution channel as supported.
- **Risk: the dirty triage branch obscures upstream changes** — mitigation: preserve existing work, integrate `main` on a clean implementation branch, and do not use destructive resets.
- **Open maintainer decision:** should version ranges/pubspec constraints be opt-in initially, or become fallback behavior when both the CLI argument and `.fvmrc` are absent?
- **Open maintainer decision:** should dynamic IDE discovery (#821) supersede persistent symlinks (#681/#743), or must both be supported?
- **Open maintainer decision:** which external package channels have committed owners? Unowned channels should remain community recipes rather than release promises.

## Rollout

- Land queue-hygiene replies continuously; they do not need a release train.
- Ship #688 and #1046 independently after their full gates pass; neither should wait for broader enhancements.
- Release version-resolution changes additively with explicit diagnostics showing the selected version and source of the decision.
- Roll out cache/project-reference migrations as opt-in first, preserving the old layout/link and a documented rollback command.
- Publish packaging channels only after install/update/uninstall automation exists; mark community-maintained channels clearly.
- Add changelog and migration notes for any new config key, output contract, provider type, or link/cache behavior.
