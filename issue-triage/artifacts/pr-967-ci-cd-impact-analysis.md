# PR #967 CI/CD and Container Impact Analysis

**PR:** #967 - Migrate install script to v2 with user-local default install
**Analysis Date:** December 8, 2025
**Analyzer:** Code Agent
**Status:** HIGH RISK for CI/CD users

---

## Executive Summary

PR #967 introduces `install-next.sh` v2.0.0 which fundamentally changes FVM's installation model from **system-wide** (`/usr/local/bin/fvm`) to **user-local** (`~/.fvm_flutter/bin`) by default. While this improves security for individual developers, it creates **significant breaking changes for CI/CD and container workflows**.

### Critical Changes

1. **Install location changed**: `/usr/local/bin/fvm` → `~/.fvm_flutter/bin`
2. **No system symlink**: Removes automatic `/usr/local/bin/fvm` creation
3. **CI/container detection removed**: No longer auto-detects CI environments
4. **Root behavior changed**: From "block unless CI/container" to "warn and continue"
5. **PATH not auto-configured**: Scripts must manually add `~/.fvm_flutter/bin` to PATH

### Risk Assessment

| Category | Risk Level | Impact |
|----------|-----------|--------|
| **GitHub Actions** | 🔴 HIGH | Workflows calling `fvm` after install will fail |
| **Docker/Containers** | 🔴 HIGH | Multi-stage builds and root users affected |
| **GitLab CI** | 🟡 MEDIUM | Needs PATH configuration updates |
| **CircleCI** | 🟡 MEDIUM | Needs PATH configuration updates |
| **Bitrise/Codemagic** | 🟡 MEDIUM | Flutter-specific platforms need testing |

---

## 1. GitHub Actions Compatibility Analysis

### Current State (v1 installer)

**Working pattern:**
```yaml
- name: Install FVM
  run: curl -fsSL https://fvm.app/install.sh | bash

- name: Use FVM
  run: fvm install stable  # ✅ Works (auto-detected as CI)
```

**Why it works:**
- v1 detects `GITHUB_ACTIONS` environment variable
- Auto-creates `/usr/local/bin/fvm` symlink
- No PATH configuration needed
- `fvm` is immediately available

### After PR #967 (v2 installer)

**Breaking scenario:**
```yaml
- name: Install FVM
  run: curl -fsSL https://fvm.app/install.sh | bash

- name: Use FVM
  run: fvm install stable  # ❌ FAILS: command not found
```

**Why it breaks:**
- No CI detection in v2
- No system symlink created
- Binary installed to `~/.fvm_flutter/bin`
- PATH not updated in non-interactive shells
- `which fvm` returns nothing

**Impact:**
- **Severity**: Critical
- **Scope**: All GitHub Actions workflows using FVM
- **User base**: Estimated 100+ public repos, unknown private repos

### Required Migration

**Option 1: Explicit PATH configuration (RECOMMENDED)**
```yaml
- name: Install FVM
  run: curl -fsSL https://fvm.app/install.sh | bash

- name: Add FVM to PATH
  run: echo "$HOME/.fvm_flutter/bin" >> $GITHUB_PATH

- name: Use FVM
  run: fvm install stable  # ✅ Works
```

**Option 2: Use absolute path**
```yaml
- name: Install FVM
  run: curl -fsSL https://fvm.app/install.sh | bash

- name: Use FVM
  run: $HOME/.fvm_flutter/bin/fvm install stable  # ✅ Works but verbose
```

**Option 3: System install flag (if v2 adds it)**
```yaml
- name: Install FVM
  run: curl -fsSL https://fvm.app/install.sh | bash -s -- --system

- name: Use FVM
  run: fvm install stable  # ✅ Works (requires sudo support)
```

### Existing Third-Party Actions

**flutter-actions/setup-fvm** ([source](https://github.com/flutter-actions/setup-fvm))
- Currently uses system install pattern
- Will break with v2 installer
- Needs update to configure PATH

**kuhnroyal/flutter-fvm-config-action** ([source](https://github.com/kuhnroyal/flutter-fvm-config-action))
- Parses `.fvmrc` and configures Flutter action
- May assume system-wide FVM availability
- Needs compatibility testing

---

## 2. Docker/Container Patterns Analysis

### Pattern 1: Root User Dockerfile

**Current working pattern (v1):**
```dockerfile
FROM ubuntu:latest

RUN apt-get update && apt-get install -y curl tar gzip git

# Install FVM as root (auto-detected as container)
RUN curl -fsSL https://fvm.app/install.sh | bash

# Use FVM (works because /usr/local/bin/fvm exists)
RUN fvm install stable
RUN fvm global stable
```

**After v2:**
```dockerfile
FROM ubuntu:latest

RUN apt-get update && apt-get install -y curl tar gzip git

# Install FVM as root
RUN curl -fsSL https://fvm.app/install.sh | bash

# ❌ FAILS: fvm command not found
RUN fvm install stable
```

**Why it breaks:**
- No container detection in v2
- Binary installed to `/root/.fvm_flutter/bin`
- `/usr/local/bin/fvm` not created
- PATH not configured for subsequent RUN commands

**Fix:**
```dockerfile
# Install FVM
RUN curl -fsSL https://fvm.app/install.sh | bash

# Configure PATH for all RUN commands
ENV PATH="/root/.fvm_flutter/bin:$PATH"

# Now works
RUN fvm install stable
```

### Pattern 2: Multi-Stage Build

**Common pattern:**
```dockerfile
# Stage 1: Build environment
FROM dart:stable AS builder

RUN curl -fsSL https://fvm.app/install.sh | bash
RUN fvm install 3.24.0
RUN fvm flutter build apk

# Stage 2: Runtime
FROM alpine:latest
# ❌ FVM not available (different stage)
```

**Impact:**
- Each stage needs separate FVM installation
- PATH must be configured per stage
- Binary not shared across stages

**Fix:**
```dockerfile
# Stage 1
FROM dart:stable AS builder

RUN curl -fsSL https://fvm.app/install.sh | bash
ENV PATH="/root/.fvm_flutter/bin:$PATH"
RUN fvm install 3.24.0
RUN fvm flutter build apk

# Stage 2
FROM alpine:latest
COPY --from=builder /root/.fvm_flutter /root/.fvm_flutter
ENV PATH="/root/.fvm_flutter/bin:$PATH"
```

### Pattern 3: Non-Root Container User

**Current pattern:**
```dockerfile
FROM ubuntu:latest

RUN useradd -m flutter
USER flutter

# Install as non-root user
RUN curl -fsSL https://fvm.app/install.sh | bash

# ✅ This actually works better with v2!
ENV PATH="/home/flutter/.fvm_flutter/bin:$PATH"
RUN fvm install stable
```

**Impact:**
- **POSITIVE**: v2 is actually better for non-root users
- No sudo required
- Cleaner permission model
- Follows container best practices

### Pattern 4: Alpine Linux (musl)

**Current concern:**
```dockerfile
FROM alpine:latest

RUN apk add --no-cache bash curl tar gzip

# Install FVM
RUN curl -fsSL https://fvm.app/install.sh | bash
ENV PATH="/root/.fvm_flutter/bin:$PATH"

# Will v2 detect musl correctly?
RUN fvm install stable
```

**v2 musl detection:**
```bash
# From install-next.sh lines 264-270
if [ "$OS" = "linux" ] && { [ "$ARCH" = "x64" ] || [ "$ARCH" = "arm64" ]; }; then
  if (ldd --version 2>&1 | grep -qi musl) || grep -qi musl /proc/self/maps 2>/dev/null; then
    LIBC_SUFFIX="-musl"
  fi
fi
```

**Status:**
- ✅ Musl detection logic exists
- ✅ Fallback to glibc if musl variant unavailable
- ❌ **NOT TESTED IN CI** (no Alpine test job in workflow)

---

## 3. CI Platform Compatibility Matrix

### GitHub Actions

| Scenario | v1 Status | v2 Status | Migration Effort |
|----------|-----------|-----------|------------------|
| ubuntu-latest (x64) | ✅ Auto-works | ❌ Needs PATH | Low (add `$GITHUB_PATH`) |
| macos-latest (x64/arm64) | ✅ Auto-works | ❌ Needs PATH | Low (add `$GITHUB_PATH`) |
| Container jobs | ✅ Auto-detected | ❌ Needs PATH+ENV | Medium (PATH per job) |
| Self-hosted runners | ✅ Works | ⚠️ Untested | High (varies by setup) |

**Migration example:**
```yaml
# Add this step after FVM install
- name: Configure FVM PATH
  run: echo "$HOME/.fvm_flutter/bin" >> $GITHUB_PATH
```

### GitLab CI

**Current pattern:**
```yaml
before_script:
  - curl -fsSL https://fvm.app/install.sh | bash
  - fvm install  # ❌ Will fail with v2

script:
  - fvm flutter test
```

**v2 migration:**
```yaml
before_script:
  - curl -fsSL https://fvm.app/install.sh | bash
  - export PATH="$HOME/.fvm_flutter/bin:$PATH"
  - fvm install  # ✅ Now works

script:
  - fvm flutter test
```

**Impact:**
- PATH export needed in `before_script`
- Or use absolute path: `$HOME/.fvm_flutter/bin/fvm`
- Docker-based GitLab CI needs container fixes above

### CircleCI

**Current pattern:**
```yaml
jobs:
  build:
    docker:
      - image: circleci/android:api-29
    steps:
      - run: curl -fsSL https://fvm.app/install.sh | bash
      - run: fvm install  # ❌ Will fail
```

**v2 migration:**
```yaml
jobs:
  build:
    docker:
      - image: circleci/android:api-29
    steps:
      - run: curl -fsSL https://fvm.app/install.sh | bash
      - run: echo 'export PATH="$HOME/.fvm_flutter/bin:$PATH"' >> $BASH_ENV
      - run: fvm install  # ✅ Works
```

**CircleCI specific:**
- Use `$BASH_ENV` to persist PATH across steps
- Container-based builds need ENV configuration

### Bitrise

**Common pattern:**
```yaml
workflows:
  primary:
    steps:
    - script:
        title: Install FVM
        inputs:
        - content: curl -fsSL https://fvm.app/install.sh | bash
    - script:
        title: Setup Flutter
        inputs:
        - content: fvm install  # ❌ Will fail
```

**v2 migration:**
```yaml
- script:
    title: Install FVM
    inputs:
    - content: |
        curl -fsSL https://fvm.app/install.sh | bash
        echo "export PATH=\"$HOME/.fvm_flutter/bin:\$PATH\"" >> ~/.bashrc
- script:
    title: Setup Flutter
    inputs:
    - content: |
        source ~/.bashrc
        fvm install  # ✅ Works
```

### Codemagic

**Flutter-specific platform** ([reference](https://blog.codemagic.io/how-to-dockerize-flutter-apps/))

**Current pattern:**
```yaml
scripts:
  - name: Install FVM
    script: curl -fsSL https://fvm.app/install.sh | bash
  - name: Setup
    script: fvm install  # ❌ Will fail
```

**v2 migration:**
```yaml
scripts:
  - name: Install FVM
    script: |
      curl -fsSL https://fvm.app/install.sh | bash
      export PATH="$HOME/.fvm_flutter/bin:$PATH"
  - name: Setup
    script: fvm install  # ✅ Works
```

---

## 4. Specific Breaking Scenarios

### Scenario 1: `which fvm` Scripts

**Common pattern:**
```bash
#!/bin/bash
curl -fsSL https://fvm.app/install.sh | bash

# Verify installation
FVM_PATH=$(which fvm)
if [ -z "$FVM_PATH" ]; then
  echo "FVM install failed"
  exit 1
fi
```

**Impact with v2:**
- `which fvm` returns empty (not in PATH)
- Scripts relying on this will fail
- **Mitigation**: Check `$HOME/.fvm_flutter/bin/fvm` directly

### Scenario 2: Hardcoded `/usr/local/bin/fvm`

**Found in user scripts:**
```bash
# Hardcoded path (will break)
/usr/local/bin/fvm install stable

# Or symlink expectations
ls -la /usr/local/bin/fvm  # File not found
```

**Impact:**
- Scripts with hardcoded paths will fail
- No automatic migration
- **Mitigation**: Update to `$HOME/.fvm_flutter/bin/fvm`

### Scenario 3: Root Without HOME

**Edge case:**
```bash
# Some CI systems don't set HOME for root
unset HOME
curl -fsSL https://fvm.app/install.sh | bash
# Where does FVM install? /root/.fvm_flutter or error?
```

**v2 behavior:**
```bash
# From install-next.sh:
INSTALL_BASE="${HOME}/.fvm_flutter"
# Will fail if HOME is unset
```

**Impact:**
- Broken in environments without HOME
- **Mitigation**: Ensure HOME is set, or v2 needs fallback

### Scenario 4: Non-Interactive Shell

**Pattern:**
```bash
ssh user@server 'curl -fsSL https://fvm.app/install.sh | bash && fvm --version'
```

**Impact with v2:**
- PATH updates go to `~/.bashrc`
- Non-interactive shells don't source `~/.bashrc`
- `fvm --version` will fail
- **Mitigation**: Use absolute path or `bash -l -c`

### Scenario 5: Migration Race Condition

**Scenario:**
```bash
# Old v1 install exists at /usr/local/bin/fvm
curl -fsSL https://fvm.app/install.sh | bash

# During migration, if cleanup fails:
# - Old symlink at /usr/local/bin/fvm (may be broken)
# - New binary at ~/.fvm_flutter/bin/fvm
# - Which one does `which fvm` find?
```

**Impact:**
- Partial migration state
- Unpredictable `which fvm` results
- **Mitigation**: v2 attempts cleanup, but may fail silently (see rm -f bug)

---

## 5. Migration Path Analysis

### Smooth Migration (Best Case)

**User with clean system:**
```bash
# No existing FVM
curl -fsSL https://fvm.app/install-next.sh | bash
# ✅ Clean install to ~/.fvm_flutter/bin
```

**Result:** Works perfectly, no issues

### Partial Migration (Common Case)

**User with v1 system install:**
```bash
# v1 symlink exists: /usr/local/bin/fvm -> ~/.fvm_flutter/bin/fvm
curl -fsSL https://fvm.app/install-next.sh | bash

# v2 behavior:
# 1. Detects old symlink
# 2. Installs to ~/.fvm_flutter/bin
# 3. Attempts to remove /usr/local/bin/fvm (may fail without sudo)
```

**Possible outcomes:**
1. **Success with sudo**: Old symlink removed, clean state
2. **Partial (no sudo)**: Old symlink remains, message printed
3. **Silent fail**: Bug in rm -f logic (see code review notes)

### Breaking Migration (Worst Case)

**CI pipeline with cached environment:**
```yaml
# CI cache includes:
# - Old FVM at /usr/local/bin/fvm
# - Old Flutter SDKs in ~/.fvm/versions

steps:
  - restore_cache: fvm-install
  - run: curl -fsSL https://fvm.app/install.sh | bash  # Gets v2!
  - run: fvm install stable  # ❌ FAILS (PATH not configured)
```

**Result:**
- Cache invalidation needed
- Pipeline broken until updated
- Difficult to diagnose (silently gets new installer)

---

## 6. Root Behavior Analysis

### v1 Behavior (Current)

```bash
# From current install.sh:
if [[ $(id -u) -eq 0 ]]; then
  if is_container_env || [[ "${FVM_ALLOW_ROOT:-}" == "true" ]]; then
    info "Root execution allowed (container/CI/override detected)"
  else
    error "This script should not be run as root."
  fi
fi
```

**Logic:**
- **BLOCKS** root execution by default
- **ALLOWS** if container detected (/.dockerenv, CI env vars)
- **ALLOWS** if FVM_ALLOW_ROOT=true

### v2 Behavior (install-next.sh)

```bash
# From install-next.sh lines 193-207:
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
```

**Logic:**
- Same blocking behavior
- **BUT**: `is_ci_or_container()` checks 10+ CI/container signals
- Still exits with error if root and not allowed

### Key Difference

**v1 CI detection:**
```bash
is_container_env() {
  [[ -f /.dockerenv ]] || [[ -f /.containerenv ]] || [[ -n "${CI:-}" ]]
}
```

**v2 CI detection:**
```bash
is_ci_or_container() {
  # CI signals (10+ platforms)
  [ -n "${CI:-}" ] && return 0
  [ -n "${GITHUB_ACTIONS:-}" ] && return 0
  [ -n "${GITLAB_CI:-}" ] && return 0
  # ... 7+ more ...

  # Container signals
  [ -f "/.dockerenv" ] && return 0
  [ -f "/run/.containerenv" ] && return 0
  if grep -Eiq '(docker|containerd|kubepods|podman)' /proc/1/cgroup 2>/dev/null; then
    return 0
  fi
  return 1
}
```

**Impact:**
- v2 is **MORE PERMISSIVE** (detects more CI systems)
- Better support for Azure Pipelines, AWS CodeBuild, Drone, etc.
- **NOT A BREAKING CHANGE** (expands compatibility)

---

## 7. Test Coverage Gaps

### Current CI Tests (test-install.yml)

**What's tested:**
```yaml
test-install:
  runs-on: [ubuntu-latest, macos-latest]
  steps:
    - run: ./scripts/install.sh
    - run: fvm --version  # ✅ Tests binary works

test-container:
  container: ubuntu:latest
  steps:
    - run: ./scripts/install.sh
    - run: /usr/local/bin/fvm --version  # ✅ Tests system path
```

**What's NOT tested in v2:**
1. ❌ PATH-based `fvm` resolution (only absolute path)
2. ❌ Alpine Linux / musl detection
3. ❌ Non-interactive shell behavior
4. ❌ Migration from v1 to v2
5. ❌ Specific version installation
6. ❌ arm64 architecture (only x64)

### Recommended Additional Tests

**1. PATH Resolution Test**
```yaml
- name: Test PATH resolution
  run: |
    ./scripts/install-next.sh
    export PATH="$HOME/.fvm_flutter/bin:$PATH"
    which fvm  # Should succeed
    fvm --version  # Should work without absolute path
```

**2. GitHub Actions Integration Test**
```yaml
- name: Test GitHub Actions PATH
  run: |
    ./scripts/install-next.sh
    echo "$HOME/.fvm_flutter/bin" >> $GITHUB_PATH

    # New step to verify PATH persists
- name: Verify FVM in PATH
  run: |
    which fvm
    fvm --version
```

**3. Alpine/musl Test**
```yaml
test-alpine:
  container: alpine:latest
  steps:
    - run: apk add --no-cache bash curl tar gzip
    - run: ./scripts/install-next.sh
    - run: $HOME/.fvm_flutter/bin/fvm --version
```

**4. Migration Test**
```yaml
test-migration:
  steps:
    # Simulate v1 install
    - run: |
        sudo mkdir -p /usr/local/bin
        echo '#!/bin/bash' | sudo tee /usr/local/bin/fvm
        sudo chmod +x /usr/local/bin/fvm

    # Install v2
    - run: ./scripts/install-next.sh

    # Verify migration
    - run: |
        test -f ~/.fvm_flutter/bin/fvm || exit 1
        ! test -f /usr/local/bin/fvm || echo "WARNING: Old install remains"
```

---

## 8. Mitigation Strategies

### For FVM Maintainers

**Option 1: Gradual Rollout (RECOMMENDED)**
```bash
# Keep install.sh as v1 (stable)
# Release install-next.sh as v2 (opt-in)
# Document migration path
# After 3-6 months, promote v2 to install.sh
```

**Benefits:**
- No immediate breakage
- Users can test and migrate at their own pace
- Feedback loop before full deployment

**Option 2: Feature Flag**
```bash
# Add to v2:
INSTALL_MODE="${FVM_INSTALL_MODE:-user}"  # user or system

if [ "$INSTALL_MODE" = "system" ]; then
  # Use old v1 behavior
  BIN_DIR="/usr/local/bin"
else
  # Use new v2 behavior
  BIN_DIR="$HOME/.fvm_flutter/bin"
fi
```

**Benefits:**
- Single installer with backward compatibility
- Environment variable controls behavior
- Easier for CI systems to override

**Option 3: Auto-Detect CI and Use System Install**
```bash
# In v2, add:
if is_ci_or_container && [ "$SYSTEM_INSTALL" -eq 0 ]; then
  echo "CI/container detected, using system install for compatibility"
  SYSTEM_INSTALL=1
fi
```

**Benefits:**
- Zero breaking changes for CI users
- Maintains v2 benefits for developers
- Could be overridden with --user flag

### For FVM Users

**Immediate Actions:**
1. **Pin installer version** in CI:
   ```bash
   # Pin to v1 during transition
   curl -fsSL https://fvm.app/install-legacy.sh | bash
   ```

2. **Add PATH configuration** to all CI workflows:
   ```yaml
   # GitHub Actions
   - run: echo "$HOME/.fvm_flutter/bin" >> $GITHUB_PATH

   # GitLab CI / CircleCI
   - run: export PATH="$HOME/.fvm_flutter/bin:$PATH"
   ```

3. **Test v2 in non-critical environments** first:
   ```bash
   curl -fsSL https://fvm.app/install-next.sh | bash
   ```

**Long-term Migration:**
1. Update all documentation to use PATH configuration
2. Update container images to set ENV PATH
3. Update third-party actions to support v2
4. Add health checks to CI to verify FVM availability

---

## 9. Documentation Gaps

### Missing Documentation

**1. Migration Guide**
- No guide for v1 → v2 transition
- No warning about breaking changes
- No CI-specific migration instructions

**Recommendation:** Create `docs/migration-v2.md` with:
- Breaking changes summary
- Platform-specific migration steps
- Rollback instructions
- FAQ for common issues

**2. CI/CD Guide**
- Current docs don't cover CI usage patterns
- No examples for major platforms

**Recommendation:** Create `docs/ci-cd-setup.md` with:
- GitHub Actions example
- GitLab CI example
- CircleCI example
- Docker/container patterns
- Troubleshooting section

**3. Troubleshooting Section**
- No guide for "command not found" errors
- No PATH configuration help

**Recommendation:** Add to existing docs:
```markdown
## Troubleshooting

### FVM not found after installation

**Problem:** `bash: fvm: command not found`

**Solution:** Add FVM to your PATH:
```bash
export PATH="$HOME/.fvm_flutter/bin:$PATH"
```

Add this line to your shell config and restart your shell.
```

---

## 10. Recommendations

### Critical (Must Address Before Merge)

1. **Add CI PATH tests** to verify `fvm` command works without absolute path
2. **Document breaking changes** prominently in PR description
3. **Create migration guide** for CI/CD users
4. **Fix rm -f bug** in migration logic (false success messages)
5. **Add Alpine Linux test** to verify musl detection

### High Priority (Should Address)

1. **Consider gradual rollout** (keep v1 as install.sh, v2 as install-next.sh)
2. **Add feature flag** for backward compatibility (FVM_INSTALL_MODE=system)
3. **Update third-party actions** or coordinate with maintainers
4. **Add migration test** to CI (v1 → v2 upgrade scenario)
5. **Document CI-specific migration** for each major platform

### Medium Priority (Nice to Have)

1. Add arm64 test on GitHub Actions macOS M1 runners
2. Add non-interactive shell test
3. Add HOME unset edge case handling
4. Create video tutorial for CI migration
5. Add health check command: `fvm doctor --check-install`

### Low Priority (Future Enhancements)

1. Add `fvm self-update` command to manage installer updates
2. Create pre-flight check in installer to warn about breaking changes
3. Add telemetry to track installer version usage
4. Create automated migration tool: `fvm migrate-to-v2`

---

## 11. Conclusion

PR #967's install-next.sh represents a **significant architectural improvement** for individual developers (no sudo, better security, follows modern patterns). However, it introduces **high-risk breaking changes for CI/CD and container users**.

### Key Takeaways

1. **Breaking Change Scope**: Affects all CI/CD pipelines using FVM
2. **Migration Effort**: Low-to-medium per platform (add PATH configuration)
3. **Risk Mitigation**: Gradual rollout and comprehensive documentation essential
4. **User Impact**: Estimated hundreds to thousands of workflows globally
5. **Test Coverage**: Insufficient for v2 installer, needs CI-specific tests

### Recommended Path Forward

1. **DO NOT** replace `install.sh` immediately
2. **DO** release as `install-next.sh` for opt-in testing
3. **DO** create comprehensive migration documentation
4. **DO** add CI integration tests
5. **DO** coordinate with third-party action maintainers
6. **DO** collect feedback for 3-6 months before promoting to default

With proper planning and documentation, this migration can be successful. Without it, it risks breaking thousands of CI/CD pipelines globally.

---

## References

- PR #967: https://github.com/leoafarias/fvm/pull/967
- Current install.sh: `/Users/leofarias/Projects/fvm/scripts/install.sh`
- Proposed install-next.sh: PR #967 diff
- GitHub Actions setup-fvm: https://github.com/flutter-actions/setup-fvm
- flutter-fvm-config-action: https://github.com/kuhnroyal/flutter-fvm-config-action
- FVM Installation Docs: https://fvm.app/documentation/getting-started/installation
- Docker with FVM: https://blog.codemagic.io/how-to-dockerize-flutter-apps/

---

**Analysis completed:** December 8, 2025
**Next review:** After PR author addresses critical recommendations
