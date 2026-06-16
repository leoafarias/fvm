# Issue #1028: [Bug] FVM hangs indefinitely at "Downloading Dart SDK from Flutter engine..." on Windows

## Metadata
- **Reporter**: Dan-Solopago
- **Created**: 2026-04-21
- **Reported Version**: 4.0.5
- **Issue Type**: bug
- **URL**: https://github.com/leoafarias/fvm/issues/1028

## 2026-06-16 Sync Update
- Issue remains open.
- PR #1037 (`Fix git cache bloat and stale cache clones`) merged on 2026-06-16 and touched `GitService`, `FlutterService`, and `EnsureCacheWorkflow`.
- PR #1037 does not close #1028. Revalidate the hang/progress findings after pulling latest `main`, because git-cache behavior changed materially.

## Problem Summary
Multiple users report `fvm install` or `fvm use` appearing to hang while Flutter setup reports "Downloading Dart SDK from Flutter engine...". Later comments show at least one reproducible path where FVM is silently updating the large local Flutter git mirror, making the command look frozen.

## Version Context
- Reported against: v4.0.5 and v4.1.0 comments
- Current version: v4.0.0 triage baseline; branch package version is 4.0.5
- Version-specific: no
- Reason: The behavior involves setup/mirror update/process diagnostics and affects install/use workflows across reported platforms.

## Validation Steps
1. Reviewed the initial Windows report and follow-up comments.
2. Checked the setup path: `SetupFlutterWorkflow` runs `flutter --version`, which can trigger Dart SDK bootstrap.
3. Checked local mirror update: `_syncMirrorWithRemote` runs `git remote update --prune origin` through `ProcessService.run`, which captures output silently unless verbose paths are used.
4. Confirmed no timeout/stall detector exists in `ProcessService.run`.

## Evidence
```text
lib/src/workflows/setup_flutter.workflow.dart:16-24: setup delegates to FlutterService.setup and rethrows on failure.
lib/src/services/flutter_service.dart:518-520: setup runs flutter --version.
lib/src/services/git_service.dart:431-442: mirror sync runs git remote update --prune origin.
lib/src/services/process_service.dart:52-65: default Process.run captures stdout/stderr without streaming progress.
```

**Files/Code References:**
- [../../lib/src/workflows/setup_flutter.workflow.dart](../../lib/src/workflows/setup_flutter.workflow.dart) - setup workflow.
- [../../lib/src/services/flutter_service.dart](../../lib/src/services/flutter_service.dart) - install/setup execution.
- [../../lib/src/services/git_service.dart](../../lib/src/services/git_service.dart) - local mirror refresh.
- [../../lib/src/services/process_service.dart](../../lib/src/services/process_service.dart) - process execution lacks timeout/stall feedback.

## Current Status in v4.0.0
- [x] Still reproducible
- [ ] Already fixed
- [ ] Not applicable to v4.0.0
- [ ] Needs more information
- [ ] Cannot reproduce

## Troubleshooting/Implementation Plan

### Root Cause Analysis
There are likely two contributing paths. First, Flutter bootstrap can hang inside `flutter --version` while downloading Dart SDK. Second, the FVM local mirror update can run a long `git remote update` with no visible progress, which users perceive as an indefinite hang. Current process execution has no stall timeout, progress streaming, or actionable "still working" message.

### Proposed Solution
1. Update [../../lib/src/services/git_service.dart](../../lib/src/services/git_service.dart) to show progress for local mirror updates, especially before `git remote update --prune origin`.
2. Add streaming or heartbeat support to [../../lib/src/services/process_service.dart](../../lib/src/services/process_service.dart) for long-running git and Flutter setup commands.
3. Add a stall timeout with a diagnostic message that suggests `--verbose`, `FVM_USE_GIT_CACHE=false`, and manual cache cleanup/fetch steps.
4. For Windows setup hangs, capture the invoked shell/PowerShell path and include `flutter.bat --version` diagnostic guidance.
5. Add tests around long-running process handling and mirror-update messaging.

### Alternative Approaches
- Disable git cache by default on Windows until progress/timeout behavior is improved.
- Make local mirror updates opt-in for all platforms.
- Split install into clone and setup phases with separate progress labels.

### Dependencies & Risks
- Streaming output must not break existing quiet output behavior.
- Timeouts must not kill legitimate slow Flutter repository operations too aggressively.
- Process cleanup needs careful handling on Windows to avoid orphaned `git`, `dart`, or `flutter` children.

### Related Code Locations
- [../../lib/src/services/git_service.dart](../../lib/src/services/git_service.dart) - mirror cache management.
- [../../lib/src/services/flutter_service.dart](../../lib/src/services/flutter_service.dart) - install and setup process invocation.
- [../../lib/src/services/process_service.dart](../../lib/src/services/process_service.dart) - shared process wrapper.

## Recommendation
**Action**: validate-p1

**Reason**: Install/use can appear stuck indefinitely for multiple users, blocking setup. The latest evidence points to missing progress/diagnostics around long-running mirror/setup operations.

## Notes
The 2026-06-04 comment gives a likely workaround: manually run `git fetch --verbose --prune origin` inside the local cache, then rerun install. That workaround should be documented if the fix is not immediate.

---
**Validated by**: Code Agent
**Date**: 2026-06-10
