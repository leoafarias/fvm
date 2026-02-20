# FVM Local Regression Testing Agent

## Purpose
This file defines a deterministic local-testing agent workflow for FVM. The agent validates local environment readiness, runs regression checks, and reports pass/fail with evidence.

Primary target: detect regressions in CLI behavior, with archive install behavior treated as mandatory coverage.

## Runtime Model
- This "agent" is command automation only.
- It does not invoke Claude, Codex, or any LLM during execution.
- It runs the scripted shell/Dart commands and reports results from those commands.

## Agent Inputs
- `scope`: `archive-only` or `full-regression`.
- `run_integration`: `true` or `false`.
- `run_heavy`: `true` or `false`.

Default values:
- `scope=archive-only`
- `run_integration=false`
- `run_heavy=false`

## Agent Outputs
- Terminal summary by stage.
- Artifacts written to `.context/testing-runs/<timestamp>/`:
  - `env.txt`
  - `commands.log`
  - `summary.md`
  - `failures.md` (if failures occur)

## Hard Rules
- Do not skip required checks.
- Do not use `--no-verify`.
- Stop immediately on blocker failures.
- Log every executed command.
- For expected-failure tests, treat success as failure.

## Execution Stages

### Stage 0: Workspace Guard
Commands:
1. `pwd`
2. `git rev-parse --abbrev-ref HEAD`
3. `git status --short`

Rules:
- Must run from repository root.
- Dirty tree is allowed, but report it in summary.

### Stage A: Environment Preflight (Blocker)
Commands:
1. `dart --version`
2. `git --version`
3. `dart pub get`
4. `which tar` (macOS/Linux)
5. `which unzip` (macOS/Linux)
6. `flutter --version` (optional warning if missing)

Fail if:
- `dart` missing,
- `git` missing,
- `dart pub get` fails,
- archive extraction tools missing for current OS.

### Stage B: Static Quality Gates
Commands:
1. `dart analyze --fatal-infos`
2. `dcm analyze lib`

Fail policy:
- Any failure stops the run.

### Stage C: Archive Regression Target Set
Commands:
1. `dart test test/services/archive_service_test.dart`
2. `dart test test/commands/install_command_test.dart`
3. `dart test test/commands/use_command_test.dart`
4. `dart test test/src/workflows/ensure_cache_ci_test.dart`

Required behavior coverage:
- unsupported archive version types rejected,
- qualifier rules enforced (`@stable` rejected, invalid qualifiers rejected),
- corrupted-cache reinstall preserves archive mode,
- finalize/swap flow is safe.

### Stage D: Full Unit Regression
Command:
1. `dart test`

Rules:
- Always run for `scope=full-regression`.
- For `scope=archive-only`, run unless explicitly skipped by caller.

### Stage E: Integration Suite (Optional)
Condition: `run_integration=true`

Commands:
1. `dart run grinder test-setup`
2. `dart run grinder integration-test`

Rules:
- If skipped, record explicit reason in `summary.md`.

### Stage F: Local Archive CLI Smoke (Optional)
Condition: `run_heavy=true`

Use local source command (not global dependency):
- `dart run bin/main.dart ...`

Positive check:
1. `dart run bin/main.dart install stable --archive --no-setup`

Expected-failure checks:
1. `dart run bin/main.dart install f4c74a6ec3 --archive`
2. `dart run bin/main.dart install 2.2.2@stable --archive`
3. `dart run bin/main.dart use 2.2.2@master --archive --skip-setup --skip-pub-get`

Rules:
- These expected-failure commands must exit non-zero.
- If any exits zero, mark run as failed.

## Reporting Contract
`summary.md` must include:
- input parameters,
- stage-by-stage status,
- first failure (if any),
- shipping recommendation (`safe-to-ship: yes/no`).

`failures.md` must include (for each failure):
- stage,
- command,
- exit code,
- concise stderr excerpt,
- recommended next action.

## Quick Start for Agents
Recommended command:

```bash
scripts/local_regression_agent.sh --scope archive-only --integration false --heavy false
```

Full run:

```bash
scripts/local_regression_agent.sh --scope full-regression --integration true --heavy true
```
