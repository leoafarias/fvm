# FVM Install Script Profile/PATH Handling Plan

Based on verified analysis of NVM (v0.40.1), Homebrew, and Bun installation scripts.

## Executive Summary

The current FVM install script is **well-designed** and follows industry best practices. It aligns closely with Homebrew's philosophy (show instructions, do not auto-modify) while providing superior CI environment handling.

**Recommendation: Keep the current approach with minor enhancements.**

---

## 1. Comparative Analysis

### 1.1 Shell Detection

| Feature | NVM | Homebrew | Bun | FVM Current | Assessment |
|---------|-----|----------|-----|-------------|------------|
| Detection method | `${SHELL#*bash}` pattern | `case "${SHELL}"` | `basename "$SHELL"` | `ps -p $PPID` + `$SHELL` fallback | **FVM is best** |
| Login shell handling | Strips leading dash | N/A | N/A | `${shell_name##-}` | **Good** |
| Fallback mechanism | $SHELL env var | N/A | N/A | $SHELL env var | **Good** |

**Assessment: FVM's shell detection is the most robust.** Using `ps -p $PPID` detects the actual running shell, not just the default.

### 1.2 Profile File Priority

| Shell | NVM | Homebrew | FVM Current | Correct Per Docs |
|-------|-----|----------|-------------|------------------|
| **Bash (Linux)** | .bashrc first | .bashrc | .bash_profile > .bashrc | .bashrc for Linux |
| **Bash (macOS)** | .bashrc first | .bash_profile | .bash_profile > .bashrc | .bash_profile for macOS |
| **Zsh** | .zshrc first | Platform-dependent | .zprofile > .zshrc | Platform-dependent |
| **Fish** | N/A | .config/fish/config.fish | XDG_CONFIG_HOME respect | **Good** |

**Minor Gap**: FVM does not differentiate Linux vs macOS for bash profile priority.

### 1.3 Duplicate Detection

| Tool | Method | Robustness |
|------|--------|------------|
| NVM | `grep -qc '/nvm.sh'` | Medium |
| Homebrew | `grep -qs "eval.*brew shellenv"` | Medium |
| Bun | **None** | **Bad** |
| FVM | `grep -v '^\s*#' \| grep -qF` + regex variants | **Excellent** |

**Assessment: FVM has the most robust duplicate detection.**

### 1.4 CI Environment Handling

| CI System | NVM | Homebrew | Bun | FVM |
|-----------|-----|----------|-----|-----|
| GitHub Actions (GITHUB_PATH) | No | No | No | **Yes** |
| CircleCI (BASH_ENV) | No | No | No | **Yes** |
| Azure DevOps (##vso) | No | No | No | **Yes** |
| GitLab/Travis/Jenkins | No | No | No | **Yes** |

**Assessment: FVM has unique, comprehensive CI support** that no other tool provides.

### 1.5 Auto-Modify vs Instructions-Only

| Tool | Default Behavior | User Override |
|------|------------------|---------------|
| NVM | **Auto-modifies** | `PROFILE='/dev/null'` to skip |
| Homebrew | **Instructions only** | N/A |
| Bun | **Auto-modifies** | No skip option |
| FVM | **Instructions only** | N/A |

**Assessment: FVM follows the safer Homebrew pattern.**

---

## 2. Verified Code Patterns

### NVM Profile Detection (verified from v0.40.1)
```bash
nvm_detect_profile() {
  # Respects PROFILE env var override
  if [ "${PROFILE-}" = '/dev/null' ]; then
    return
  fi

  if [ -n "${PROFILE}" ] && [ -f "${PROFILE}" ]; then
    nvm_echo "${PROFILE}"
    return
  fi

  # Shell detection via pattern matching
  if [ "${SHELL#*bash}" != "$SHELL" ]; then
    if [ -f "$HOME/.bashrc" ]; then
      DETECTED_PROFILE="$HOME/.bashrc"
    elif [ -f "$HOME/.bash_profile" ]; then
      DETECTED_PROFILE="$HOME/.bash_profile"
    fi
  elif [ "${SHELL#*zsh}" != "$SHELL" ]; then
    if [ -f "$HOME/.zshrc" ]; then
      DETECTED_PROFILE="$HOME/.zshrc"
    fi
  fi

  # Fallback iteration
  for EACH_PROFILE in ".profile" ".bashrc" ".bash_profile" ".zprofile" ".zshrc"; do
    if [ -f "${HOME}/${EACH_PROFILE}" ]; then
      break
    fi
  done
}
```

### Homebrew Shell Detection (verified)
```bash
case "${SHELL}" in
  */bash*)
    if [[ -n "${HOMEBREW_ON_LINUX-}" ]]; then
      shell_rcfile="${HOME}/.bashrc"
    else
      shell_rcfile="${HOME}/.bash_profile"
    fi
    ;;
  */zsh*)
    if [[ -n "${HOMEBREW_ON_LINUX-}" ]]; then
      shell_rcfile="${ZDOTDIR:-"${HOME}"}/.zshrc"
    else
      shell_rcfile="${ZDOTDIR:-"${HOME}"}/.zprofile"
    fi
    ;;
  */fish*)
    shell_rcfile="${HOME}/.config/fish/config.fish"
    ;;
  *)
    shell_rcfile="${ENV:-"${HOME}/.profile"}"
    ;;
esac
```

---

## 3. Recommended Changes

### 3.1 Add PROFILE Environment Variable Support (Medium Priority)

Allow users to override profile detection:
- `PROFILE=~/.zshrc ./install.sh` - Use specific file
- `PROFILE=/dev/null ./install.sh` - Skip profile detection entirely

```bash
get_profile_file() {
  local shell_type="$1"

  # Allow explicit override via PROFILE environment variable
  if [ -n "${PROFILE:-}" ]; then
    if [ "${PROFILE}" = "/dev/null" ]; then
      echo ""
      return
    fi
    if [ -f "${PROFILE}" ]; then
      echo "${PROFILE}"
      return
    fi
  fi

  # ... existing auto-detection logic
}
```

### 3.2 Platform-Aware Bash Profile Priority (Low Priority)

Optionally differentiate Linux vs macOS:
- **macOS**: `.bash_profile` first (Terminal.app opens login shells)
- **Linux**: `.bashrc` first (terminals open non-login interactive shells)

```bash
bash)
  if [ "$(uname -s)" = "Darwin" ]; then
    # macOS: .bash_profile > .bashrc
  else
    # Linux: .bashrc > .bash_profile
  fi
  ;;
```

### 3.3 Expand Unknown Shell Fallback (Very Low Priority)

```bash
*)
  for profile in ".profile" ".bashrc" ".bash_profile" ".zprofile" ".zshrc"; do
    if [ -f "$HOME/$profile" ]; then
      profile_file="$HOME/$profile"
      break
    fi
  done
  ;;
```

---

## 4. What NOT to Change

Preserve these current behaviors:

1. **Do not auto-modify profiles by default** - Safer approach
2. **Keep `ps -p $PPID` as primary detection** - More accurate than `$SHELL` alone
3. **Keep `grep -qF` for duplicate detection** - Prevents regex injection
4. **Keep CI auto-setup behavior** - Unique value-add
5. **Keep XDG_CONFIG_HOME respect for fish** - Follows XDG spec
6. **Keep comment-line filtering** - Prevents false positives

---

## 5. Implementation Priority

| Change | Priority | Effort | Impact |
|--------|----------|--------|--------|
| Add PROFILE env var support | Medium | Low | NVM compatibility |
| Platform-aware bash priority | Low | Medium | Marginal improvement |
| Expand unknown shell fallback | Very Low | Very Low | Edge case coverage |

---

## 6. Conclusion

The current FVM install script combines the best of:
- **Homebrew**: Safe, non-invasive (show instructions only)
- **NVM**: Robust shell detection and profile handling
- **Unique**: Comprehensive CI auto-configuration

Only the `PROFILE` environment variable support is recommended as a meaningful improvement.
