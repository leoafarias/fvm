# Issue #786: Please bump dart_console to ^4.0.0

## Metadata
- **Reporter**: @provokateurin
- **Created**: 2024-10-08
- **Issue Type**: dependency upgrade
- **URL**: https://github.com/leoafarias/fvm/issues/786

## Problem Summary
`dart_console` is pinned to ^1.2.0. Upgrading to ^4.0.0 conflicts with `interact`, which depends on older versions.

## Validation Steps
1. Verified `pubspec.yaml` dependencies: `dart_console: ^1.2.0`, `interact: ^2.2.0`.
2. `interact` hasn’t released updates since 2022 and depends on older `dart_console`.
3. FVM uses `interact` only for confirmation/select prompts in `LoggerService`.

## Proposed Implementation Plan
1. Remove `interact` and rewrite prompts using `mason_logger` (already dependency) or custom prompt utility.
2. After removing `interact`, update `dart_console` to ^4.0.0 and run `dart pub upgrade`.
3. Add tests to ensure prompt behavior unchanged.
4. Document upgrade in changelog.

## Classification Recommendation
- Priority: **P2 - Medium** (dependency maintenance)
- Suggested Folder: `validated/p2-medium/`

## Notes for Follow-up
- Confirm `mason_logger` prompt APIs cover multi-select; if not, implement simple replacements.
