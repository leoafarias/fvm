# Action Item: Issue #600 – Improve Android Studio Configuration Docs

## Objective
Expand the Android Studio/IntelliJ guidance so users reliably point the IDE at `.fvm/flutter_sdk` and understand how the symlink updates across projects.

## Current State (v4.0.0)
- `docs/pages/documentation/guides/workflows.mdx:198-210` lists a terse three-step checklist without context or troubleshooting.
- `docs/pages/documentation/getting-started/configuration.mdx` does not cover Android Studio specifics or multi-module setups.

## Root Cause
Documentation was written prior to the v4 symlink workflow refresh; it lacks explanation of how `.fvm/flutter_sdk` behaves, how to rescan in Android Studio, and what to do when IDE caches stale paths.

## Implementation Steps
1. Update the Android Studio section in `docs/pages/documentation/guides/workflows.mdx`:
   - Explain that `fvm use` (per project) keeps `.fvm/flutter_sdk` up to date.
   - Add guidance for triggering **File → Sync with Gradle** or **Tools → Flutter → Sync Project** after switching versions.
   - Document how to fix cached paths (Invalidate Caches / Restart, re-select the SDK directory).
   - Include tips for multi-module/monorepo setups (each module points to its local `.fvm/flutter_sdk`).
2. Add screenshots or a short GIF illustrating the Project Structure dialog pointing at `.fvm/flutter_sdk` (store assets under `docs/public/img/` and reference them in the MDX).
3. Cross-link from `docs/pages/documentation/getting-started/configuration.mdx` to the enriched Android Studio instructions so users find the content from both entry points.
4. Note in the docs that if `.fvm/flutter_sdk` is missing users should run `fvm use` in the project root.

## Files to Modify
- `docs/pages/documentation/guides/workflows.mdx`
- `docs/pages/documentation/getting-started/configuration.mdx`
- (Optional) `docs/public/img/android-studio/*.png` for new screenshots

## Validation & Testing
- Run `npm run lint-docs` (or the project’s docs build command) to ensure MDX compiles.
- Manually inspect the Docs dev server (`npm run docs:dev`) to confirm links and images render.

## Completion Criteria
- Updated docs merged with screenshots, referencing `.fvm/flutter_sdk` behavior, troubleshooting, and multi-module guidance.
- Issue #600 commented with summary + link to the doc PR and then closed.

## References
- Planning artifact: `issue-triage/artifacts/issue-600.md`
- GitHub issue: https://github.com/leoafarias/fvm/issues/600
