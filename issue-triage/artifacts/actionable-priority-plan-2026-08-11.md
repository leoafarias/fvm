# Actionable Issue Priority Plan — 2026-08-11

For the disposition and execution sequence covering all 57 open issues, see [all-open-issues-execution-plan-2026-08-11.md](all-open-issues-execution-plan-2026-08-11.md).

**Execution update:** nine completed, answered, duplicate, or not-applicable items were closed after this snapshot, leaving 48 open issues. See [issue-closure-audit-2026-08-11.md](issue-closure-audit-2026-08-11.md).

## Queue Snapshot

- **57 open issues** and **6 open pull requests** on GitHub.
- **P0:** none.
- **P1:** #688 only.
- Latest release: **FVM 4.1.2**.
- The `issue-triage` branch is current with `origin/issue-triage`; `origin/main` has 22 commits not merged into this branch. The existing dirty worktree overlaps 82 paths changed from `main`, so the merge was not forced.

## Priority 1 — Unblock archive installs (#688 / PR #1013)

**Why first:** This remains the only P1. Restricted-network and custom-engine users cannot rely solely on Git/GitHub clones and need archive metadata/storage mirrors.

**Next action:** Rebase PR #1013 on current `main`, fix the failing Linux `Test` formatting gate, review the large/stale diff, run the full suite plus the manual install/use smoke test, then validate against a real mirror before release.

**Risk:** The PR has not changed since 2026-06-22 while `main` has advanced; it must not be merged on the strength of old partial CI.

## Priority 2 — Review the fish SIGINT fix (#1046 / PR #1054)

**Why next:** This is the highest-value actionable runtime bug. Ctrl+C can leave fish terminals unusable, and the PR now includes a focused process-lifecycle change plus a POSIX PTY regression test.

**Next action:** Run the full CLI test matrix, manually verify in fish, inspect signal/exit-code behavior on macOS and Linux, and review Windows implications before merging.

**Risk:** GitHub currently shows only a failed Vercel authorization status and no complete CLI CI run or review decision.

## Priority 3 — Clear small PR-backed compatibility work

1. **#1021 / PR #1022 — `pub_updater` 0.5 compatibility:** rebase and run current CLI tests; this removes dependency-resolution friction in Dart workspaces.
2. **#762 / PR #1053 — Docker ARM64:** verify the two workflow changes with a multi-architecture build and image smoke test, then merge if manifests contain both amd64 and arm64.
3. **PR #1051 — `.gitignore` documentation:** verify the canonical ignored path and merge or close; this is documentation-only and should not remain indefinitely unstable because of Vercel authorization.

## Queue Hygiene

- **#1055:** answer with version/update commands and close; optional docs follow-up.
- Existing ready-to-close issues: **#575, #697, #754, #791, #794**.
- Do not elevate **#1050** (native Windows ARM64 package-manager delivery) above P2; standalone native archives already work.
- Keep **#968** in the next unassigned P2 tranche because false setup success can waste significant user time even though no current PR addresses it.

## Recommended Order

1. Repair/rebase #1013.
2. Put PR #1054 through full CI and review.
3. Reply to and close #1055.
4. Process PRs #1022, #1053, and #1051.
5. Work through the five previously validated closure candidates.
