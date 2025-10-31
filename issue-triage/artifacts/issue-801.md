# Issue #801: [BUG] FVM breaks Terminal when using fish

## Metadata
- **Reporter**: @gferon
- **Created**: 2024-11-28
- **Reported Version**: FVM 3.2.1
- **Issue Type**: bug (high severity for fish users)
- **URL**: https://github.com/leoafarias/fvm/issues/801

## Problem Summary
Running `fvm flutter …` inside the fish shell and aborting with `Ctrl+C` leaves the terminal unusable until it is closed.

## Version Context
- Current version: v4.0.0 (behavior unchanged)

## Validation Steps
1. Reviewed `ProcessService.run`. When `echoOutput` is false (default), FVM uses `Process.run` without `inheritStdio`. Signals like `Ctrl+C` do not reach the child process, and the parent process terminates leaving terminal state broken.
2. `FlutterService.runFlutter` always invokes `ProcessService.run` with `echoOutput == false`, meaning interactive commands never inherit stdio.

## Proposed Implementation Plan
1. Default `runFlutter` (and other CLI-facing commands) to `echoOutput: true` so subprocesses inherit stdio, enabling proper signal handling.
2. For cases that need captured output (if any), add explicit flag to request buffered execution.
3. Add regression test or manual QA instructions: run `fvm flutter pub get` in fish, abort with `Ctrl+C`, confirm shell remains usable.
4. Document fix in changelog.

## Classification Recommendation
- Priority: **P1 - High**
- Suggested Folder: `validated/p1-high/`

## Notes for Follow-up
- Validate on Bash/Zsh as well to ensure no regressions.
