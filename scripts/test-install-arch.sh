#!/usr/bin/env bash
set -euo pipefail

RED=$'\033[0;31m'
GREEN=$'\033[0;32m'
NC=$'\033[0m'

pass() { echo -e "${GREEN}✅ $1${NC}"; }
fail() { echo -e "${RED}❌ $1${NC}"; exit 1; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
INSTALL_SCRIPT="${REPO_ROOT}/docs/public/install.sh"
BASH_BIN="$(command -v bash)"
BASH_DIR="$(dirname "${BASH_BIN}")"
TMP_DIR="$(mktemp -d 2>/dev/null || mktemp -d -t 'fvm_install_arch_test')"
STUB_DIR="${TMP_DIR}/bin"
SYSCTL_STUB="${TMP_DIR}/sysctl"
TEST_HOME="${TMP_DIR}/home"

cleanup() {
  rm -rf "${TMP_DIR}"
}
trap cleanup EXIT

mkdir -p "${STUB_DIR}" "${TEST_HOME}"

# Stub uname to return controlled values
cat > "${STUB_DIR}/uname" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
case "${1:-}" in
  -s) printf '%s\n' "${FVM_TEST_UNAME_S:?}" ;;
  -m) printf '%s\n' "${FVM_TEST_UNAME_M:?}" ;;
  *)  echo "unexpected uname args: $*" >&2; exit 64 ;;
esac
EOF

# Stub sysctl that returns a controlled value or fails
cat > "${SYSCTL_STUB}" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
if [ "${FVM_TEST_SYSCTL_MODE:-value}" = "fail" ]; then
  exit 1
fi
if [ "${1:-}" = "-n" ] && [ "${2:-}" = "hw.optional.arm64" ]; then
  printf '%s\n' "${FVM_TEST_SYSCTL_VALUE:?}"
else
  echo "unexpected sysctl args: $*" >&2; exit 65
fi
EOF

chmod +x "${STUB_DIR}/uname" "${SYSCTL_STUB}"

# Verify the shipped helper still prefers /usr/sbin/sysctl over PATH sysctl.
# This catches regressions back to PATH-only resolution on macOS hosts.
assert_resolve_sysctl_prefers_absolute_path() {
  local output

  if [ ! -x "/usr/sbin/sysctl" ]; then
    echo "ℹ️  Skipping absolute-path sysctl precedence check on this host"
    return 0
  fi

  cat > "${STUB_DIR}/sysctl" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' "fake-path-sysctl"
EOF
  chmod +x "${STUB_DIR}/sysctl"

  # shellcheck disable=SC2016
  output="$(
    env \
      PATH="${STUB_DIR}:${BASH_DIR}" \
      HOME="${TEST_HOME}" \
      INSTALL_SCRIPT="${INSTALL_SCRIPT}" \
      "${BASH_BIN}" -c '
        set -euo pipefail
        source "$INSTALL_SCRIPT"
        resolve_sysctl_cmd
      '
  )"

  if [ "${output}" != "/usr/sbin/sysctl" ]; then
    fail "resolve_sysctl_cmd prefers absolute path -> expected '/usr/sbin/sysctl', got '${output}'"
  fi

  pass "resolve_sysctl_cmd prefers absolute path over PATH"
}

# Run detect_arch in an isolated subprocess with stubbed commands.
# sysctl_mode: "value" (returns sysctl_value), "fail" (sysctl exits 1), "missing" (no sysctl)
run_detect_arch() {
  local uname_s="$1"
  local uname_m="$2"
  local sysctl_mode="$3"
  local sysctl_value="${4:-}"

  # shellcheck disable=SC2016
  env \
    PATH="${STUB_DIR}:${BASH_DIR}" \
    HOME="${TEST_HOME}" \
    FVM_TEST_UNAME_S="${uname_s}" \
    FVM_TEST_UNAME_M="${uname_m}" \
    FVM_TEST_SYSCTL_MODE="${sysctl_mode}" \
    FVM_TEST_SYSCTL_VALUE="${sysctl_value}" \
    INSTALL_SCRIPT="${INSTALL_SCRIPT}" \
    SYSCTL_STUB="${SYSCTL_STUB}" \
    "${BASH_BIN}" -c '
      set -euo pipefail
      source "$INSTALL_SCRIPT"

      # Override resolve_sysctl_cmd to use our stub (or simulate missing)
      resolve_sysctl_cmd() {
        if [ "${FVM_TEST_SYSCTL_MODE}" = "missing" ]; then
          return 1
        fi
        printf "%s\n" "$SYSCTL_STUB"
        return 0
      }

      arch="$(detect_arch "${FVM_TEST_UNAME_S}")"
      printf "%s\n" "$arch"
    '
}

assert_arch() {
  local description="$1"
  local expected="$2"
  local uname_s="$3"
  local uname_m="$4"
  local sysctl_mode="$5"
  local sysctl_value="${6:-}"
  local output

  output="$(run_detect_arch "${uname_s}" "${uname_m}" "${sysctl_mode}" "${sysctl_value}")"
  if [ "${output}" != "${expected}" ]; then
    fail "${description} -> expected '${expected}', got '${output}'"
  fi
  pass "${description}"
}

assert_failure() {
  local description="$1"
  local expected_fragment="$2"
  local output

  set +e
  output="$(run_detect_arch "Linux" "mips64" "missing" "" 2>&1)"
  local status=$?
  set -e

  if [ "${status}" -eq 0 ]; then
    fail "${description} -> expected non-zero exit"
  fi
  if ! printf '%s' "${output}" | grep -Fq "${expected_fragment}"; then
    fail "${description} -> expected '${expected_fragment}', got '${output}'"
  fi
  pass "${description}"
}

echo "🧪 Testing install.sh architecture detection"
echo "============================================"

assert_resolve_sysctl_prefers_absolute_path

# Darwin + sysctl (the Rosetta fix)
assert_arch "Darwin under Rosetta selects arm64"       "arm64"   "Darwin" "x86_64" "value" "1"
assert_arch "Intel macOS selects x64"                   "x64"     "Darwin" "x86_64" "value" "0"

# Darwin fallbacks when sysctl is unavailable
assert_arch "Darwin falls back to uname arm64 when sysctl fails"   "arm64" "Darwin" "arm64"  "fail"
assert_arch "Darwin falls back to uname x64 when sysctl fails"     "x64"   "Darwin" "x86_64" "fail"
assert_arch "Darwin falls back to uname arm64 when sysctl missing" "arm64" "Darwin" "arm64"  "missing"
assert_arch "Darwin falls back to uname x64 when sysctl missing"   "x64"   "Darwin" "x86_64" "missing"

# Linux arch mapping
assert_arch "Linux aarch64 maps to arm64"   "arm64"   "Linux" "aarch64" "missing"
assert_arch "Linux armv7l maps to arm"      "arm"     "Linux" "armv7l"  "missing"
assert_arch "Linux riscv64 maps to riscv64" "riscv64" "Linux" "riscv64" "missing"

# Error case
assert_failure "Unsupported architecture fails" "error: unsupported architecture: mips64"

echo ""
echo "✅ All architecture tests passed!"
