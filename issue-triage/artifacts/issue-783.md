# Issue #783: [BUG] DO NOT use short hash for commit versions (DOS attack)

## Metadata
- **Reporter**: @Leptopoda
- **Created**: 2024-09-16
- **Reported Version**: FVM 3.2.1
- **Issue Type**: security bug
- **URL**: https://github.com/leoafarias/fvm/issues/783

## Problem Summary
FVM writes only the short 10-character git hash to `.fvmrc`/VS Code settings when using commit versions. Short hashes can collide across forks (see [GitHub Actions DoS article](https://blog.teddykatz.com/2019/11/12/github-actions-dos.html)), so configs should store the full 40-character SHA.

## Proposed Fix
1. Ensure `UseVersionWorkflow` always stores `version.name` (full hash) for git references.
2. Audit the code path for configuration serialization to confirm no truncation occurs (add regression tests).
3. On write, normalize commit strings to lowercase 40-char SHA; convert short inputs by resolving via git.
4. For existing configs containing short hashes, detect and warn users to update.

## Classification Recommendation
- Priority: **P1 - High** (security correctness)
- Suggested Folder: `validated/p1-high/`

## Notes for Follow-up
- Add tests verifying `.fvmrc` uses full SHAs.
