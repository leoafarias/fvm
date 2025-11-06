#!/usr/bin/env bash
# Install or uninstall FVM from GitHub releases.
# - Default: user install to $HOME/.fvm_flutter/bin and PATH update
# - Optional: --system to copy to /usr/local/bin/fvm (needs sudo/doas)
# - Optional: VERSION arg (x.y.z or vx.y.z). Default = latest via redirect.
# - Root blocked unless running in CI/container or FVM_ALLOW_ROOT=true
# - Uninstall: --uninstall removes user install and /usr/local/bin/fvm if present
set -Eeuo pipefail
umask 022

# ---- installer metadata ----
INSTALLER_NAME="install_fvm.sh"
INSTALLER_VERSION="2.0.0"  # v2: user install by default, system install requires --system

# ---- config ----
REPO="leoafarias/fvm"
INSTALL_BASE="${HOME}/.fvm_flutter"
BIN_DIR="${INSTALL_BASE}/bin"
TMP_DIR="${INSTALL_BASE}/temp_extract"
SYSTEM_DEST="/usr/local/bin/fvm"

SYSTEM_INSTALL=0
MODIFY_PATH=1
UNINSTALL_ONLY=0
REQUESTED_VERSION=""

# ---- helpers ----
usage() {
  cat <<'EOF'
Usage:
  install_fvm.sh [FLAGS] [VERSION]

Arguments:
  VERSION               Version to install, e.g. 4.0.1 or v4.0.1.
                        If omitted, the latest GitHub release is used.

Flags:
  --system              Copy binary to /usr/local/bin/fvm (requires sudo/doas).
  --no-modify-path      Do not edit shell config files (bash/zsh/fish).
  --uninstall           Remove FVM (user dir and /usr/local/bin/fvm if present).
  -h, --help            Show this help and exit.
  -v, --version         Show installer script version and exit.

Environment:
  FVM_ALLOW_ROOT=true   Allow running as root even outside CI/containers.

Examples:
  # Install latest to user dir and update PATH
  bash install_fvm.sh

  # Install a specific version
  bash install_fvm.sh 4.0.1

  # System-wide copy (no symlinks)
  bash install_fvm.sh --system 4.0.1

  # Uninstall (idempotent)
  bash install_fvm.sh --uninstall
EOF
}

print_installer_version() {
  printf '%s version %s\n' "$INSTALLER_NAME" "$INSTALLER_VERSION"
}

require() { command -v "$1" >/dev/null 2>&1 || { echo "error: $1 is required" >&2; exit 1; }; }

is_ci_or_container() {
  # CI signals
  [ -n "${CI:-}" ] && return 0
  [ -n "${GITHUB_ACTIONS:-}" ] && return 0
  [ -n "${GITLAB_CI:-}" ] && return 0
  [ -n "${BUILDKITE:-}" ] && return 0
  [ -n "${CIRCLECI:-}" ] && return 0
  [ -n "${TRAVIS:-}" ] && return 0
  [ -n "${APPVEYOR:-}" ] && return 0
  [ -n "${JENKINS_URL:-}" ] && return 0
  [ -n "${DRONE:-}" ] && return 0
  [ -n "${TF_BUILD:-}" ] && return 0           # Azure Pipelines
  [ -n "${CODEBUILD_BUILD_ARN:-}" ] && return 0 # AWS CodeBuild

  # Container signals
  [ -f "/.dockerenv" ] && return 0             # Docker
  [ -f "/run/.containerenv" ] && return 0      # Podman
  if grep -Eiq '(docker|containerd|kubepods|podman)' /proc/1/cgroup 2>/dev/null; then
    return 0
  fi
  return 1
}

normalize_version() { printf '%s\n' "$1" | sed -E 's/^v//'; }

get_latest_version() {
  # Follows redirect from /releases/latest -> .../tag/vX.Y.Z
  local url
  url="$(curl -fsSLI -o /dev/null -w '%{url_effective}' "https://github.com/${REPO}/releases/latest")" || return 1
  normalize_version "${url##*/}"
}

choose_elev() {
  if [ "${EUID:-$(id -u)}" -ne 0 ]; then
    if command -v sudo >/dev/null 2>&1; then echo "sudo"
    elif command -v doas >/dev/null 2>&1; then echo "doas"
    else echo ""
    fi
  else
    echo ""
  fi
}

add_line_if_missing() {
  # $1=file, $2=marker for grep, $3=line to append
  local f="$1" marker="$2" line="$3"
  if [ -f "$f" ] && ! [ -w "$f" ]; then
    echo "note: $f not writable. Add PATH manually: $line" >&2
    return 0
  fi
  mkdir -p "$(dirname "$f")"
  touch "$f" 2>/dev/null || { echo "note: cannot create $f. Add PATH manually: $line" >&2; return 0; }
  if ! grep -Fq "$marker" "$f"; then
    printf '\n%s\n' "$line" >> "$f"
    echo "Updated: $f"
  fi
}

notify_rc_files_may_remain() {
  echo "note: PATH lines may remain in shell config files:"
  [ -f "${HOME}/.bashrc" ]        && echo " - ${HOME}/.bashrc"
  [ -f "${HOME}/.bash_profile" ]  && echo " - ${HOME}/.bash_profile"
  [ -f "${HOME}/.zshrc" ]         && echo " - ${HOME}/.zshrc"
  [ -f "${HOME}/.config/fish/config.fish" ] && echo " - ${HOME}/.config/fish/config.fish"
  echo "      Remove lines referencing '\$HOME/.fvm_flutter/bin' if desired."
}

do_uninstall() {
  local removed_user=0 removed_system=0

  # Remove user installation directory
  if [ -d "$INSTALL_BASE" ]; then
    rm -rf "$INSTALL_BASE"
    removed_user=1
    echo "Removed user dir: $INSTALL_BASE"
  else
    echo "User dir not found: $INSTALL_BASE (ok)"
  fi

  # Remove system-wide binary (handles both symlink and regular file)
  if [ -L "$SYSTEM_DEST" ] || [ -f "$SYSTEM_DEST" ]; then
    if rm -f "$SYSTEM_DEST" 2>/dev/null; then
      removed_system=1
      echo "Removed system binary: $SYSTEM_DEST"
    else
      local ELEV; ELEV="$(choose_elev)"
      if [ -n "$ELEV" ]; then
        $ELEV rm -f "$SYSTEM_DEST"
        removed_system=1
        echo "Removed system binary with elevation: $SYSTEM_DEST"
      else
        echo "note: could not remove $SYSTEM_DEST (need sudo or doas)"
      fi
    fi
  else
    echo "System binary not found: $SYSTEM_DEST (ok)"
  fi

  # Also remove legacy user symlink if it exists (defensive)
  if [ -L "${HOME}/.local/bin/fvm" ] || [ -f "${HOME}/.local/bin/fvm" ]; then
    rm -f "${HOME}/.local/bin/fvm" || true
    echo "Removed legacy: ${HOME}/.local/bin/fvm"
  fi

  notify_rc_files_may_remain

  echo "Uninstall complete."
  # Exit success even if nothing was removed to remain idempotent.
  exit 0
}

# ---- arg parsing ----
for arg in "$@"; do
  case "$arg" in
    -h|--help) usage; exit 0 ;;
    -v|--version) print_installer_version; exit 0 ;;
    --system) SYSTEM_INSTALL=1 ;;
    --no-modify-path) MODIFY_PATH=0 ;;
    --uninstall) UNINSTALL_ONLY=1 ;;
    v[0-9]*|[0-9]*.[0-9]*.[0-9]*) REQUESTED_VERSION="$arg" ;;
    *)
      echo "error: unknown argument: $arg" >&2
      usage
      exit 1
      ;;
  esac
done

# ---- preflight root policy ----
ALLOW_ROOT=0
if is_ci_or_container; then
  ALLOW_ROOT=1
fi
if [ "${FVM_ALLOW_ROOT:-}" = "true" ]; then
  ALLOW_ROOT=1
fi

if [ "${EUID:-$(id -u)}" -eq 0 ] && [ "$ALLOW_ROOT" -ne 1 ]; then
  echo "error: refusing to run as root. Allowed in CI/containers or set FVM_ALLOW_ROOT=true." >&2
  exit 1
fi
if [ "${EUID:-$(id -u)}" -eq 0 ] && [ "$ALLOW_ROOT" -eq 1 ]; then
  echo "note: running as root permitted due to CI/container context or override."
fi

# ---- migration compatibility: detect v1 installation ----
# Check if user has existing system install (from v1 installer or old v2 usage)
LEGACY_SYSTEM_SYMLINK=0
if [ -L "$SYSTEM_DEST" ] || [ -f "$SYSTEM_DEST" ]; then
  LEGACY_SYSTEM_SYMLINK=1
  # Only warn if user didn't explicitly request system install
  if [ "$SYSTEM_INSTALL" -eq 0 ] && [ "$UNINSTALL_ONLY" -eq 0 ]; then
    # Check if this is a symlink pointing to user bin (old v1 behavior)
    if [ -L "$SYSTEM_DEST" ] && [ "$(readlink "$SYSTEM_DEST" 2>/dev/null || true)" = "${BIN_DIR}/fvm" ]; then
      echo "note: detected existing system symlink from previous installer"
      echo "      Installer v2 defaults to user-only install."
      echo "      Your old system symlink will be removed (no longer needed)."
      echo ""
    elif [ ! -t 0 ]; then
      # Non-interactive (piped), just log
      echo "note: detected existing $SYSTEM_DEST"
      echo "      Installing to user directory by default. Use --system for system-wide install."
    else
      # Interactive mode - ask user
      echo "note: detected existing $SYSTEM_DEST"
      echo "      Installer v2 defaults to user-only install (no sudo needed)."
      echo ""
      printf "      Continue with user install? [Y/n]: "
      read -r response
      case "$response" in
        [Nn]*)
          echo "Installation cancelled. To do system install, run with --system flag."
          exit 0
          ;;
      esac
    fi
  fi
fi

# ---- uninstall path ----
if [ "$UNINSTALL_ONLY" -eq 1 ]; then
  do_uninstall
fi

# ---- prereqs ----
require curl
require tar
[ -n "${BASH_VERSION:-}" ] || { echo "error: bash is required to run this installer" >&2; exit 1; }

# ---- detect OS ----
case "$(uname -s)" in
  Linux)  OS="linux" ;;
  Darwin) OS="macos" ;;
  *) echo "error: unsupported OS: $(uname -s)" >&2; exit 1 ;;
esac

# ---- detect ARCH ----
case "$(uname -m)" in
  x86_64|amd64)                   ARCH="x64" ;;
  aarch64|arm64)                  ARCH="arm64" ;;
  armv7l|armv7|armv6l|armv6|armhf) ARCH="arm" ;;
  riscv64)                        ARCH="riscv64" ;;
  *) echo "error: unsupported architecture: $(uname -m)" >&2; exit 1 ;;
esac

# ---- detect libc (Linux only), musl suffix only for x64/arm64 ----
LIBC_SUFFIX=""
if [ "$OS" = "linux" ] && { [ "$ARCH" = "x64" ] || [ "$ARCH" = "arm64" ]; }; then
  if (ldd --version 2>&1 | grep -qi musl) || grep -qi musl /proc/self/maps 2>/dev/null; then
    LIBC_SUFFIX="-musl"
  fi
fi

# ---- resolve version ----
if [ -n "$REQUESTED_VERSION" ]; then
  VERSION="$(normalize_version "$REQUESTED_VERSION")"
else
  VERSION="$(get_latest_version)" || { echo "error: failed to determine latest version" >&2; exit 1; }
fi

# ---- construct asset URL and validate existence, with musl->glibc fallback ----
TARBALL="fvm-${VERSION}-${OS}-${ARCH}${LIBC_SUFFIX}.tar.gz"
URL="https://github.com/${REPO}/releases/download/${VERSION}/${TARBALL}"

if ! curl -fsSLI -o /dev/null "$URL"; then
  if [ -n "$LIBC_SUFFIX" ]; then
    ALT_URL="https://github.com/${REPO}/releases/download/${VERSION}/fvm-${VERSION}-${OS}-${ARCH}.tar.gz"
    if curl -fsSLI -o /dev/null "$ALT_URL"; then
      URL="$ALT_URL"
      TARBALL="fvm-${VERSION}-${OS}-${ARCH}.tar.gz"
    else
      echo "error: no asset found for ${OS}/${ARCH} (tried musl and glibc variants)" >&2
      exit 1
    fi
  else
    echo "error: asset not found: $URL" >&2
    exit 1
  fi
fi

# ---- prep dirs and cleanup trap ----
mkdir -p "$BIN_DIR" "$TMP_DIR"
cleanup() { rm -rf "$TMP_DIR" 2>/dev/null || true; }
trap cleanup EXIT

# ---- download ----
ARCHIVE="${TMP_DIR}/${TARBALL}"
echo "Downloading ${URL}"
curl -fsSL "$URL" -o "$ARCHIVE"

# ---- validate archive ----
if ! tar -tzf "$ARCHIVE" >/dev/null 2>&1; then
  echo "error: downloaded archive appears corrupted: $ARCHIVE" >&2
  exit 1
fi

# ---- extract ----
tar -xzf "$ARCHIVE" -C "$TMP_DIR"

# ---- locate binary and copy contents per tarball structure ----
if [ -d "${TMP_DIR}/fvm" ] && [ -f "${TMP_DIR}/fvm/fvm" ]; then
  cp -a "${TMP_DIR}/fvm/." "$BIN_DIR/"
elif [ -f "${TMP_DIR}/fvm" ]; then
  cp -a "${TMP_DIR}/fvm" "${BIN_DIR}/fvm"
else
  FOUND="$(find "$TMP_DIR" -type f -name 'fvm' 2>/dev/null | head -n1 || true)"
  [ -n "$FOUND" ] || { echo "error: fvm binary not found in archive" >&2; exit 1; }
  cp -a "$FOUND" "${BIN_DIR}/fvm"
fi
chmod +x "${BIN_DIR}/fvm"

# ---- optional system-wide copy ----
if [ "$SYSTEM_INSTALL" -eq 1 ]; then
  if [ "${EUID:-$(id -u)}" -ne 0 ]; then
    if command -v sudo >/dev/null 2>&1; then ELEV="sudo"
    elif command -v doas >/dev/null 2>&1; then ELEV="doas"
    else echo "error: need sudo or doas for --system" >&2; exit 1
    fi
  else
    ELEV=""
  fi
  ${ELEV:-} install -m 0755 "${BIN_DIR}/fvm" "$SYSTEM_DEST"
  echo "System install: ${SYSTEM_DEST}"
else
  # User install: clean up old system symlink if it points to user bin
  if [ "$LEGACY_SYSTEM_SYMLINK" -eq 1 ] && [ -L "$SYSTEM_DEST" ]; then
    if [ "$(readlink "$SYSTEM_DEST" 2>/dev/null || true)" = "${BIN_DIR}/fvm" ]; then
      echo "Cleaning up old system symlink..."
      if rm -f "$SYSTEM_DEST" 2>/dev/null; then
        echo "Removed old system symlink: $SYSTEM_DEST"
      else
        local ELEV; ELEV="$(choose_elev)"
        if [ -n "$ELEV" ]; then
          $ELEV rm -f "$SYSTEM_DEST" 2>/dev/null || true
          echo "Removed old system symlink: $SYSTEM_DEST"
        else
          echo "note: could not remove old symlink $SYSTEM_DEST (requires sudo)"
          echo "      You may remove it manually: sudo rm $SYSTEM_DEST"
        fi
      fi
    fi
  fi
fi

# ---- PATH integration (user shells) ----
if [ "$MODIFY_PATH" -eq 1 ]; then
  add_line_if_missing "${HOME}/.bashrc"        '$HOME/.fvm_flutter/bin' 'export PATH="$HOME/.fvm_flutter/bin:$PATH"'
  # macOS users may rely on .bash_profile
  if [ "$OS" = "macos" ] && [ -f "${HOME}/.bash_profile" ]; then
    add_line_if_missing "${HOME}/.bash_profile" '$HOME/.fvm_flutter/bin' 'export PATH="$HOME/.fvm_flutter/bin:$PATH"'
  fi
  add_line_if_missing "${HOME}/.zshrc"         '$HOME/.fvm_flutter/bin' 'export PATH="$HOME/.fvm_flutter/bin:$PATH"'
  if command -v fish >/dev/null 2>&1; then
    add_line_if_missing "${HOME}/.config/fish/config.fish" 'fish_add_path "$HOME/.fvm_flutter/bin"' 'if type -q fish_add_path; fish_add_path "$HOME/.fvm_flutter/bin"; else; set -gx PATH "$HOME/.fvm_flutter/bin" $PATH; end'
  fi
fi

# ---- verify run (non-fatal) ----
if ! "${BIN_DIR}/fvm" --version >/dev/null 2>&1; then
  echo "note: installed, but running '${BIN_DIR}/fvm --version' failed. Ensure system libs are present." >&2
fi

echo "Installed to: ${BIN_DIR}/fvm"
echo "FVM version: ${VERSION}"
print_installer_version
echo "Done."