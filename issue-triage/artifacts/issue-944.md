# Issue #944: [BUG] 404 for https://fvm.app/documentation/installation

## Metadata
- **Reporter**: Seth Ladd (@sethladd)
- **Created**: 2025-10-29
- **Reported Version**: Not specified (reported from public docs)
- **Issue Type**: documentation
- **URL**: https://github.com/leoafarias/fvm/issues/944

## Problem Summary
The "Getting Started" page links to `/documentation/installation`, which returns a 404. Users following the primary install call-to-action cannot reach the installation guide.

## Version Context
- Reported against: Unknown (observed on docs published with v4.0.0 launch)
- Current version: v4.0.0
- Version-specific: no — affects the live v4 documentation site

## Validation Steps
1. Requested the affected URL (`https://fvm.app/documentation/installation`) and confirmed it returns HTTP 404.
2. Checked the intended installation page (`https://fvm.app/documentation/getting-started/installation`) and verified it resolves with HTTP 200.
3. Reviewed `docs/pages/documentation/getting-started/index.md` and found the "Next Steps" links use `./installation`, `./configuration`, and `./faq`, which Nextra resolves to `/documentation/<slug>` instead of `/documentation/getting-started/<slug>`.

## Evidence
```
$ curl -s -I https://fvm.app/documentation/installation
HTTP/2 404
...

$ curl -s -I https://fvm.app/documentation/getting-started/installation
HTTP/2 200
...

$ sed -n '33,38p' docs/pages/documentation/getting-started/index.md
## Next Steps

1. [Install FVM](./installation) on your system
2. [Configure](./configuration) your first project
3. Check the [FAQ](./faq) for common questions
```

## Current Status in v4.0.0
- [x] Still reproducible
- [ ] Already fixed
- [ ] Not applicable to v4.0.0
- [ ] Needs more information

## Troubleshooting/Implementation Plan

### Root Cause Analysis
The "Getting Started" overview page relies on relative links (`./installation`, `./configuration`, `./faq`). Under the current Nextra configuration, those links resolve relative to `/documentation/`, dropping the `getting-started/` segment and leading to 404s for each target page.

### Proposed Solution
1. Update `docs/pages/documentation/getting-started/index.md:35-37` to use explicit paths (`/documentation/getting-started/installation`, `/documentation/getting-started/configuration`, `/documentation/getting-started/faq`) so the generated site points to the correct routes.
2. Run the docs build from `docs/` (`yarn install && yarn build`) to ensure the site compiles without warnings.
3. Manually verify the rendered HTML (locally via `yarn dev` or in the deployed preview) to confirm the "Next Steps" links no longer produce 404s.
4. Spot-check other doc pages for similar relative links (e.g., `rg "\./" docs/pages/documentation`) and correct any additional instances.

### Alternative Approaches (if applicable)
- Investigate Nextra configuration for relative link handling (e.g., enabling `trailingSlash` or adjusting the docs basePath) to preserve `./` semantics, though this is heavier than fixing the explicit links.

### Dependencies & Risks
- Requires Node/Yarn environment for docs build verification.
- Minimal risk; only affects documentation content but should still verify no navigation regression elsewhere.

## Classification Recommendation
- Priority: **P0 - Critical** (broken primary installation docs link)
- Suggested Folder: `validated/p0-critical/`

## Notes for Follow-up
- After deploying the fix, re-test the live site to confirm Vercel cache invalidation and link correctness.
