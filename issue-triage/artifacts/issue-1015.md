# Issue #1015: Update docs to add info about using FVM with Dart MCP

## Metadata
- **Reporter**: @Harishwarrior
- **Created**: 2026-02-18
- **Reported Version**: N/A (documentation request)
- **Issue Type**: documentation
- **URL**: https://github.com/leoafarias/fvm/issues/1015

## Problem Summary
Reporter requests official docs for configuring Dart MCP to point at the FVM-managed SDK (`.fvm/flutter_sdk`) so AI tooling uses project-pinned Flutter.

## Version Context
- Reported against: docs
- Current version: v4 docs
- Version-specific: no
- Reason: this is a documentation gap independent of SDK runtime behavior.

## Validation Steps
1. Searched docs for MCP references.
2. Reviewed current VS Code and running-flutter docs for nearby guidance.
3. Confirmed there is no explicit Dart MCP configuration section.

## Evidence
```text
$ grep -RIn --include='*.md' --include='*.mdx' -i 'mcp' docs
(no matches)

docs/pages/documentation/guides/vscode.mdx:31-46
- Covers Dart Code extension integration and sdk path behavior.

docs/pages/documentation/guides/running-flutter.mdx:37-52
- Covers command/symlink usage but not MCP server flags.
```

**Files/Code References:**
- [docs/pages/documentation/guides/vscode.mdx:31](../docs/pages/documentation/guides/vscode.mdx#L31) - Existing IDE integration context.
- [docs/pages/documentation/guides/running-flutter.mdx:37](../docs/pages/documentation/guides/running-flutter.mdx#L37) - Current runtime guidance.

## Current Status in v4.0.0
- [x] Still reproducible
- [ ] Already fixed
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
**Action**: validate-p3

**Reason**: Valuable docs improvement with growing ecosystem relevance, but not a runtime defect.

## Notes
- Reporter linked a concrete MCP snippet that can seed the official example.

---
**Validated by**: Code Agent  
**Date**: 2026-03-03
