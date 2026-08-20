# Current Issues Ready to Close

Revalidated against live GitHub and `origin/main` on 2026-08-11. The nine
evidence-backed closure candidates from this audit have now received explanatory
comments and are closed: #575, #697, #720, #748, #754, #774, #791, #794, and
#1055.

No additional open issue currently meets the evidence threshold for immediate
closure. Valid feature requests remain open, and the seven uncertain bug reports
remain in `needs_info/` rather than being closed solely because of age.

## Open Pull Requests

These are not closure recommendations; they are the complete live PR queue.

- **#1013 - Archive install hardening**: addresses the sole P1 issue, #688.
  It is stale/unstable and the Linux `Test` check is failing. Rebase, review the
  drift, and fix CI before merge.
- **#1054 - Fish SIGINT cleanup**: addresses #1046 with focused process changes
  and PTY coverage. Run full CLI CI and manual fish verification before merge.
- **#1053 - Docker ARM64**: addresses #762 with two workflow platform changes.
  Validate a real multi-arch build and image manifests before merge.
- **#1051 - `.gitignore` docs**: documentation-only correction. Verify the
  canonical path and merge or close; Vercel authorization is not product CI.
- **#1022 - Bump `pub_updater` to `^0.5.0`**: addresses P2 issue #1021.
  It is mergeable, but it has no CLI test run and its Vercel status is failing;
  rebase or rerun the current checks before merge.
- **#828 - Dart SDK column in releases output**: older feature PR. Rebase and
  review against the current table/output implementation before deciding to
  merge or close.

## Summary

- **Issues ready for a maintainer reply and closure**: 0
- **Issues closed in the 2026-08-11 cleanup**: 9
- **Open pull requests**: 6
- **P0/P1 closure candidates**: 0
