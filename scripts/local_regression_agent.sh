#!/usr/bin/env bash

set -u

SCOPE="archive-only"
RUN_INTEGRATION="false"
RUN_HEAVY="false"
SKIP_FULL_FOR_ARCHIVE="false"
TIMESTAMP="$(date +%Y%m%d-%H%M%S)"
OUT_DIR=".context/testing-runs/${TIMESTAMP}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --scope)
      SCOPE="$2"
      shift 2
      ;;
    --integration)
      RUN_INTEGRATION="$2"
      shift 2
      ;;
    --heavy)
      RUN_HEAVY="$2"
      shift 2
      ;;
    --skip-full-for-archive)
      SKIP_FULL_FOR_ARCHIVE="true"
      shift
      ;;
    --out-dir)
      OUT_DIR="$2"
      shift 2
      ;;
    --help|-h)
      cat <<'USAGE'
Usage: scripts/local_regression_agent.sh [options]

Options:
  --scope <archive-only|full-regression>
  --integration <true|false>
  --heavy <true|false>
  --skip-full-for-archive
  --out-dir <path>
  -h, --help
USAGE
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      exit 2
      ;;
  esac
done

if [[ "$SCOPE" != "archive-only" && "$SCOPE" != "full-regression" ]]; then
  echo "Invalid --scope: $SCOPE" >&2
  exit 2
fi
if [[ "$RUN_INTEGRATION" != "true" && "$RUN_INTEGRATION" != "false" ]]; then
  echo "Invalid --integration: $RUN_INTEGRATION" >&2
  exit 2
fi
if [[ "$RUN_HEAVY" != "true" && "$RUN_HEAVY" != "false" ]]; then
  echo "Invalid --heavy: $RUN_HEAVY" >&2
  exit 2
fi

mkdir -p "$OUT_DIR"
LOG_FILE="$OUT_DIR/commands.log"
ENV_FILE="$OUT_DIR/env.txt"
SUMMARY_FILE="$OUT_DIR/summary.md"
FAIL_FILE="$OUT_DIR/failures.md"

: > "$LOG_FILE"
: > "$ENV_FILE"
: > "$FAIL_FILE"

FAIL_COUNT=0
FIRST_FAILURE=""

log() {
  printf '%s\n' "$*" | tee -a "$LOG_FILE"
}

record_failure() {
  local stage="$1"
  local command="$2"
  local exit_code="$3"
  local tail_output="$4"

  FAIL_COUNT=$((FAIL_COUNT + 1))
  if [[ -z "$FIRST_FAILURE" ]]; then
    FIRST_FAILURE="$stage :: $command"
  fi

  {
    echo "## Failure ${FAIL_COUNT}"
    echo "- Stage: ${stage}"
    echo "- Command: \\`${command}\\`"
    echo "- Exit code: ${exit_code}"
    echo "- Stderr/Output excerpt:"
    echo '```text'
    echo "$tail_output"
    echo '```'
    echo "- Next action: inspect command output and fix root cause before rerun."
    echo
  } >> "$FAIL_FILE"
}

run_cmd() {
  local stage="$1"
  shift
  local cmd="$*"

  log "[$stage] $cmd"
  local output
  if output=$(eval "$cmd" 2>&1); then
    printf '%s\n' "$output" >> "$LOG_FILE"
    return 0
  else
    local code=$?
    printf '%s\n' "$output" >> "$LOG_FILE"
    local excerpt
    excerpt=$(printf '%s\n' "$output" | tail -n 40)
    record_failure "$stage" "$cmd" "$code" "$excerpt"
    return "$code"
  fi
}

run_expect_fail() {
  local stage="$1"
  shift
  local cmd="$*"

  log "[$stage][EXPECT_FAIL] $cmd"
  local output
  if output=$(eval "$cmd" 2>&1); then
    printf '%s\n' "$output" >> "$LOG_FILE"
    record_failure "$stage" "$cmd" "0" "Expected non-zero exit, but command succeeded."
    return 1
  else
    printf '%s\n' "$output" >> "$LOG_FILE"
    return 0
  fi
}

stage_status() {
  local name="$1"
  local status="$2"
  echo "- ${name}: ${status}" >> "$SUMMARY_FILE"
}

{
  echo "# Local Regression Run"
  echo "- timestamp: ${TIMESTAMP}"
  echo "- scope: ${SCOPE}"
  echo "- run_integration: ${RUN_INTEGRATION}"
  echo "- run_heavy: ${RUN_HEAVY}"
  echo
  echo "## Stage Results"
} > "$SUMMARY_FILE"

{
  echo "pwd=$(pwd)"
  echo "branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || true)"
  echo "git_status_short=$(git status --short 2>/dev/null || true)"
  echo "uname=$(uname -a 2>/dev/null || true)"
} > "$ENV_FILE"

# Stage 0
if run_cmd "Stage 0" "pwd" && \
   run_cmd "Stage 0" "git rev-parse --abbrev-ref HEAD" && \
   run_cmd "Stage 0" "git status --short"; then
  stage_status "Stage 0 Workspace Guard" "PASS"
else
  stage_status "Stage 0 Workspace Guard" "FAIL"
fi

# Stage A
if run_cmd "Stage A" "dart --version" && \
   run_cmd "Stage A" "git --version" && \
   run_cmd "Stage A" "dart pub get"; then

  if [[ "$(uname -s)" != "MINGW" && "$(uname -s)" != "MSYS" && "$(uname -s)" != CYGWIN* ]]; then
    run_cmd "Stage A" "which tar" || true
    run_cmd "Stage A" "which unzip" || true
  fi

  if command -v flutter >/dev/null 2>&1; then
    run_cmd "Stage A" "flutter --version" || true
  else
    log "[Stage A] flutter not found (non-blocking warning)"
  fi

  stage_status "Stage A Environment Preflight" "PASS"
else
  stage_status "Stage A Environment Preflight" "FAIL"
  goto_end=true
fi

if [[ "${goto_end:-false}" == "true" ]]; then
  :
else
  # Stage B
  if run_cmd "Stage B" "dart analyze --fatal-infos" && \
     run_cmd "Stage B" "dcm analyze lib"; then
    stage_status "Stage B Static Gates" "PASS"
  else
    stage_status "Stage B Static Gates" "FAIL"
    goto_end=true
  fi
fi

if [[ "${goto_end:-false}" == "true" ]]; then
  :
else
  # Stage C
  if run_cmd "Stage C" "dart test test/services/archive_service_test.dart" && \
     run_cmd "Stage C" "dart test test/commands/install_command_test.dart" && \
     run_cmd "Stage C" "dart test test/commands/use_command_test.dart" && \
     run_cmd "Stage C" "dart test test/src/workflows/ensure_cache_ci_test.dart"; then
    stage_status "Stage C Targeted Archive Tests" "PASS"
  else
    stage_status "Stage C Targeted Archive Tests" "FAIL"
    goto_end=true
  fi
fi

if [[ "${goto_end:-false}" == "true" ]]; then
  :
else
  # Stage D
  if [[ "$SCOPE" == "full-regression" || "$SKIP_FULL_FOR_ARCHIVE" == "false" ]]; then
    if run_cmd "Stage D" "dart test"; then
      stage_status "Stage D Full Unit Regression" "PASS"
    else
      stage_status "Stage D Full Unit Regression" "FAIL"
      goto_end=true
    fi
  else
    stage_status "Stage D Full Unit Regression" "SKIPPED"
  fi
fi

if [[ "${goto_end:-false}" == "true" ]]; then
  :
else
  # Stage E
  if [[ "$RUN_INTEGRATION" == "true" ]]; then
    if run_cmd "Stage E" "dart run grinder test-setup" && \
       run_cmd "Stage E" "dart run grinder integration-test"; then
      stage_status "Stage E Integration" "PASS"
    else
      stage_status "Stage E Integration" "FAIL"
      goto_end=true
    fi
  else
    stage_status "Stage E Integration" "SKIPPED"
  fi
fi

if [[ "${goto_end:-false}" == "true" ]]; then
  :
else
  # Stage F
  if [[ "$RUN_HEAVY" == "true" ]]; then
    if run_cmd "Stage F" "dart run bin/main.dart install stable --archive --no-setup" && \
       run_expect_fail "Stage F" "dart run bin/main.dart install f4c74a6ec3 --archive" && \
       run_expect_fail "Stage F" "dart run bin/main.dart install 2.2.2@stable --archive" && \
       run_expect_fail "Stage F" "dart run bin/main.dart use 2.2.2@master --archive --skip-setup --skip-pub-get"; then
      stage_status "Stage F Local Archive CLI Smoke" "PASS"
    else
      stage_status "Stage F Local Archive CLI Smoke" "FAIL"
      goto_end=true
    fi
  else
    stage_status "Stage F Local Archive CLI Smoke" "SKIPPED"
  fi
fi

if [[ "$FAIL_COUNT" -eq 0 && "${goto_end:-false}" == "false" ]]; then
  echo >> "$SUMMARY_FILE"
  echo "- first_failure: none" >> "$SUMMARY_FILE"
  echo "- safe-to-ship: yes" >> "$SUMMARY_FILE"
  log "Run completed: PASS"
  exit 0
else
  echo >> "$SUMMARY_FILE"
  echo "- first_failure: ${FIRST_FAILURE:-unknown}" >> "$SUMMARY_FILE"
  echo "- safe-to-ship: no" >> "$SUMMARY_FILE"
  log "Run completed: FAIL"
  if [[ -s "$FAIL_FILE" ]]; then
    log "Failure report: $FAIL_FILE"
  fi
  exit 1
fi
