# FVM Triage Agent Notes

Follow these steps whenever picking up the issue-triage workload:

1. Read the high-level workflow in `issue-triage/TRIAGE_AGENT.md`.
2. Pull the next issue from `issue-triage/pending_issues/open_issues.json`.
3. Investigate the repository and documentation as needed (search in `docs/`, `scripts/`, `lib/`, etc.).
4. Capture findings and plans in a new artifact (`issue-triage/artifacts/issue-<number>.md`) using the template from `issue-triage/artifacts/validation-template.md`.
5. Place a JSON summary in the appropriate folder:
   - `issue-triage/validated/p0-critical|p1-high|p2-medium|p3-low/`
   - `issue-triage/resolved/`
   - `issue-triage/version_specific/`
   - `issue-triage/needs_info/`
6. Append a brief bullet to the “Detailed Triage Results” list inside `issue-triage/artifacts/triage-log.md`.
7. Update the counters in the “Summary Statistics” block of `triage-log.md` so totals reflect the work done.

Directory highlights:

```
issue-triage/
├── TRIAGE_AGENT.md               # Full workflow and expectations
├── pending_issues/open_issues.json
├── artifacts/                    # Markdown reports + triage log
├── validated/                    # JSON summaries grouped by priority
├── resolved/
├── needs_info/
├── version_specific/
└── artifacts/validation-template.md
```

Keep edits scoped to triage research (no code fixes). Once all pending issues are processed, re-run `gh issue list` (or equivalent) to catch newly closed issues before handing off.
