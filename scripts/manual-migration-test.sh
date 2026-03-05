#!/usr/bin/env bash
#
# Reproducible manual migration test for legacy (non-bare) git cache migration.
#
# This script validates:
# 1) legacy cache is created as non-bare with legacy alternates paths
# 2) current branch migrates cache to bare mirror and rewrites alternates
# 3) list command works and migrated SDK binaries execute
#
# Default cache path is isolated in this repo's .context/tmp directory.
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

FVM_CACHE_PATH_DEFAULT="${REPO_ROOT}/.context/tmp/fvm-migration-cache"
LEGACY_FVM_VERSION="4.0.1"
RELEASE_VERSION=""
FVM_CACHE_PATH="${FVM_CACHE_PATH_DEFAULT}"
DO_CLEANUP=0

usage() {
  cat <<'EOF'
Usage: ./scripts/manual-migration-test.sh [options]

Options:
  --cache-path <path>         Override cache path.
  --legacy-fvm <version>      Legacy fvm version used to seed cache (default: 4.0.1).
  --release-version <value>   Stable release version to install (defaults to 2nd latest stable).
  --cleanup                   Remove the test cache at the end.
  -h, --help                  Show this help.

Environment:
  The script forces FVM_USE_GIT_CACHE=true.
EOF
}

log() {
  printf '[manual-migration] %s\n' "$1"
}

fail() {
  printf '[manual-migration][ERROR] %s\n' "$1" >&2
  exit 1
}

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || fail "Required command not found: $1"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --cache-path)
      FVM_CACHE_PATH="${2:-}"
      shift 2
      ;;
    --legacy-fvm)
      LEGACY_FVM_VERSION="${2:-}"
      shift 2
      ;;
    --release-version)
      RELEASE_VERSION="${2:-}"
      shift 2
      ;;
    --cleanup)
      DO_CLEANUP=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      fail "Unknown option: $1"
      ;;
  esac
done

[[ -n "${FVM_CACHE_PATH}" ]] || fail "--cache-path cannot be empty"
[[ -n "${LEGACY_FVM_VERSION}" ]] || fail "--legacy-fvm cannot be empty"

cd "${REPO_ROOT}"
mkdir -p "${REPO_ROOT}/.context/tmp"

require_cmd git
require_cmd dart
require_cmd fvm
require_cmd rg

ORIGINAL_FVM_VERSION="$(fvm --version 2>/dev/null || true)"

restore_fvm_version() {
  if [[ -n "${ORIGINAL_FVM_VERSION}" && "${ORIGINAL_FVM_VERSION}" != "${LEGACY_FVM_VERSION}" ]]; then
    log "Restoring global fvm version to ${ORIGINAL_FVM_VERSION}"
    if ! dart pub global activate fvm "${ORIGINAL_FVM_VERSION}" >/dev/null; then
      printf '[manual-migration][WARN] Failed to restore fvm %s. Current fvm: %s\n' \
        "${ORIGINAL_FVM_VERSION}" "$(fvm --version 2>/dev/null || echo unknown)" >&2
    fi
  fi
}
trap restore_fvm_version EXIT

export FVM_CACHE_PATH
export FVM_USE_GIT_CACHE=true

log "Preflight"
printf 'git: %s\n' "$(git --version)"
printf 'dart: %s\n' "$(dart --version 2>&1)"
printf 'fvm: %s\n' "$(fvm --version)"
printf 'branch: %s\n' "$(git branch --show-current)"
printf 'cache: %s\n' "${FVM_CACHE_PATH}"

log "Step 1: clean slate"
rm -rf "${FVM_CACHE_PATH}"
mkdir -p "${FVM_CACHE_PATH}"

log "Step 2: activate legacy fvm ${LEGACY_FVM_VERSION}"
dart pub global activate fvm "${LEGACY_FVM_VERSION}" >/dev/null
[[ "$(fvm --version)" == "${LEGACY_FVM_VERSION}" ]] || fail "Failed to activate fvm ${LEGACY_FVM_VERSION}"

if [[ -z "${RELEASE_VERSION}" ]]; then
  log "Detecting 2nd latest stable release version"
  stable_json="$(fvm api releases --filter-channel stable --limit 2 --compress)"
  RELEASE_VERSION="$(printf '%s\n' "${stable_json}" | rg -o '"version":"[^"]+"' | sed -n '2p' | cut -d'"' -f4)"
  [[ -n "${RELEASE_VERSION}" ]] || fail "Could not detect stable release version"
fi
log "Using release version: ${RELEASE_VERSION}"

log "Step 2: seed legacy cache"
fvm install stable
fvm install "${RELEASE_VERSION}"
fvm install beta

log "Verify pre-migration state"
core_bare_before="$(git -C "${FVM_CACHE_PATH}/cache.git" config --bool core.bare)"
[[ "${core_bare_before}" == "false" ]] || fail "Expected legacy cache core.bare=false, got ${core_bare_before}"

mapfile -t alt_files_before < <(find "${FVM_CACHE_PATH}/versions" -path '*/.git/objects/info/alternates')
[[ "${#alt_files_before[@]}" -gt 0 ]] || fail "No alternates files found before migration"
for alt_file in "${alt_files_before[@]}"; do
  alt_target="$(cat "${alt_file}")"
  [[ "${alt_target}" == */.git/objects ]] || fail "Expected legacy alternates path in ${alt_file}, got ${alt_target}"
done

log "Step 3: trigger migration on current branch"
dart pub get >/dev/null
migration_log="${REPO_ROOT}/.context/tmp/migration-manual-run.log"
FVM_CACHE_PATH="${FVM_CACHE_PATH}" FVM_USE_GIT_CACHE=true \
  dart run bin/main.dart install stable | tee "${migration_log}"

for expected in \
  "Migrating cache clone to bare mirror..." \
  "Creating bare mirror from local clone..." \
  "Legacy cache migrated to bare mirror successfully!" \
  "Updated alternates for stable" \
  "Updated alternates for beta" \
  "Updated alternates for ${RELEASE_VERSION}"; do
  rg -Fq "${expected}" "${migration_log}" || fail "Missing migration log line: ${expected}"
done

log "Verify post-migration state"
core_bare_after="$(git -C "${FVM_CACHE_PATH}/cache.git" config --bool core.bare)"
[[ "${core_bare_after}" == "true" ]] || fail "Expected migrated cache core.bare=true, got ${core_bare_after}"

mapfile -t alt_files_after < <(find "${FVM_CACHE_PATH}/versions" -path '*/.git/objects/info/alternates')
[[ "${#alt_files_after[@]}" -gt 0 ]] || fail "No alternates files found after migration"
for alt_file in "${alt_files_after[@]}"; do
  alt_target="$(cat "${alt_file}")"
  [[ "${alt_target}" == */cache.git/objects ]] || fail "Expected bare alternates path in ${alt_file}, got ${alt_target}"
  [[ "${alt_target}" != */.git/objects ]] || fail "Found legacy alternates path after migration: ${alt_target}"
done

fsck_log="${REPO_ROOT}/.context/tmp/migration-fsck.log"
git -C "${FVM_CACHE_PATH}/cache.git" fsck --connectivity-only > "${fsck_log}" 2>&1
non_dangling_count="$(awk '!/^dangling commit / && NF{c++} END{print c+0}' "${fsck_log}")"
[[ "${non_dangling_count}" -eq 0 ]] || fail "git fsck reported non-dangling output; see ${fsck_log}"

log "Verify list output"
FVM_CACHE_PATH="${FVM_CACHE_PATH}" FVM_USE_GIT_CACHE=true dart run bin/main.dart list

log "Step 4: verify SDK executability"
"${FVM_CACHE_PATH}/versions/stable/bin/flutter" --version >/dev/null
"${FVM_CACHE_PATH}/versions/${RELEASE_VERSION}/bin/flutter" --version >/dev/null
"${FVM_CACHE_PATH}/versions/beta/bin/flutter" --version >/dev/null

log "Validation completed successfully"

if [[ "${DO_CLEANUP}" -eq 1 ]]; then
  log "Cleanup enabled: removing ${FVM_CACHE_PATH}"
  rm -rf "${FVM_CACHE_PATH}"
fi
