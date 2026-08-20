# Actionable Priority Plan - 2026-06-10

> Updated 2026-06-16: #1030 is now closed as completed by PR #1033 and should not be treated as an active P1. Active P1 count is now 3: #1028, #688, and #914. PR #1037 also changed git-cache behavior, so revalidate #1028 after pulling latest `main`.
>
> Updated 2026-06-19: latest sync has 57 open issues. #1042 is a new P2 architecture/design item for multi-SDK-family support. #1015 is delegated to `mcp_task.md` and should not be worked from the regular priority queue.
>
> Updated 2026-06-22: latest sync has 56 open issues and 3 open PRs. #1015 is closed by merged PR #1038. #688 remains the only confirmed P1. #914 is downgraded to P2 because docs/workaround exist and remaining work is diagnostics. #1028 moved to needs-info/revalidation because it was reported on FVM 4.0.5 and 4.1.1 shipped relevant git-cache/hang fixes after all issue comments.
>
> Updated 2026-06-22 after maintainer comments: #1028 was closed as expected fixed in FVM 4.1.1 with retest instructions. #914 was closed as documented/not planned for automatic Git config mutation. Latest sync now has 54 open issues and 3 open PRs.
>
> Updated 2026-07-18: live sync has 56 open issues and 3 open PRs. New work is #1046 (fish terminal state, P2), #1047 (Windows arm64 installer/support gap, P2), and #1048 (intentional VS Code opt-out warning, P3). #1043 is closed by the v4.1.2 git-cache metadata fix. #688 remains the only P1.

## Objective
Validate that every live open issue has exactly one current classification, then identify the actionable work that should be executed first. This plan is a triage handoff: it records what to build or review next, but does not implement product code.

## Current Triage State
- Latest GitHub sync on 2026-07-18: `issue-triage/scripts/sync_github.sh` wrote 56 open issues and 3 open PRs.
- Active classifications after the 2026-07-18 revalidation: P0=0, P1=1, P2=31, P3=16, needs-info=8.
- Consistency audit: every open issue is active in exactly one classification folder; no active issue is closed; no duplicate active issue numbers.
- Branch state: the working branch is behind `origin/main`, but the urgency evidence below was rechecked directly against current `origin/main` (v4.1.2). Merge `origin/main` before final handoff.

## Verified Findings Log
- `issue-triage/pending_issues/open_issues.json` contains the authoritative 56 open issues from GitHub.
- `issue-triage/validated/p1-high/` contains #688 only. #1030 moved to `closed/` on 2026-06-16; #914 and #1028 moved to `closed/` on 2026-06-22.
- `lib/src/commands/install_command.dart` currently defaults `--setup` to true and does not expose an archive install flag.
- `lib/src/services/releases_service/models/version_model.dart` exposes `FlutterSdkRelease.archiveUrl`; `lib/src/services/releases_service/releases_client.dart` honors `FLUTTER_STORAGE_BASE_URL` for archive URLs, but installs do not consume those archives.
- `lib/src/services/git_service.dart` now uses heads/tags-only cache fetches after PR #1037, so #1028 needs reporter retest before more P1 work is scheduled.
- `lib/src/services/process_service.dart` uses `Process.run` by default when `echoOutput` is false, so long-running commands can be silent until exit.
- `docs/pages/documentation/troubleshooting/git-safe-directory-windows.md` and the FAQ link now exist, but `lib/src/commands/doctor_command.dart` only reports environment/project paths and does not validate Git `safe.directory`.

## Priority Order

### Completed - #1030 Non-Interactive Version Mismatch Hook Blocker
#1030 is closed as completed. Historical action item: `issue-triage/action_items/action_item_1030.md`.

### Closed - #1028 Silent Install/Use Hang During Mirror or Setup
Why closed: it was reported on FVM 4.0.5, and FVM 4.1.1 shipped git-cache and non-interactive hang fixes after all issue comments. The closing comment asks reporters to retest on 4.1.1 with a clean cache and `FVM_USE_GIT_CACHE=false`.

Action:
- Do not implement unless a reporter confirms a current 4.1.1 reproduction.
- If reopened, revive `issue-triage/action_items/action_item_1028.md` and scope it to the remaining failing path.

Acceptance:
- Reporter confirms whether 4.1.1 still reproduces.
- Reproduction identifies whether the hang is FVM git-cache, Flutter bootstrap, or local Windows environment.

### P1.1 - #688 Archive-Based Installs for Storage Mirrors
Why urgent: it blocks enterprise and restricted-network users who mirror Flutter SDK archives but cannot reach GitHub, and it is the only open issue that currently meets the P1 threshold.

Action:
- Use the refreshed `issue-triage/action_items/action_item_688.md` as the implementation/review handoff.
- Implement an archive install strategy that consumes `FlutterSdkRelease.archiveUrl` and validates `sha256`.
- Decide whether archive mode is explicit (`--archive`/config) or selected automatically when mirror env vars are present.
- First unblock PR #1013: its current failing `Test` check is a `fvm_mcp` format failure in `lib/src/process_runner.dart`, `lib/src/server.dart`, and `test/process_runner_test.dart`.

Acceptance:
- `FLUTTER_STORAGE_BASE_URL` and `FLUTTER_RELEASES_URL` can be used without GitHub clone access for official releases.
- Archive extraction produces the same usable cache shape as git installs.
- Checksums are enforced and failures are actionable.

### Closed - #914 Windows Git Safe Directory Doctor/CLI Messaging
Why closed: the issue is documented and automatic mutation of global Git config is not planned. Future explicit doctor diagnostics can be tracked separately.

Action:
- No active work in this triage queue.
- If maintainers want an explicit doctor diagnostic, open or track a separate issue scoped to diagnostics only.

## P2 Actionable Queue
- #1046: Reproduce the fish-only Ctrl+C terminal-state failure on 4.1.2, capture process-group/TTY state, and restore the exact pre-spawn terminal modes rather than forcing defaults.
- #1047: Fix Windows arm64 detection in `install.ps1`, use the existing `windows-arm64` FVM asset, and verify the remaining Flutter SDK architecture limitation on real Windows arm64 hardware.
- #1042: Define support boundaries for alternate SDK executables such as `flutter-tizen`; current fork aliases assume the standard `flutter` executable and do not satisfy the reporter's reproduced case.
- #767: Treat the repeatedly confirmed Android Studio symlink-resolution behavior as a valid P2 compatibility bug; reproduce against current IDE/plugin versions before choosing opt-in IntelliJ file management versus documentation.
- #1021: Review and merge PR #1022 (`chore: bump pub_updater to ^0.5.0`) if CI is green; this is the fastest P2 closure.
- #968: Add post-setup validation so missing tools like `unzip` fail the install/setup path instead of reporting success.
- #1024: Improve Windows no-admin fallback by detecting symlink privilege errors and continuing in non-privileged mode where possible.
- #1026: Design per-project JDK config without leaking Flutter global `--jdk-dir` state between projects.
- #1008: Extend Melos settings update to support `pubspec.yaml` `melos.sdkPath`.
- #894, #811, #826, #762: Treat as packaging/distribution roadmap items; group these into a release infrastructure milestone.
- #774 and #782: Documentation fixes with likely low implementation risk; handle as quick docs PRs when code P1s are not actively in flight.
- #575, #697, #754, #791, and #794: Revalidated as answered or implemented; use `issue-triage/ready-to-close.md` for the evidence-backed maintainer replies.
- #724 remains active: newer reports show Android Studio resolving or persisting physical SDK paths, so documentation alone does not close the underlying IDE compatibility gap.

## P3 Quick Fix
- #1048: Remove the warning when `updateVscodeSettings: false` is an explicit opt-out; retain debug logging and add a no-warning regression test.

## Needs-Info Handling
Do not implement #731, #748, #759, #781, #797, #809, #906, or #1017 until reporter data is available. For each one, the next action is a focused maintainer comment requesting the exact missing reproduction material already listed in `issue-triage/artifacts/triage-log.md`.

## Validation Commands
Run these before changing issue state or handing off:

```bash
bash issue-triage/scripts/sync_github.sh
find issue-triage -name '*.json' -print0 | xargs -0 -n1 jq empty
python3 - <<'PY'
import json
from pathlib import Path
from collections import Counter
root = Path('issue-triage')
open_nums = {int(i['number']) for i in json.loads((root / 'pending_issues/open_issues.json').read_text())}
active_dirs = [
    root / 'validated/p0-critical',
    root / 'validated/p1-high',
    root / 'validated/p2-medium',
    root / 'validated/p3-low',
    root / 'needs_info',
]
active = []
for folder in active_dirs:
    for path in folder.glob('issue-*.json'):
        active.append((int(json.loads(path.read_text())['number']), path))
active_nums = [number for number, _ in active]
assert not (open_nums - set(active_nums)), sorted(open_nums - set(active_nums))
assert not (set(active_nums) - open_nums), sorted(set(active_nums) - open_nums)
assert not [n for n, c in Counter(active_nums).items() if c > 1]
print('issue-triage classifications are in sync')
PY
git diff --check
```

Run these after implementing the P1 items:

```bash
dart analyze --fatal-infos
dart test test/src/workflows/ensure_cache_ci_test.dart test/src/services/logger_service_test.dart
dart test test/services/git_service_test.dart test/services/flutter_service_test.dart
dart test test/commands/doctor_command_test.dart
dart test
```

## Stop Conditions
- Stop and resync if `open_issues.json` changes count or an active issue disappears from GitHub.
- Stop before product implementation if a P1 has no artifact or no action item.
- Stop before closing any issue unless the artifact includes a current-code verification and a closure note.
- Stop before mutating global Git config for #914 unless there is an explicit opt-in command or prompt.
