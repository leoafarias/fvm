# Merged PR Issue Audit - 2026-06-16

## Scope
Audited GitHub PRs merged on or after 2026-06-10 and compared issue references against active triage folders.

## Merged PRs Checked

| PR | Merged At | Issue Closing References | Other `#` References | Triage Result |
| --- | --- | --- | --- | --- |
| #1032 - chore: consolidate test temp folders | 2026-06-10 | none | none | No issue action. |
| #1033 - fix: avoid false cache version mismatches from git describe tags | 2026-06-15 | #1030 | #1030 | #1030 already moved to `closed/`. |
| #1034 - chore: improve fast test mocks | 2026-06-10 | none | none | No issue action. |
| #1035 - chore: remove orphaned README testing guide and stale references | 2026-06-10 | none | #1034 (PR number) | No issue action. |
| #1036 - fix: treat non-TTY prompts as skipped input | 2026-06-12 | none | #1030 | Related to #1030, but did not close it; #1030 later closed by #1033. |
| #1037 - Fix git cache bloat and stale cache clones | 2026-06-16 | none | none | No direct issue closure. Keep #1028 active but revalidate after pulling latest `main`. |
| #1039 - chore: dart fix and format | 2026-06-15 | none | none | No issue action. |
| #1040 - chore: apply dart format, dart fix, and dcm fix | 2026-06-15 | none | none | No issue action. |
| #1041 - chore: prepare v4.1.1 release | 2026-06-16 | none | PR numbers #1030, #1032, #1033, #1035, #1036, #1037, #1039 | No additional issue action beyond already-closed #1030. |

## Closed Issue Sweep
`gh issue list --state closed --search 'closed:>=2026-06-10'` returned:

- #969 - closed as completed on 2026-06-11; already moved to `closed/`.
- #1030 - closed as completed on 2026-06-15; already moved to `closed/`.

## Open PR Watchlist
- #1038 is still open and explicitly closes #1015 if merged. Keep #1015 active in P3 until GitHub closes it.
- #1022 is still open for #1021. Keep #1021 active in P2 until the PR merges and the issue closes.

## Result
No additional active issue needs to be moved to `closed/` from the merged PR audit. Current active issue parity remains 56 open issues mapped to 56 active classifications.
