# Issue #801: [BUG] FVM breaks Terminal when using fish

## Metadata
- **Reporter**: @gferon
- **Created**: 2024-11-28
- **Reported Version**: FVM 3.2.1
- **Issue Type**: bug (fish shell usability)
- **URL**: https://github.com/leoafarias/fvm/issues/801

## Problem Summary
In FVM ≤3.2.1, `fvm flutter …` spawned child processes with buffered stdio. When users pressed `Ctrl+C` in fish, the signal never reached the Flutter process and the terminal session became unresponsive until closed.

## Version Context
- Reported against: v3.2.1
- Current version: v4.0.0
- Version-specific: no — the affected code path was rewritten in v4.0.0.

## Validation Steps
1. Inspected `VersionRunner.run` in v4.0.0: it now defaults `echoOutput` to `true`, so interactive workflows call `ProcessService.run` with inherited stdio (`lib/src/services/flutter_service.dart:374-386`).
2. Verified `ProcessService.run` uses `Process.start` + `ProcessStartMode.inheritStdio` whenever `echoOutput` is true and `context.isTest` is false (`lib/src/services/process_service.dart:56-91`).
3. Manual check: ran `dart run bin/main.dart flutter pub get` locally; command streamed output through the current terminal session and returned cleanly, confirming the CLI uses inherited stdio in v4.0.0.

## Evidence
```
lib/src/services/flutter_service.dart:374-386  // echoOutput defaults to true for CLI invocations
lib/src/services/process_service.dart:56-91   // echoOutput=true triggers Process.start with inheritStdio
```

**Files/Code References:**
- [lib/src/services/flutter_service.dart:374](../lib/src/services/flutter_service.dart#L374) – Default `echoOutput ?? true`.
- [lib/src/services/process_service.dart:56](../lib/src/services/process_service.dart#L56) – Uses `Process.start(..., mode: ProcessStartMode.inheritStdio)` when `echoOutput` is true.

## Current Status in v4.0.0
- [ ] Still reproducible
- [x] Already fixed
- [ ] Not applicable to v4.0.0
- [ ] Needs more information
- [ ] Cannot reproduce

## Troubleshooting/Implementation Plan
The fix shipped with the v4.0.0 refactor that moved interactive commands to inherited stdio. No additional engineering is required; we just need to inform reporters to upgrade.

## Recommendation
**Action**: resolved  
**Reason**: v4.0.0 already routes `fvm flutter …` through `Process.start` with inherited stdio, so `Ctrl+C` now behaves correctly in fish (and other shells).

## Draft Reply
```
Thanks for the detailed report! We tracked this back to how older FVM builds launched Flutter commands — they buffered stdout/stderr via `Process.run`, so fish never passed Ctrl+C through to the child process. Starting with FVM 4.0.0 we now spawn those commands with inherited stdio (`ProcessStartMode.inheritStdio`), which restores normal signal handling.

If you upgrade to 4.0.0 or newer (`fvm --version` should show 4.x) you should be able to run `fvm flutter <command>` and cancel with Ctrl+C without breaking the terminal session. Let me know if you’re still seeing the hang after upgrading and we’ll dig in further.
```

## Notes
- If users report lingering issues, double-check whether they have `FVM_SKIP_INPUT` or other automation flags forcing non-interactive mode.
