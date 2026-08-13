# FVM 5.0.0-alpha.0 readiness plan

> Close out the `release/5.0` hardening branch and ship it under a correct
> pre-release version. Companion to `internal/fvm-5-binary-migration-plan.md`.

- Status: executed on `release/5.0` (D1/D3 still deferred follow-ups; D2 kept as recommended)
- Base: `origin/main` at `0d5cae20`; branch `release/5.0` at `ebb2e3a0`
- Reviewed: 2026-08-12
- Revised: 2026-08-12 after a three-agent adversarial verification pass —
  every factual claim re-checked against the repo; two corrections applied
  (the `test-workflows.sh` story, the excluded-test-file count) and the
  release-pipeline consequences added (D1 cherry-pick conflicts, item 19,
  `.pubignore`)
- Gates at review time: `dart analyze --fatal-infos` clean, `dcm analyze lib
  fvm_mcp/lib` clean, fast suite green, 30 conventional commits

## Why this plan exists

The branch is in good shape as code. It is not shippable as *labelled* because
`v4.1.2` is already tagged and released, and the branch adds 18 new CHANGELOG
bullets plus a feature to that released section while leaving `pubspec.yaml` at
`4.1.2`.

Verified:

| Fact | Evidence |
| --- | --- |
| `4.1.2` is released | `git tag -l v4.1.2` returns `v4.1.2` and `4.1.2` |
| Released `4.1.2` had 1 bullet | `git show v4.1.2:CHANGELOG.md` |
| Branch has 19 bullets under `## 4.1.2` (the 1 released + 18 new) | `CHANGELOG.md` |
| Branch version is unchanged | `pubspec.yaml:4` and `lib/src/version.dart:2` are both `4.1.2` |

So the version bump is mandatory, not stylistic.

## Version decision

Use **`5.0.0-alpha.0`**.

Ordering verified empirically with the project's own `pub_semver`:

```
4.1.2  <  5.0.0-alpha.0  <  5.0.0-beta.0  <  5.0.0-dev.0  <  5.0.0-rc.0  <  5.0.0
```

Two consequences worth recording:

1. **Do not use `dev` as the first pre-release.** Pre-release identifiers compare
   as ASCII, so `dev` sorts *after* `beta`, not before it. The only progression
   that sorts earliest-first is `alpha` -> `beta` -> `rc`.
2. `5.0.0-alpha.0 > 4.1.2` is `true`, so the update check correctly stays silent
   for alpha users while `4.x` is the latest stable. No downgrade nag. When
   `5.0.0` ships, alpha users get notified normally. The reverse direction is
   also safe: a published `5.0.0-alpha.0` GitHub release is never offered to
   `4.x` users as an update — `_parseRelease` excludes prereleases twice, via
   GitHub's `draft`/`prerelease` flags (`fvm_release_service.dart:86-87`) and
   `pub_semver`'s `isPreRelease` (`:106`).

`alpha` also matches the sibling package convention (`fvm_mcp` is
`0.0.1-alpha.1`).

## Decisions needed

### D1 — Does the FVM 4 pub.dev bridge release still happen?

`internal/fvm-5-binary-migration-plan.md` objective 3 commits to a final FVM 4
release that "discovers updates from GitHub Releases, and directs users to the
standalone installation path."

This matters because existing pub.dev users are running `fvm` binaries built
with `pub_updater`. If no 4.x release ever ships containing the GitHub
update-discovery code, those users never learn 5.x exists — the exact stranding
the plan's objective forbids.

- **Recommendation: keep the bridge.** Bump this branch to `5.0.0-alpha.0`, and
  cut the bridge separately from `main` by cherry-picking `a39ccf4c`
  (`feat(updates): discover FVM releases from GitHub`). This is already the
  designed path: the plan deliberately kept the GitHub client on the Dart 3.6
  floor "so it can be reused by the final FVM 4 release."
- The bridge should be **`4.2.0`**, not `4.1.3` — it carries a `feat`.
- **The cherry-pick is not clean.** A dry-run (`git cherry-pick --no-commit
  a39ccf4c` in a temp worktree on `origin/main`) hits 5 conflicts:
  `.github/workflows/test.yml`, `lib/src/commands/doctor_command.dart`,
  `lib/src/runner.dart`, `test/commands/doctor_command_test.dart`, and a
  modify/delete on `test/src/runner_test.dart` (deleted on `main`, modified by
  the commit). Budget real conflict resolution — including deciding where the
  runner update-check tests land on `main` — not a mechanical pick.

### D2 — Dart SDK floor and `publish_to`

The migration plan calls for FVM 5 to use `publish_to: none` and a
`>=3.12.2 <4.0.0` floor.

- **Recommendation: do neither in this branch.** Keep `>=3.6.0 <4.0.0` and keep
  the package publishable for now, keeping the D1 cherry-pick surface as small
  as possible. Both changes belong in the first alpha that actually ships
  standalone binaries, once the bridge is out. Accept the consequence
  explicitly: while the package stays publishable, pushing any `v*` tag
  auto-publishes it to pub.dev and every other channel (see item 19) — which
  also makes item 5 (`.pubignore`) part of the blocking gate.

### D3 — Global config toggles (`updateMelosSettings` and siblings)

`app_config_service.dart:67-69,86-88` merges `updateVscodeSettings`,
`updateGitIgnore`, and `updateMelosSettings` into `AppConfig`. Nothing reads
them: the three workflows read `project.config?.X` only
(`update_melos_settings.workflow.dart:154`, `setup_gitignore.workflow.dart:46`,
`update_vscode_settings.workflow.dart:233`). Global defaults for these three
toggles are therefore inert.

- Options: (a) wire the workflows to fall back to the app config, (b) drop the
  three fields from the merge and document them as project-only.
- **Recommendation: (a), but not in this branch.** It is a real feature gap with
  user-visible consequences, pre-existing, and unrelated to this cleanup. File
  it as a follow-up issue.

### Follow-up (D3)

Deferred from `5.0.0-alpha.0`: wire
`updateVscodeSettings` / `updateGitIgnore` / `updateMelosSettings` so the
three workflows fall back to `AppConfig` when the project config omits them.
Do not treat this as done until that lands.

## Work items

### Gate 1 — Version identity (blocking)

1. Set `pubspec.yaml:4` to `version: 5.0.0-alpha.0`.
2. Regenerate `lib/src/version.dart`:
   `dart run build_runner build --delete-conflicting-outputs`.
   Confirm `packageVersion == '5.0.0-alpha.0'`.
3. In `CHANGELOG.md`, restore `## 4.1.2` to exactly its released content (the
   single `.DS_Store` bullet) and move the 18 new bullets under a new
   `## 5.0.0-alpha.0` heading above it.
4. Grep for hardcoded `4.1.2` outside generated files and fix any that are not
   historical changelog entries. (Verified: the only hits today are fixture
   decoys — `fvm_mcp/test/server_test.dart:34`, `fvm_mcp/test/bin/fake_fvm.dart:8`,
   and an unrelated `sse 4.1.2` line in `test/utils/helpers_test.dart:244` —
   none need changing, but re-check after items 1–3.)
5. Add `internal/` to `.pubignore` (the file exists; the entry does not).
   Verified via `dart pub publish --dry-run`: the tarball currently includes
   `internal/` — the 515-line binary-migration plan, this document, and
   `migration-manual-test-plan.md` would all ship to pub.dev. Blocking while D2
   keeps the package publishable, because item 19's pipeline publishes
   unconditionally on tag.

### Gate 2 — Documentation debt (blocking)

6. Document the update-discovery change under `## 5.0.0-alpha.0`. It is the
   single most user-visible change in the branch and currently has no entry
   while cosmetic string fixes do. Cover: update checks now read GitHub
   Releases instead of pub.dev; `pub_updater` dependency removed; a major-version
   notice points at `kFvmMigrationGuideUrl`. Precedent for documenting this class
   of change: the `4.1.0` entry "feat: opt out of update checks".
7. Document the `stable@beta` rejection as a **breaking change**.
   `flutter_version_model.dart:103-108` now throws `FormatException` on
   `<channel>@<channel>`; this previously parsed silently — precisely, `main`
   parsed `stable@beta` *as* `stable`, discarding `@beta` with no trace — so an
   existing `.fvmrc` carrying such a value will now hard-fail. Confirmed
   intended behavior — this item is documentation only, no code change. A
   dedicated test exists (`test/version_format_test.dart:174-191`).

Deliberately out of scope for the root CHANGELOG, so their absence is a
decision rather than an oversight: the `fvm_mcp` changes (the `FutureOr`
compile fix, keeping unexpected tool stack traces server-side, the new
205-line end-to-end `server_test.dart`) are already recorded in
`fvm_mcp/CHANGELOG.md` and ship through the separate `release-fvm-mcp.yml`
pipeline; the `tool/release_tool` pagination fix (`grind.dart` now pages past
GitHub's 100-per-page release limit — FVM already has more than 100 releases)
is maintainer-only tooling.

### Gate 3 — Code fix

8. `lib/src/utils/which.dart:6,61` — remove the hardcoded `/bin/test`
   dependency. On systems without it (NixOS, which FVM explicitly supports per
   the `4.0.5` entry; also distroless/minimal containers) `Process.runSync`
   throws `ProcessException`, which is caught and returns `false`, so `which()`
   returns `null` for every command.

   All call sites are advisory — `doctor_command.dart:263-264` (display),
   `global_command.dart:85` (PATH-shadow warning),
   `use_version.workflow.dart:68` (debug short-circuit) — so the symptom is
   silently degraded output, not a crash. Fix by falling back to mode bits when
   the subprocess is unavailable, preserving the current per-user accuracy where
   `/bin/test` does exist:

   ```dart
   } on ProcessException {
     // /bin/test is absent on some distros (NixOS, distroless images).
     // Fall back to mode bits; less precise than `test -x` for the current
     // user, but better than reporting every PATH entry as non-executable.
     return file.statSync().mode & 0x49 != 0;
   }
   ```

   Implementation constraints, verified: `stat` from the `try` block is **not
   in scope** inside a `catch` clause — an earlier draft of this snippet
   returned `stat.mode` and did not compile — so either re-stat via the `file`
   parameter as above or hoist the variable before the `try`. This branch is
   POSIX-only (`_isExecutable` returns `true` for Windows at `which.dart:59`
   before the subprocess call). The fallback is deliberately weaker than
   `test -x`: any execute bit counts, even when the current user cannot
   actually run the file.

   Add a regression test that exercises the fallback path directly.

### Gate 4 — Simplification of the new release service

`lib/src/services/fvm_release_service.dart` is the only file the simplification
pass flagged; the rest of the branch (commands, workflows, cache/flutter/process
services, `config_model`, `which`) was judged appropriately sized, several files
net-negative in line count. Roughly 40 lines total.

9. Reuse `lib/src/utils/http.dart::httpRequest` instead of the private
   `_httpRequest` (`:114-132`). `httpRequest` already performs the identical
   GET/decode/close cycle and is already used by `FlutterReleaseClient`. Change
   `FvmReleaseRequest` to return `Future<String>`, translate `HttpException`
   into `FvmReleaseException`, and delete the `FvmReleaseHttpResponse` wrapper
   (`:25-33`), whose only addition over a bare body string is the status code.
   (~28 lines)

   Three behavior deltas to handle in the swap, none blocking: `httpRequest`
   takes a `String` (call `_releasesUri.toString()`); it closes the client
   gracefully rather than `close(force: true)`, so a request that loses the
   `.timeout(_timeout)` race holds its socket slightly longer; and it accepts
   any status `< 400` where the current code requires exactly `200`. Also
   budget the test churn: `fvm_release_service_test.dart` constructs
   `FvmReleaseHttpResponse` directly in 6 tests — the ~28-line estimate covers
   production code only.
10. Delete the unreachable `on FvmReleaseException { rethrow; }` at `:145-147`.
    Nothing inside that `try` throws it — `_decodeReleaseList`, the only source,
    is called later at `:160`, outside the block. Verified across production and
    every test fake. (3 lines)
11. Make `FvmReleaseException` extend `AppException`
    (`lib/src/utils/exceptions.dart:8-17`) rather than reimplementing its exact
    `message` + `toString()` shape. Matches the convention used by
    `ForceExit` and `GitCacheDependentSdkRemovalException`. Verified
    behavior-neutral: the only thrower is inside `getLatestStableRelease()`,
    whose sole caller wraps it in an untyped `catch (_)` (`runner.dart:95`), so
    the supertype change routes nothing anywhere new. (~5 lines)
12. Resolve `FvmRelease.url` (`:39`). It has zero production consumers, yet
    `:96-101` gates release *acceptance* on validating its host and path. If
    GitHub's `html_url` shape ever shifts, every release is silently rejected —
    for a field nothing reads. Severity, precisely: the resulting
    `FvmReleaseException` lands in `_checkForUpdates`' blanket `catch (_)`
    (`runner.dart:95`) and degrades to a debug log, so update notifications are
    silently disabled; nothing crashes. Preferred resolution: surface the URL
    in `_showUpdateNotice` (one line, and the validation starts earning its
    keep). Dropping both the field and the validation is the fallback.
13. `lib/src/commands/use_command.dart:92-93` — `{'stable','beta','dev'}` is a
    third independent encoding of channel membership alongside `kFlutterChannels`
    (`constants.dart:96`) and the `FlutterChannel` enum
    (`flutter_version_model.dart:16-21`). **Caveat before touching it:** the
    set excludes `master`/`main` *deliberately* — that is the `b85c2b19` fix
    ("fix: reject unsupported channel pinning", this branch's own
    `fvm use main --pin` CHANGELOG bullet), because rolling channels have no
    discrete release to pin. Deriving it naively from `FlutterChannel.values`
    or `kFlutterChannels` (both include `main` and `master`) would reintroduce
    that bug. Either derive it as channels-minus-rolling, or keep the literal
    and add a comment citing `b85c2b19` so a future refactor doesn't "fix" it.
14. Add a comment to `constants.dart:36` explaining that
    `kFvmRepository = 'conceptadev/fvm'` is deliberate. Verified live:
    `api.github.com/repos/conceptadev/fvm` returns `200` and `leoafarias/fvm`
    `301`-redirects to it, so the canonical slug is correct — but it contradicts
    both the git remote and `tool/release_tool/tool/grind.dart` (`_owner =
    'leoafarias'`). Without a note, a maintainer "fixing" the mismatch would
    break the `html_url` validation in item 12.

### Gate 5 — Test coverage gap (decide, may defer)

15. Real (non-fake) fork clone coverage was removed with
    `_testForkFunctionality` from `test/version_format_workflow_test.dart`, and
    fork recipes were already cut from the real integration suite per
    `.context/docs/integration-tests.md:54`. Nothing now proves a real fork
    clone works against `FakeGitService`'s live counterpart. Either restore one
    real fork recipe to the integration suite or record the gap explicitly in
    that doc.

### Gate 6 — Verification

16. Re-run the full gate set:
    ```bash
    dart analyze --fatal-infos
    dcm analyze lib fvm_mcp/lib
    dart test -x "sdk || network || git || integration || migration"
    ```
17. Run the manual branch smoke test in
    `docs/pages/documentation/guides/manual-smoke-test.md`. Required here: the
    branch touches `FlutterService`, `EnsureCacheWorkflow`-adjacent setup,
    install/use behavior, prompt handling, and project SDK references.
18. Sanity-check the update path against a real GitHub response before tagging,
    since the update-check path is effectively new in production (see note
    below). Concretely: with update checks enabled and a fresh config (null
    `lastUpdateCheck`), any real CLI invocation triggers the check
    (`runner.dart:292`). Known limitation: `_showUpdateNotice`'s major-version
    branch cannot be exercised against live data until a `5.x` GitHub release
    actually exists — pre-tag, the live check proves fetch/parse/store only;
    the notice itself is provable only by its unit tests until after the first
    alpha is published.
19. Know what pushing the tag does. `release.yml` fires on any `v*` tag push
    with **no tag-vs-pubspec validation** (unlike `release-fvm-mcp.yml`, which
    cross-checks tag, pubspec, and changelog), and its deploy chain publishes
    unconditionally: pub.dev (`dart pub publish --force` via cli_pkg's
    `pkg-pub-deploy`), GitHub binaries, Homebrew (versioned formula),
    Chocolatey, and Docker. Two consequences: Gate 1 must be fully done
    *before* the tag is pushed — CI provides no safety net if pubspec and tag
    disagree — and tagging publishes `5.0.0-alpha.0` to pub.dev before the D1
    bridge exists. That ordering is precedented (`v3.0.0-beta.*` and
    `v4.0.0-beta.*` shipped through this same pipeline) but should be a
    conscious decision taken together with D1, not a surprise. Also note that
    "green CI" on this branch is a stronger claim than on `main`: `test.yml`
    now runs `dart analyze --fatal-infos` (previously the invertase action with
    `fatal-infos: false`) and gates `test-os`/`integration-test`/
    `migration-test` on `test`.

## Note: what this branch silently repairs

Worth keeping in the record, because none of it is in the CHANGELOG and it
changes how much of this code is actually new-in-production rather than merely
changed.

- **The update check never ran for anyone.** On `main`, the only write of
  `lastUpdateCheck` sat behind a guard that defaulted a null value to "now" and
  then short-circuited — it could never pass while the value was null, so the
  write was unreachable and the field stayed null forever. The branch inverts
  the guard (`runner.dart:81-88`). The entire update-check path is therefore
  effectively new code, not a refactor — hence verification item 18.
- **`fvm_mcp` did not compile on `main`.** `_error()` returns a synchronous
  `CallToolResult` (`server.dart:471`) against a declared
  `Future<CallToolResult> Function(...)`. The `FutureOr` widening at `:438`
  fixes it. (Reproduced: `dart analyze` on `origin/main` reports 5
  `return_of_invalid_type_from_closure` errors; the branch analyzes clean.)
- **Four test files were excluded from CI.** `dart test` with a `paths:` list
  restricts discovery; `install_script_validation_test.dart`,
  `testing_utils_test.dart`, `version_format_test.dart`, and
  `fixtures/releases_schema_compatibility_test.dart` were never listed. Now
  added in `dart_test.yaml:16-19`. Notably, `version_format_test.dart` carries
  the `stable@beta` rejection tests item 7 documents — on `main` those tests
  never ran in CI.
- **`scripts/test-workflows.sh` had real bugs — but not the one an earlier
  draft of this plan recorded.** The old `if [ $? -eq 0 ]` did follow the
  `act` invocation, so exit codes were read correctly (refuted by direct
  reading and a shell repro). What the branch actually fixes: unquoted
  `$ACT_CMD` word-splitting (now a bash array with quoted expansion), the
  act/Docker preflight checks running before argument parsing (which broke
  `--help` and made `-l` require Docker), and missing-value guards for
  `-w`/`-e`/`-j`.
- **`list_command.dart`** had an assignment-in-return
  (`return flutterSdkVersion = ...`) and a dead channel lookup, since
  `releaseChannel` is hardcoded `null` for channel-type versions.
- **CI enforcement tightened.** `test.yml`'s analyzer step went from the
  invertase action with `fatal-infos: false` to `dart analyze --fatal-infos`,
  and `test-os`/`integration-test`/`migration-test` now all gate on `test`.
- **`fvm_mcp` was hardened beyond the compile fix** — unexpected tool stack
  traces now stay server-side instead of returning to MCP clients
  (`fvm_mcp/CHANGELOG.md:21`), and a 205-line end-to-end `server_test.dart`
  was added. Scoped out of the root CHANGELOG in Gate 2.
- **`tool/release_tool`'s release listing now paginates.** `grind.dart`
  previously fetched a single `per_page=100` page; FVM already has more than
  100 releases, so the maintainer release-notes tooling silently truncated.

## Suggested order

Gates 1 and 2 unblock tagging and are independent of everything else — do them
first and the branch becomes shippable as an alpha. Gate 3 is a small isolated
fix. Gate 4 is best done now while the release service is still new, but does
not block the alpha. Gate 5 and decisions D1/D3 can become follow-up issues.
Item 19 is less a work item than a pre-tag checklist: re-read it immediately
before pushing the tag, because the pipeline has no tag-vs-pubspec safety net.
