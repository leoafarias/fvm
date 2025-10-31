# Issue #915: [DOC BUG] Broken links in https://fvm.app/documentation/getting-started and improve Mac installation instruction

## Metadata
- **Reporter**: @imanabu
- **Created**: 2025-09-21
- **Reported Version**: Docs as of Sep 2025
- **Issue Type**: documentation
- **URL**: https://github.com/leoafarias/fvm/issues/915

## Problem Summary
The reporter flagged two problems on the Getting Started page: (1) the Quick Start section lacked the `brew tap` prerequisite, and (2) hyperlinks under “Next Steps” drop the `getting-started/` segment and return 404s.

## Version Context
- Reported against: documentation published with FVM v3.x/v4 launch
- Current version: v4.0.0
- Version-specific: no — affects the live docs until updated

## Validation Steps
1. Checked `docs/pages/documentation/getting-started/index.md` and confirmed the Quick Start instructions now include both `brew tap leoafarias/fvm` and `brew install fvm`, so part (1) has been addressed since the issue was opened.
2. Queried `https://fvm.app/documentation/installation` and verified it still returns HTTP 404, so the broken links remain.
3. Documented the overlap with issue #944, which tracks the same broken navigation.

## Evidence
```
$ nl -ba docs/pages/documentation/getting-started/index.md | sed -n '10,22p'
    10 ## Quick Start
    14 brew tap leoafarias/fvm
    15 brew install fvm

$ curl -s -I https://fvm.app/documentation/installation | head -n 1
HTTP/2 404
```

## Current Status in v4.0.0
- [x] Still reproducible (broken links)
- [ ] Already fixed
- [ ] Not applicable to v4.0.0
- [ ] Needs more information

## Troubleshooting/Implementation Plan

### Root Cause Analysis
The Quick Start complaint is already resolved, but the “Next Steps” links on the Overview page still point to `/documentation/installation` instead of `/documentation/getting-started/installation`, producing 404s.

### Proposed Solution
1. Track the fix under issue #944 (update the relative links to explicit `/documentation/getting-started/...` paths). Once that change is merged, this issue can be closed as resolved/duplicate.
2. After deployment, re-test the live site to ensure `https://fvm.app/documentation/installation` redirects or returns 404 no longer.
3. Optionally add a regression test for docs navigation (e.g., a simple link checker in CI) to catch future broken URLs.

### Alternative Approaches
- Add temporary redirects on Vercel (`vercel.json`) mapping `/documentation/installation` to the getting-started page, but fixing the Markdown is cleaner.

### Dependencies & Risks
- None beyond the main docs fix already planned for #944.

## Classification Recommendation
- Priority: **P0 - Critical** (same broken docs as #944)
- Suggested Folder: `validated/p0-critical/`

## Notes for Follow-up
- Close this issue as soon as the #944 doc fix deploys; comment with confirmation that both concerns are addressed (Quick Start + links).
