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
TMP_DIR="$(mktemp -d 2>/dev/null || mktemp -d -t 'fvm_install_arch_test')"
STUB_DIR="${TMP_DIR}/bin"
TEST_HOME="${TMP_DIR}/home"

cleanup() {
  rm -rf "${TMP_DIR}"
}
trap cleanup EXIT

mkdir -p "${STUB_DIR}" "${TEST_HOME}"

cat > "${STUB_DIR}/uname" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

case "${1:-}" in
  -s) printf '%s\n' "${FVM_TEST_UNAME_S:?}" ;;
  -m) printf '%s\n' "${FVM_TEST_UNAME_M:?}" ;;
  *)
    echo "unexpected uname args: $*" >&2
    exit 64
    ;;
esac
EOF

cat > "${STUB_DIR}/sysctl" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

case "${FVM_TEST_SYSCTL_MODE:-value}" in
  fail)
    exit 1
    ;;
  value)
    if [ "${1:-}" = "-n" ] && [ "${2:-}" = "hw.optional.arm64" ]; then
      printf '%s\n' "${FVM_TEST_SYSCTL_VALUE:?}"
    else
      echo "unexpected sysctl args: $*" >&2
      exit 65
    fi
    ;;
  *)
    echo "unexpected sysctl mode: ${FVM_TEST_SYSCTL_MODE:-}" >&2
    exit 66
    ;;
esac
EOF

cat > "${STUB_DIR}/curl" <<'EOF'
#!/usr/bin/env bash
echo "unexpected curl invocation: $*" >&2
exit 97
EOF

cat > "${STUB_DIR}/tar" <<'EOF'
#!/usr/bin/env bash
echo "unexpected tar invocation: $*" >&2
exit 98
EOF

chmod +x "${STUB_DIR}/uname" "${STUB_DIR}/sysctl" "${STUB_DIR}/curl" "${STUB_DIR}/tar"

run_install() {
  local uname_s="$1"
  local uname_m="$2"
  local sysctl_mode="$3"
  local sysctl_value="${4:-}"

  env \
    PATH="${STUB_DIR}:$PATH" \
    HOME="${TEST_HOME}" \
    FVM_INSTALL_TEST_MODE="print-target" \
    FVM_TEST_UNAME_S="${uname_s}" \
    FVM_TEST_UNAME_M="${uname_m}" \
    FVM_TEST_SYSCTL_MODE="${sysctl_mode}" \
    FVM_TEST_SYSCTL_VALUE="${sysctl_value}" \
    bash "${INSTALL_SCRIPT}"
}

assert_target() {
  local description="$1"
  local expected="$2"
  local uname_s="$3"
  local uname_m="$4"
  local sysctl_mode="$5"
  local sysctl_value="${6:-}"
  local output

  output="$(run_install "${uname_s}" "${uname_m}" "${sysctl_mode}" "${sysctl_value}")"
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
  output="$(
    env \
      PATH="${STUB_DIR}:$PATH" \
      HOME="${TEST_HOME}" \
      FVM_INSTALL_TEST_MODE="print-target" \
      FVM_TEST_UNAME_S="Linux" \
      FVM_TEST_UNAME_M="mips64" \
      FVM_TEST_SYSCTL_MODE="fail" \
      bash "${INSTALL_SCRIPT}" 2>&1
  )"
  local status=$?
  set -e

  if [ "${status}" -eq 0 ]; then
    fail "${description} -> expected non-zero exit"
  fi

  if ! printf '%s' "${output}" | grep -Fq "${expected_fragment}"; then
    fail "${description} -> expected output to contain '${expected_fragment}', got '${output}'"
  fi

  pass "${description}"
}

echo "🧪 Testing install.sh architecture detection"
echo "============================================"

assert_target \
  "Darwin under Rosetta still selects arm64" \
  "OS=macos ARCH=arm64" \
  "Darwin" \
  "x86_64" \
  "value" \
  "1"

assert_target \
  "Intel macOS selects x64" \
  "OS=macos ARCH=x64" \
  "Darwin" \
  "x86_64" \
  "value" \
  "0"

assert_target \
  "Darwin arm64 falls back to uname when sysctl fails" \
  "OS=macos ARCH=arm64" \
  "Darwin" \
  "arm64" \
  "fail"

assert_target \
  "Darwin x64 falls back to uname when sysctl fails" \
  "OS=macos ARCH=x64" \
  "Darwin" \
  "x86_64" \
  "fail"

assert_target \
  "Linux aarch64 maps to arm64" \
  "OS=linux ARCH=arm64" \
  "Linux" \
  "aarch64" \
  "fail"

assert_target \
  "Linux armv7l maps to arm" \
  "OS=linux ARCH=arm" \
  "Linux" \
  "armv7l" \
  "fail"

assert_target \
  "Linux riscv64 maps to riscv64" \
  "OS=linux ARCH=riscv64" \
  "Linux" \
  "riscv64" \
  "fail"

assert_failure \
  "Unsupported architectures still fail" \
  "error: unsupported architecture: mips64"

echo ""
echo "✅ All architecture tests passed!"
