# MCP Task Handoff

## Scope
This repo's regular `issue-triage` queue should not carry MCP-specific work. This file now records the completed MCP handoff for historical context.

## Current State
- Completed on GitHub: PR #1038 merged on 2026-06-19T16:29:09Z.
- Closed issue: #1015 closed on 2026-06-19T16:29:10Z.
- Triage status: archived in `issue-triage/closed/issue-1015.json`.
- Open MCP delegated issues: none as of 2026-06-22.

## Delegated Issue
- GitHub issue: #1015 - "Update docs to add info about using FVM with Dart MCP"
- Current state: closed
- Archived triage summary: `issue-triage/closed/issue-1015.json`
- Detailed artifact: `issue-triage/artifacts/issue-1015.md`
- Merged PR: #1038 - `docs: add guide for using FVM with the Dart MCP server`
- PR branch: `docs/dart-mcp-fvm-sdk`
- PR files:
  - `docs/pages/documentation/guides/_meta.json`
  - `docs/pages/documentation/guides/dart-mcp.mdx`

## Historical MCP Agent Task
1. Review PR #1038 and verify it fully addresses #1015.
2. Confirm the `.fvm/flutter_sdk` guidance is correct for FVM projects after `fvm use`.
3. Check whether non-symlink or `privilegedAccess: false` setups need a note or alternative path.
4. Validate the Dart MCP command example:
   ```json
   {
     "mcpServers": {
       "dart": {
         "command": "dart",
         "args": ["mcp-server", "--flutter-sdk", ".fvm/flutter_sdk"]
       }
     }
   }
   ```
5. Run the docs validation/build command used by this repo, or at minimum verify the docs page renders and links from guide navigation.
6. Merge or update PR #1038 as needed. Completed on 2026-06-19.
7. After GitHub closes #1015, remove or archive `issue-triage/delegated/mcp/issue-1015.json` and update `issue-triage/artifacts/triage-log.md`. Completed on 2026-06-22.

## Acceptance Criteria
- #1015 is closed on GitHub.
- The docs include a clear Dart MCP guide for FVM-managed Flutter SDKs.
- The guide is discoverable from the docs navigation.
- The regular issue triage queue no longer lists #1015 as P3/P2/P1 work.

## Out Of Scope
- Do not implement unrelated `fvm_mcp` package behavior in the issue-triage branch.
- Do not change FVM install/use/cache behavior unless a separate product issue explicitly requires it.
