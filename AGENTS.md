# FVM - Flutter Version Manager

CLI tool for managing Flutter SDK versions per project.

## Structure

- `bin/main.dart`: CLI entry point
- `lib/src/commands/`: CLI commands
- `lib/src/services/`: Business logic (cache, flutter, git, project)
- `lib/src/workflows/`: Multi-step orchestration
- `lib/src/models/`: Data models (dart_mappable)
- `test/`: Unit + integration tests

## Commands

```bash
dart pub get                    # Install dependencies
dart test                       # Unit tests
dart run grinder integration-test  # Integration suite (needs Flutter)
dart analyze --fatal-infos      # Analysis (must pass)
dcm analyze lib                 # Code metrics
dart run build_runner build --delete-conflicting-outputs  # Regenerate mappers
```

## Verification

Pre-commit hooks run automatically. Before pushing:
1. `dart analyze --fatal-infos` passes
2. `dcm analyze lib` passes
3. `dart test` passes

For final review on changes that affect `GitService`, `FlutterService`,
`EnsureCacheWorkflow`, install/use/global command behavior, prompt handling, or
project SDK references, also run the manual branch smoke test in
`docs/pages/documentation/guides/manual-smoke-test.md`. It uses isolated temp `HOME`,
`FVM_CACHE_PATH`, and `FVM_GIT_CACHE_PATH` values and includes cleanup guidance
for the temporary SDKs, git cache, project files, and config it creates.

## Architecture

Commands → Workflows → Services → Models

- Services accessed via `FvmContext.get<T>()`
- Workflows extend `Workflow` for multi-step operations
- Models use `@MappableClass()` with `part 'name.mapper.dart';`

## Critical Rules

- NEVER bypass git hooks with `--no-verify`
- YOU MUST run `build_runner build` after modifying `@MappableClass()` models
- Integration tests require Flutter: run `dart run grinder test-setup` first

## Gotchas

- Release tool (`tool/release_tool/`) requires Dart >=3.8.0
- Version format: `[fork/]version[@channel]` (e.g., `stable`, `3.24.0`, `custom-fork/3.24.0@beta`)

## Documentation

Developer docs live in `.context/docs/` and tracked guides under
`docs/pages/documentation/guides/`. Reference for specific tasks:

- @README.md - Project overview, release process
- @CHANGELOG.md - Version history, breaking changes
- @.github/workflows/README.md - CI/CD pipelines, deployment automation
- @.context/docs/testing-methodology.md - Test patterns, TestFactory, mocking
- @.context/docs/integration-tests.md - Real integration guardrails
- @docs/pages/documentation/guides/manual-smoke-test.md - Isolated final smoke test for git cache, install/use, prompts, symlinks, Melos, VS Code, and cleanup
- @.context/docs/version-parsing.md - Version parsing regex and logic
- @.context/docs/v4-release-notes.md - v4.0 architecture changes, migration

## Triage Workflow

Follow these steps whenever picking up the `issue-triage` workload:

1. Read the high-level workflow in `issue-triage/TRIAGE_AGENT.md`.
2. Pull the next issue from `issue-triage/pending_issues/open_issues.json`.
3. Investigate the repository and documentation as needed.
4. Capture findings and plans in `issue-triage/artifacts/issue-<number>.md` using `issue-triage/artifacts/validation-template.md`.
5. Place a JSON summary in the appropriate folder:
   - `issue-triage/validated/p0-critical|p1-high|p2-medium|p3-low/`
   - `issue-triage/resolved/`
   - `issue-triage/version_specific/`
   - `issue-triage/needs_info/`
6. Append a brief bullet to the `Detailed Triage Results` list in `issue-triage/artifacts/triage-log.md`.
7. Update the counters in the `Summary Statistics` block of `issue-triage/artifacts/triage-log.md`.

Keep triage edits scoped to research artifacts and queue bookkeeping. Once all pending issues are processed, re-run `gh issue list` or equivalent to catch newly closed issues before handing off.
