# Issue #771: `fvm list` complains about semver when it's not relevant

## Metadata
- **Reporter**: @matthew-carroll
- **Created**: 2024-08-30
- **Issue Type**: feature/UX
- **URL**: https://github.com/leoafarias/fvm/issues/771

## Problem Summary
`fvm list` warns about semver compliance for custom fork versions (`fork/mybranch`). Docs don’t require semver for fork names.

## Proposed Solution
1. Update `assignVersionWeight` to treat forked/custom names as custom, avoiding the `0.0.0` fallback.
2. Add tests ensuring list command doesn’t warn for fork names.
3. Update docs to note optional naming guidance.

## Classification Recommendation
- Priority: **P2 - Medium**
- Suggested Folder: `validated/p2-medium/`
