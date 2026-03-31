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
CORE_STUB_DIR="${TMP_DIR}/core-bin"
PATH_SYSCTL_DIR="${TMP_DIR}/path-bin"
ABSOLUTE_SYSCTL_DIR="${TMP_DIR}/usr/sbin"
ABSOLUTE_SYSCTL_PATH="${ABSOLUTE_SYSCTL_DIR}/sysctl"
TEST_HOME="${TMP_DIR}/home"

cleanup() {
  rm -rf "${TMP_DIR}"
}
trap cleanup EXIT

mkdir -p "${CORE_STUB_DIR}" "${PATH_SYSCTL_DIR}" "${ABSOLUTE_SYSCTL_DIR}" "${TEST_HOME}"

cat > "${CORE_STUB_DIR}/uname" <<'EOF'
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

cat > "${PATH_SYSCTL_DIR}/sysctl" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

case "${FVM_TEST_PATH_SYSCTL_MODE:-value}" in
  fail)
    exit 1
    ;;
  value)
    if [ "${1:-}" = "-n" ] && [ "${2:-}" = "hw.optional.arm64" ]; then
      printf '%s\n' "${FVM_TEST_PATH_SYSCTL_VALUE:?}"
    else
      echo "unexpected sysctl args: $*" >&2
      exit 65
    fi
    ;;
  *)
    echo "unexpected sysctl mode: ${FVM_TEST_PATH_SYSCTL_MODE:-}" >&2
    exit 66
    ;;
esac
EOF

cat > "${ABSOLUTE_SYSCTL_PATH}" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

case "${FVM_TEST_ABSOLUTE_SYSCTL_MODE:-value}" in
  fail)
    exit 1
    ;;
  value)
    if [ "${1:-}" = "-n" ] && [ "${2:-}" = "hw.optional.arm64" ]; then
      printf '%s\n' "${FVM_TEST_ABSOLUTE_SYSCTL_VALUE:?}"
    else
      echo "unexpected sysctl args: $*" >&2
      exit 65
    fi
    ;;
  *)
    echo "unexpected sysctl mode: ${FVM_TEST_ABSOLUTE_SYSCTL_MODE:-}" >&2
    exit 66
    ;;
esac
EOF

chmod +x \
  "${CORE_STUB_DIR}/uname" \
  "${PATH_SYSCTL_DIR}/sysctl" \
  "${ABSOLUTE_SYSCTL_PATH}"

run_target_detection() {
  local uname_s="$1"
  local uname_m="$2"
  local path_sysctl_mode="$3"
  local path_sysctl_value="$4"
  local absolute_sysctl_mode="$5"
  local absolute_sysctl_value="$6"
  local path_prefix="${CORE_STUB_DIR}"

  if [ "$path_sysctl_mode" != "missing" ]; then
    path_prefix="${PATH_SYSCTL_DIR}:${CORE_STUB_DIR}"
  fi

  # shellcheck disable=SC2016
  env \
    PATH="${path_prefix}:${BASH_DIR}" \
    HOME="${TEST_HOME}" \
    FVM_TEST_UNAME_S="${uname_s}" \
    FVM_TEST_UNAME_M="${uname_m}" \
    FVM_TEST_PATH_SYSCTL_MODE="${path_sysctl_mode}" \
    FVM_TEST_PATH_SYSCTL_VALUE="${path_sysctl_value}" \
    FVM_TEST_ABSOLUTE_SYSCTL_MODE="${absolute_sysctl_mode}" \
    FVM_TEST_ABSOLUTE_SYSCTL_VALUE="${absolute_sysctl_value}" \
    INSTALL_SCRIPT="${INSTALL_SCRIPT}" \
    ABSOLUTE_SYSCTL_PATH="${ABSOLUTE_SYSCTL_PATH}" \
    "${BASH_BIN}" -c '
      set -euo pipefail

      source "$INSTALL_SCRIPT"

      resolve_sysctl_cmd() {
        if [ "${FVM_TEST_ABSOLUTE_SYSCTL_MODE}" != "missing" ]; then
          printf "%s\n" "$ABSOLUTE_SYSCTL_PATH"
          return 0
        fi

        if [ "${FVM_TEST_PATH_SYSCTL_MODE}" != "missing" ]; then
          command -v sysctl
          return 0
        fi

        return 1
      }

      case "${FVM_TEST_UNAME_S}" in
        Linux) os="linux" ;;
        Darwin) os="macos" ;;
        *)
          echo "error: unsupported OS: ${FVM_TEST_UNAME_S}" >&2
          exit 1
          ;;
      esac

      arch="$(detect_arch "${FVM_TEST_UNAME_S}")"
      printf "OS=%s ARCH=%s\n" "$os" "$arch"
    '
}

assert_target() {
  local description="$1"
  local expected="$2"
  local uname_s="$3"
  local uname_m="$4"
  local path_sysctl_mode="$5"
  local path_sysctl_value="$6"
  local absolute_sysctl_mode="$7"
  local absolute_sysctl_value="$8"
  local output

  output="$(
    run_target_detection \
      "${uname_s}" \
      "${uname_m}" \
      "${path_sysctl_mode}" \
      "${path_sysctl_value}" \
      "${absolute_sysctl_mode}" \
      "${absolute_sysctl_value}"
  )"
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
    # shellcheck disable=SC2016
    env \
      PATH="${CORE_STUB_DIR}:${BASH_DIR}" \
      HOME="${TEST_HOME}" \
      FVM_TEST_UNAME_S="Linux" \
      FVM_TEST_UNAME_M="mips64" \
      FVM_TEST_PATH_SYSCTL_MODE="missing" \
      FVM_TEST_PATH_SYSCTL_VALUE="" \
      FVM_TEST_ABSOLUTE_SYSCTL_MODE="missing" \
      FVM_TEST_ABSOLUTE_SYSCTL_VALUE="" \
      INSTALL_SCRIPT="${INSTALL_SCRIPT}" \
      ABSOLUTE_SYSCTL_PATH="${ABSOLUTE_SYSCTL_PATH}" \
      "${BASH_BIN}" -c '
        set -euo pipefail

        source "$INSTALL_SCRIPT"

        resolve_sysctl_cmd() {
          return 1
        }

        detect_arch "Linux"
      ' 2>&1
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
  "1" \
  "missing" \
  ""

assert_target \
  "Intel macOS selects x64" \
  "OS=macos ARCH=x64" \
  "Darwin" \
  "x86_64" \
  "value" \
  "0" \
  "missing" \
  ""

assert_target \
  "Darwin arm64 falls back to uname when sysctl fails" \
  "OS=macos ARCH=arm64" \
  "Darwin" \
  "arm64" \
  "fail" \
  "" \
  "missing" \
  ""

assert_target \
  "Darwin x64 falls back to uname when sysctl fails" \
  "OS=macos ARCH=x64" \
  "Darwin" \
  "x86_64" \
  "fail" \
  "" \
  "missing" \
  ""

assert_target \
  "Darwin uses absolute-path sysctl for arm64 when PATH sysctl is absent" \
  "OS=macos ARCH=arm64" \
  "Darwin" \
  "x86_64" \
  "missing" \
  "" \
  "value" \
  "1"

assert_target \
  "Darwin uses absolute-path sysctl for x64 when PATH sysctl is absent" \
  "OS=macos ARCH=x64" \
  "Darwin" \
  "x86_64" \
  "missing" \
  "" \
  "value" \
  "0"

assert_target \
  "Darwin falls back to uname when absolute-path sysctl fails" \
  "OS=macos ARCH=arm64" \
  "Darwin" \
  "arm64" \
  "missing" \
  "" \
  "fail" \
  ""

assert_target \
  "Darwin falls back to uname arm64 when no sysctl is available" \
  "OS=macos ARCH=arm64" \
  "Darwin" \
  "arm64" \
  "missing" \
  "" \
  "missing" \
  ""

assert_target \
  "Darwin falls back to uname x64 when no sysctl is available" \
  "OS=macos ARCH=x64" \
  "Darwin" \
  "x86_64" \
  "missing" \
  "" \
  "missing" \
  ""

assert_target \
  "Linux aarch64 maps to arm64" \
  "OS=linux ARCH=arm64" \
  "Linux" \
  "aarch64" \
  "missing" \
  "" \
  "missing" \
  ""

assert_target \
  "Linux armv7l maps to arm" \
  "OS=linux ARCH=arm" \
  "Linux" \
  "armv7l" \
  "missing" \
  "" \
  "missing" \
  ""

assert_target \
  "Linux riscv64 maps to riscv64" \
  "OS=linux ARCH=riscv64" \
  "Linux" \
  "riscv64" \
  "missing" \
  "" \
  "missing" \
  ""

assert_failure \
  "Unsupported architectures still fail" \
  "error: unsupported architecture: mips64"

echo ""
echo "✅ All architecture tests passed!"
