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

Reference these for specific tasks:

- @README.md - Project overview, release process
- @CHANGELOG.md - Version history, breaking changes
- @.github/workflows/README.md - CI/CD pipelines, deployment automation
- @test/TESTING_METHODOLOGY.md - Test patterns, TestFactory, mocking
- @test/integration/README.md - Integration test phases (38 tests)
- @.context/docs/version-parsing.md - Version parsing regex and logic
- @.context/docs/v4-release-notes.md - v4.0 architecture changes, migration
