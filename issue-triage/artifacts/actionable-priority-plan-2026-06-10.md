# Actionable Priority Plan - 2026-06-10

> Updated 2026-06-16: #1030 is now closed as completed by PR #1033 and should not be treated as an active P1. Active P1 count is now 3: #1028, #688, and #914. PR #1037 also changed git-cache behavior, so revalidate #1028 after pulling latest `main`.

## Objective
Validate that every live open issue has exactly one current classification, then identify the actionable work that should be executed first. This plan is a triage handoff: it records what to build or review next, but does not implement product code.

## Current Triage State
- Latest GitHub sync on 2026-06-16: `issue-triage/scripts/sync_github.sh` wrote 56 open issues and 4 open PRs.
- Active classifications after the 2026-06-16 sync: P0=0, P1=3, P2=27, P3=17, needs-info=9.
- Consistency audit: every open issue is active in exactly one classification folder; no active issue is closed; no duplicate active issue numbers.
- Branch state: `origin/main` has been merged into `issue-triage`; the P1 evidence below was rechecked after that merge.

## Verified Findings Log
- `issue-triage/pending_issues/open_issues.json` contains the authoritative 58 open issues from GitHub.
- `issue-triage/validated/p1-high/` contains #688, #914, and #1028. #1030 moved to `closed/` on 2026-06-16.
- `lib/src/commands/install_command.dart` currently defaults `--setup` to true and does not expose an archive install flag.
- `lib/src/services/releases_service/models/version_model.dart` exposes `FlutterSdkRelease.archiveUrl`; `lib/src/services/releases_service/releases_client.dart` honors `FLUTTER_STORAGE_BASE_URL` for archive URLs, but installs do not consume those archives.
- `lib/src/services/git_service.dart` streams progress for initial mirror clone, but `_syncMirrorWithRemote` still runs `git remote update --prune origin` through `ProcessService.run`.
- `lib/src/services/process_service.dart` uses `Process.run` by default when `echoOutput` is false, so long-running commands can be silent until exit.
- `lib/src/workflows/ensure_cache.workflow.dart` still prompts on version mismatch unless `context.skipInput` is true.
- `lib/src/utils/context.dart` defines `skipInput` as CI or explicit `--fvm-skip-input`; it does not check `stdin.hasTerminal`.
- `docs/pages/documentation/troubleshooting/git-safe-directory-windows.md` and the FAQ link now exist, but `lib/src/commands/doctor_command.dart` only reports environment/project paths and does not validate Git `safe.directory`.

## Priority Order

### Completed - #1030 Non-Interactive Version Mismatch Hook Blocker
#1030 is closed as completed. Historical action item: `issue-triage/action_items/action_item_1030.md`.

### P1.1 - #1028 Silent Install/Use Hang During Mirror or Setup
Why second: it blocks setup and creates a high-support-cost "frozen install" experience on Windows and slow networks.

Action:
- Execute `issue-triage/action_items/action_item_1028.md`.
- Add progress, heartbeat, timeout, and diagnostics around local mirror updates and Flutter setup.
- Prefer a shared long-running process helper over one-off command handling.

Acceptance:
- Local mirror refresh emits visible progress or heartbeat before and during `git remote update --prune origin`.
- Long-running setup commands have bounded stall diagnostics and actionable recovery guidance.
- Tests verify that quiet long-running commands do not appear frozen.

### P1.2 - #688 Archive-Based Installs for Storage Mirrors
Why third: it is the biggest strategic blocker for enterprise or restricted-network users, but it is larger than the two immediate runtime regressions.

Action:
- Refresh `issue-triage/action_items/action_item_688.md` before coding because some command examples predate the current install command defaults.
- Implement an archive install strategy that consumes `FlutterSdkRelease.archiveUrl` and validates `sha256`.
- Decide whether archive mode is explicit (`--archive`/config) or selected automatically when mirror env vars are present.

Acceptance:
- `FLUTTER_STORAGE_BASE_URL` and `FLUTTER_RELEASES_URL` can be used without GitHub clone access for official releases.
- Archive extraction produces the same usable cache shape as git installs.
- Checksums are enforced and failures are actionable.

### P1.3 - #914 Windows Git Safe Directory Doctor/CLI Messaging
Why fourth: the documentation portion is now present on main, so remaining work is important but narrower.

Action:
- Execute the remaining scope in `issue-triage/action_items/action_item_914_docs_and_doctor.md`.
- Add `fvm doctor` detection for Git `safe.directory` failures on Windows.
- Intercept the misleading "Unable to find git in your PATH" failure and point users to the troubleshooting page.
- Consider an explicit opt-in fix command; do not silently mutate global Git config.

Acceptance:
- A Windows safe-directory failure produces a targeted explanation, not a generic PATH/Git missing error.
- `fvm doctor` reports the condition and the exact command the user may run.
- Existing docs remain linked from FAQ and troubleshooting navigation.

## P2 Actionable Queue
- #1021: Review and merge PR #1022 (`chore: bump pub_updater to ^0.5.0`) if CI is green; this is the fastest P2 closure.
- #968: Add post-setup validation so missing tools like `unzip` fail the install/setup path instead of reporting success.
- #1024: Improve Windows no-admin fallback by detecting symlink privilege errors and continuing in non-privileged mode where possible.
- #1026: Design per-project JDK config without leaking Flutter global `--jdk-dir` state between projects.
- #1008: Extend Melos settings update to support `pubspec.yaml` `melos.sdkPath`.
- #894, #811, #826, #794, #762: Treat as packaging/distribution roadmap items; group these into a release infrastructure milestone.
- #774 and #782: Documentation fixes with likely low implementation risk; handle as quick docs PRs when code P1s are not actively in flight.
- #697, #724, #575, #791: Mostly documentation or closure-comment candidates; revalidate immediately before closing because they remain open in GitHub.

## Needs-Info Handling
Do not implement #731, #748, #759, #767, #781, #797, #809, #906, or #1017 until reporter data is available. For each one, the next action is a focused maintainer comment requesting the exact missing reproduction material already listed in `issue-triage/artifacts/triage-log.md`.

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
