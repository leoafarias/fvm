# Issue #1015: Update docs to add info about using FVM with Dart MCP

## Metadata
- **Reporter**: @Harishwarrior
- **Created**: 2026-02-18
- **Reported Version**: N/A (documentation request)
- **Issue Type**: documentation
- **URL**: https://github.com/leoafarias/fvm/issues/1015

## 2026-06-16 Sync Update (Historical)
- At this checkpoint the issue and PR #1038 were still open.
- PR #1038 (`docs: add guide for using FVM with the Dart MCP server`) subsequently merged and closed #1015, as recorded below.

## 2026-06-19 Delegation Update (Historical)
- Removed from the regular P3 issue-triage queue by request.
- Delegated MCP ownership to `mcp_task.md`.
- Summary JSON moved to `issue-triage/delegated/mcp/issue-1015.json`.
- PR #1038 was the active implementation path and later closed #1015 when merged.

## 2026-06-22 Closure Update
- PR #1038 merged on 2026-06-19T16:29:09Z.
- GitHub issue #1015 closed on 2026-06-19T16:29:10Z.
- Summary JSON moved from delegated MCP to `issue-triage/closed/issue-1015.json`.
- No open MCP issue remains in the regular or delegated triage queues.

## Problem Summary
Reporter requests official docs for configuring Dart MCP to point at the FVM-managed SDK (`.fvm/flutter_sdk`) so AI tooling uses project-pinned Flutter.

## Version Context
- Reported against: docs
- Current version: v4.1.2 docs
- Version-specific: no
- Reason: this is a documentation gap independent of SDK runtime behavior.

## Validation Steps
1. Searched docs for MCP references.
2. Reviewed current VS Code and running-flutter docs for nearby guidance.
3. Confirmed the original gap, then verified PR #1038 added the dedicated Dart MCP guide and navigation entry before closing #1015.

## Evidence
```text
PR #1038 merged at 2026-06-19T16:29:09Z and closed #1015.
docs/pages/documentation/guides/dart-mcp.mdx now contains the FVM-specific configuration.
docs/pages/documentation/guides/_meta.json exposes the guide in navigation.

docs/pages/documentation/guides/vscode.mdx:31-46
- Covers Dart Code extension integration and sdk path behavior.

docs/pages/documentation/guides/running-flutter.mdx:37-52
- Covers command/symlink usage but not MCP server flags.
```

**Files/Code References:**
- [docs/pages/documentation/guides/vscode.mdx:31](../docs/pages/documentation/guides/vscode.mdx#L31) - Existing IDE integration context.
- [docs/pages/documentation/guides/running-flutter.mdx:37](../docs/pages/documentation/guides/running-flutter.mdx#L37) - Current runtime guidance.

## Current Status in v4.1.2
- [ ] Still reproducible
- [x] Already fixed
- [ ] Not applicable to v4.0.0
- [ ] Needs more information
- [ ] Cannot reproduce

## Troubleshooting/Implementation Plan

### Root Cause Analysis
MCP usage is increasingly common but current docs do not include a canonical FVM-compatible snippet, causing users to discover configuration through external issue threads.

### Proposed Solution
1. Add a dedicated docs section (`guides/vscode.mdx` or new `guides/ai-tools.mdx`) with MCP examples using `.fvm/flutter_sdk`.
2. Include OS-specific path notes and workspace-relative path guidance.
3. Add quick verification steps (`fvm doctor`, `fvm flutter --version`, MCP startup logs).
4. Cross-link from FAQ and quick-reference pages.

### Alternative Approaches (if applicable)
- Add only FAQ entry. Faster, but less discoverable than a guide section.

### Dependencies & Risks
- MCP flags/behavior can evolve; include version caveat and keep examples minimal.
- Ensure guidance does not conflict with existing VS Code Dart extension behavior.

### Related Code Locations
- [docs/pages/documentation/guides/quick-reference.md](../docs/pages/documentation/guides/quick-reference.md) - Good place for a short pointer link.

## Recommendation
**Action**: closed

**Reason**: PR #1038 added the requested guide and merged on 2026-06-19, automatically closing #1015. The summary is archived in `closed/`, and there is no remaining delegated MCP work.

## Notes
- Reporter linked a concrete MCP snippet that can seed the official example.
- PR #1038 implemented the requested guide and closed #1015.

---
**Validated by**: Code Agent  
**Date**: 2026-07-18
