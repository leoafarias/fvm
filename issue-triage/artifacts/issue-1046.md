# Issue #1046: [BUG] FVM leaves fish terminal wedged in raw mode after Ctrl+C mid-command

## Metadata
- **Reporter**: zHElEARN
- **Created**: 2026-07-02
- **Reported Version**: FVM 4.1.2
- **Issue Type**: bug (shell / process lifecycle)
- **URL**: https://github.com/conceptadev/fvm/issues/1046

## Problem Summary
On **fish** (macOS), interrupting `fvm flutter …` with Ctrl+C mid-run leaves the terminal in raw mode: Enter prints `^M`, keys echo literally, and the only recovery is closing the pane. Leftover Flutter output and escape sequences continue after the prompt returns. Does **not** reproduce in zsh, and does **not** reproduce when running the same Flutter binary directly in fish.

## Version Context
- Reported against: FVM 4.1.2
- Current package version on branch: 4.1.1 (releases include 4.1.2)
- Version-specific: no
- Reason: Regression or incomplete fix relative to #801 (closed as fixed in 4.0.0 via `inheritStdio`). Still present on 4.1.2.

## Validation Steps
1. Read reporter differentiators: fish-only, FVM proxy only, direct Flutter OK, zsh OK.
2. Inspected current spawn path: `FlutterCommand` → `RunConfiguredFlutterWorkflow` → `FlutterService.run` → `VersionRunner` → `ProcessService.run` with `echoOutput: true` (default) and `ProcessStartMode.inheritStdio`.
3. Confirmed `ProcessService.run` still defaults `runInShell: true` for all spawns, including interactive Flutter proxies.
4. Confirmed no terminal raw-mode / line-mode restore logic in FVM; no SIGINT watchers or child-kill registry on current `main` (signal-forwarding from #1030 was explicitly reverted in `b63de225`).
5. Related #801 was closed as resolved via inheritStdio; this report is a post-4.0.0 recurrence with stronger shell isolation evidence.
6. Rechecked on 2026-08-11: PR #1054 (`fix: wait for Flutter cleanup after SIGINT`) now fixes #1046 with process-lifecycle changes, exit-code 130 handling, and a POSIX PTY regression test. It is still open with no maintainer review or full CLI CI result; GitHub only reports a failed Vercel authorization status and a neutral Vercel agent check.

## Evidence
```
lib/src/services/process_service.dart:36-87
  - echoOutput path uses Process.start(..., mode: ProcessStartMode.inheritStdio)
  - runInShell defaults to true

lib/src/services/flutter_service.dart:613-630
  - VersionRunner.run defaults echoOutput ?? true

bin/main.dart
  - No ProcessSignal.sigint watchers (reverted from #1030 experiment)

Reporter logs show Flutter spinner (⡿) interrupted, then post-prompt leakage of doctor sections and CSI sequences — child/TTY state not cleaned up.

PR #1054 (open):
  - waits for Flutter SIGINT cleanup
  - exits with code 130 and stops downstream workflows
  - adds a POSIX PTY regression test
  - still needs full CLI CI and maintainer review
```

**Files/Code References:**
- [lib/src/services/process_service.dart:45](../../lib/src/services/process_service.dart#L45) – `runInShell: true` default for Flutter proxy
- [lib/src/services/process_service.dart:67](../../lib/src/services/process_service.dart#L67) – inheritStdio spawn
- [lib/src/services/flutter_service.dart:592](../../lib/src/services/flutter_service.dart#L592) – VersionRunner
- [lib/src/workflows/run_configured_flutter.workflow.dart](../../lib/src/workflows/run_configured_flutter.workflow.dart) – proxy entry
- Related history: `68b87484` (child registry + SIGINT) / `b63de225` (reverted as unproven for #1030)

## Current Status in v4.0.0 / 4.1.x
- [x] Still reproducible (reporter on 4.1.2; fish-specific)
- [ ] Already fixed
- [ ] Not applicable to v4.0.0
- [ ] Needs more information
- [ ] Cannot reproduce

## Troubleshooting/Implementation Plan
**IMPORTANT**: Research and plan only — do not implement during triage.

### Root Cause Analysis
FVM sits between the shell and Flutter. Flutter doctor uses interactive TTY features (spinners / raw-ish terminal control). On Ctrl+C:

1. Fish’s process-group / job-control behavior differs from zsh.
2. FVM’s intermediate process (and possibly `runInShell: true` wrapping) changes who receives SIGINT and who is responsible for restoring terminal modes.
3. Flutter can exit or partially continue while leaving the tty in a non-canonical state; FVM does not restore `stdin.lineMode` / `stdin.echoMode` or guarantee process-group cleanup.
4. Post-prompt leakage strongly suggests orphaned or still-writing descendants after FVM thinks the command finished.

inheritStdio alone was enough for #801’s original “Ctrl+C doesn’t work” report, but not for fish terminal-mode restore after mid-command interrupt.

### Proposed Solution
0. **Start with PR #1054:** review its process lifecycle and workflow-stop behavior against the evidence below rather than implementing a second competing fix.
1. **Reproduce on fish** with `fvm flutter doctor -v` + Ctrl+C; capture `stty -a` before/after; compare process tree (`pstree` / `ps`) vs direct `flutter`.
2. **Try `runInShell: false`** for VersionRunner / Flutter proxy spawns so FVM is the direct parent of `flutter`/`dart` without an intermediate shell. Keep shell mode only where required (Windows PATH resolution edge cases).
3. **On SIGINT path (optional, evidence-gated):**
   - Ensure Flutter child is in the same process group as FVM **or** FVM forwards SIGINT and waits for child exit before returning.
   - Before spawning the child, capture `stdin.echoMode` and `stdin.lineMode` when `stdin.hasTerminal`; after child exit (including signal death), restore those exact values in `finally`. Do not force both modes to `true`, because callers may intentionally start with non-default terminal settings.
4. **Avoid re-shipping the full #1030 kill-all registry** unless reproduction proves orphans remain after (2)/(3); maintainers already declined unproven signal plumbing.
5. **Tests:** integration-style or documented manual smoke on fish; unit tests for any terminal-restore helper (mock stdin flags where possible).
6. **Docs/FAQ:** interim recovery (`reset` / close pane) and note fish-specific issue until fixed.

### Alternative Approaches
- Document “use zsh for FVM interactive commands” — poor UX, temporary only.
- Wrap Flutter in a tiny C/posix helper that restores TTY on exit — heavy-handed.
- Rely solely on Flutter fixing spinner cleanup — out of FVM control; still FVM’s extra process layer that triggers fish-only failure.

### Dependencies & Risks
- Changing `runInShell` may affect Windows command resolution and PATH lookup for `flutter`/`dart`.
- Signal handling must not break non-interactive CI or double-exit.
- Avoid regressing #801 (Ctrl+C must still reach Flutter).

### Related Code Locations
- [lib/src/services/process_service.dart](../../lib/src/services/process_service.dart) – spawn mode
- [lib/src/services/flutter_service.dart](../../lib/src/services/flutter_service.dart) – VersionRunner
- [bin/main.dart](../../bin/main.dart) – process lifecycle entry
- [issue-triage/artifacts/issue-801.md](issue-801.md) – prior fish Ctrl+C fix claim

## Recommendation
**Action**: validate-p2  
**Reason**: Confirmed post-4.1.2 shell-specific runtime bug with strong repro notes; not a full install blocker, but breaks interactive fish sessions. Overlaps incomplete #801 story and reverted #1030 signal work — needs targeted repro before any signal registry lands.

## Notes
- Closely related to closed #801; treat as reopened class of bug, not pure duplicate until 4.1.2 is verified fixed or not on maintainer fish.
- Reporter assets: video of wedged terminal attached on GitHub.
- Priority escalate to P1 only if confirmed across multiple shells or default macOS Terminal fish setups at scale.
- **2026-08-11 priority update:** keep P2, but treat PR #1054 as the best near-term actionable bug fix after the sole P1 (#688).
