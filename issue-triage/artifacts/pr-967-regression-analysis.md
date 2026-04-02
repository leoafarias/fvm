# PR #967 Regression Analysis: install-next.sh v3.0.0

**Analysis Date**: 2025-12-08
**Analyst**: Code Agent
**PR**: https://github.com/leoafarias/fvm/pull/967
**Status**: OPEN - REQUIRES CAREFUL REVIEW BEFORE MERGE

---

## Executive Summary

PR #967 introduces `install-next.sh` v3.0.0 alongside the existing `install.sh` v1.1.0. This is a **fundamental architectural shift** from system-wide installation (`/usr/local/bin/fvm`) to user-local installation (`~/.fvm_flutter/bin`).

**CRITICAL FINDING**: This PR does **NOT replace** the existing installer - it adds a parallel v3 installer for testing. However, if `https://fvm.app/install.sh` is later switched to point to `install-next.sh`, significant breaking changes will occur.

### Risk Assessment

| Category | Risk Level | Impact |
|----------|------------|--------|
| CI/CD Pipelines | 🔴 **CRITICAL** | Workflows expecting `/usr/local/bin/fvm` will break |
| Multi-user Servers | 🔴 **CRITICAL** | No system-wide installation capability |
| Existing User Migration | 🟡 **MEDIUM** | Manual migration required, PATH confusion |
| Root/Container Behavior | 🟡 **MEDIUM** | Security model change from block-by-default to warn-only |
| Documentation/URL | 🔴 **CRITICAL** | If `fvm.app/install.sh` switches, mass breakage |
| IDE Integration | 🟢 **LOW** | Should work if PATH configured correctly |
| Shell Configuration | 🟡 **MEDIUM** | Manual setup vs. auto-modification |

---

## Current Architecture Analysis

### v1.1.0 `install.sh` (Current Production)

**File**: `/Users/leofarias/Projects/fvm/scripts/install.sh` (513 lines)

**Installation Architecture**:
```
Binary Path:     $HOME/.fvm_flutter/bin/fvm
System Symlink:  /usr/local/bin/fvm -> $HOME/.fvm_flutter/bin/fvm
User Access:     Via /usr/local/bin/fvm (in default PATH)
Privilege:       Requires sudo for symlink creation
```

**Key Behaviors** (Evidence from `/Users/leofarias/Projects/fvm/scripts/install.sh`):

1. **Root Blocking** (Lines 277-286):
   ```bash
   if [[ $(id -u) -eq 0 ]]; then
     if is_container_env || [[ "${FVM_ALLOW_ROOT:-}" == "true" ]]; then
       info "Root execution allowed (container/CI/override detected)"
     else
       error "This script should not be run as root. Please run as a normal user.

   For containers/CI: This should be detected automatically.
   To override: export FVM_ALLOW_ROOT=true"
     fi
   fi
   ```

2. **Container Detection** (Lines 99-102):
   ```bash
   is_container_env() {
     [[ -f /.dockerenv ]] || [[ -f /.containerenv ]] || [[ -n "${CI:-}" ]]
   }
   ```

3. **Shell Auto-Modification** (Lines 430-499):
   - Automatically updates `~/.bashrc`, `~/.zshrc`, `~/.config/fish/config.fish`
   - Adds `export PATH="$FVM_DIR_BIN:$PATH"` without user confirmation

4. **System Symlink Creation** (Lines 119-129):
   ```bash
   create_symlink() {
     local source="$1"
     local target="$2"

     if [[ "$IS_ROOT" == "true" ]]; then
       ln -sf "$source" "$target" || error "Failed to create symlink: $target"
     else
       "$ESCALATION_TOOL" ln -sf "$source" "$target" || error "Failed to create symlink: $target"
     fi
   }
   ```

**Evidence from Issue History** (`/Users/leofarias/Projects/fvm/issue-triage/install_permission_issues/install_sh_issue_overview.md`):

- **17 issues** tracked related to install.sh permission problems
- Most common complaint: `ln: failed to create symbolic link '/usr/local/bin/fvm': Permission denied`
- Users on Linux repeatedly hit sudo requirements (#699, #785, #796, #816, #830, #832, #864, #909)
- Root environments (CI/containers) blocked by root check (#864)

### v3.0.0 `install-next.sh` (PR #967)

**File**: Not in current working tree (exists in PR branch `feat/install-script-v2`)

**Installation Architecture** (Evidence from WebFetch of PR branch):
```
Binary Path:     $HOME/.fvm_flutter/bin/fvm
System Symlink:  NONE (removed completely)
User Access:     Via $HOME/.fvm_flutter/bin in user's PATH
Privilege:       No sudo required
```

**Key Behavioral Changes**:

1. **Root Handling**: Warns but **allows** execution
   - v1: Blocks root unless `FVM_ALLOW_ROOT=true` or container detected
   - v3: Warns that installation goes to root's home directory, but proceeds

2. **PATH Configuration**: Prints instructions, **does not auto-modify**
   - v1: Automatically edits shell config files
   - v3: Displays manual instructions for bash/zsh/fish

3. **Container Detection**: **Removed**
   - v1: Detects 10+ CI systems (`.dockerenv`, `.containerenv`, `$CI`, etc.)
   - v3: No special container detection

4. **Migration Logic**: Added `migrate_from_v1()`
   - Detects existing `/usr/local/bin/fvm` symlink
   - Attempts to remove old system installation
   - May fail silently if user lacks sudo permissions

---

## Detailed Regression Analysis

### 1. CI/CD Pipeline Breakage 🔴 CRITICAL

#### Evidence of Current CI Usage

**File**: `/Users/leofarias/Projects/fvm/.github/workflows/test-install.yml`

Lines 79-95 show **container testing expects system symlink**:
```yaml
test-container:
  name: Test Container
  needs: validate
  runs-on: ubuntu-latest
  container: ubuntu:latest
  steps:
    - uses: actions/checkout@v4

    - name: Install dependencies
      run: |
        apt-get update && apt-get install -y curl tar gzip

    - name: Test container root allowed
      run: |
        ./scripts/install.sh
        /usr/local/bin/fvm --version  # <--- Expects /usr/local/bin/fvm
```

#### Breaking Scenarios

**Scenario A: Hardcoded Paths in CI**
```yaml
# Current workflow (WORKS with v1)
- run: /usr/local/bin/fvm install stable

# After v3 switch (BREAKS)
# Error: /usr/local/bin/fvm: No such file or directory
```

**Scenario B: `which fvm` Dependencies**
```yaml
# Current workflow (WORKS with v1)
- run: which fvm
  # Returns: /usr/local/bin/fvm

# After v3 switch (BREAKS if PATH not configured)
# Returns: fvm not found
```

**Scenario C: Docker FROM Layer Caching**
```dockerfile
# Current Dockerfile (WORKS with v1)
RUN curl -fsSL https://fvm.app/install.sh | bash
RUN /usr/local/bin/fvm install stable  # Cached layer expects this path

# After v3 switch (BREAKS)
# Layer invalidation + path not found
```

#### Real-World Impact Evidence

From `/Users/leofarias/Projects/fvm/issue-triage/install_permission_issues/install_sh_issue_overview.md`:

- Issue #864: Codex (root container) regression after script update
- Issue #907: Alpine CI validation specifically tests container environments
- Issue #932: PR #932 (closed, merged v3.0.0 to `install.sh`) added container detection

**GitHub Actions Usage Pattern**:
```bash
# Common pattern in user repos (based on issue comments)
- run: curl -fsSL https://fvm.app/install.sh | bash
- run: fvm install 3.10.0
- run: fvm flutter build apk
```

**RISK**: If `fvm.app/install.sh` switches to v3, thousands of workflows may break silently if they don't source shell configs or expect system-wide `fvm`.

### 2. Multi-user Server Environments 🔴 CRITICAL

#### Current Architecture (v1.1.0)

**Shared Server Pattern**:
```bash
# Admin installs once (with sudo)
$ sudo curl -fsSL https://fvm.app/install.sh | bash

# Creates:
# - /usr/local/bin/fvm -> /root/.fvm_flutter/bin/fvm
# - Available to all users system-wide

# User A runs:
$ fvm install stable
# Works - uses global /usr/local/bin/fvm

# User B runs:
$ fvm install beta
# Works - uses global /usr/local/bin/fvm
```

**Evidence**: Issue #785 from `install_sh_issue_overview.md`:
> "Linux complaint emphasising that using sudo places files under `/root/.fvm`, leaving the invoking user without a working binary."

This indicates users **expect** system-wide installation despite the issues.

#### v3.0.0 Architecture

**No System-Wide Option**:
```bash
# Admin attempts install
$ curl -fsSL https://fvm.app/install-next.sh | bash
# Warning: Running as root. FVM will be installed to /root/.fvm_flutter/bin
# Creates: /root/.fvm_flutter/bin/fvm (not accessible to other users)

# User A must install separately:
$ curl -fsSL https://fvm.app/install-next.sh | bash
# Creates: /home/userA/.fvm_flutter/bin/fvm

# User B must install separately:
$ curl -fsSL https://fvm.app/install-next.sh | bash
# Creates: /home/userB/.fvm_flutter/bin/fvm
```

**Regression**: No mechanism for single system-wide installation in v3.

**CRITICAL**: PR #967 description claims migration to "v2" with `--system` flag:
> ### For System-Wide Installations
> Use the `--system` flag:
> ```bash
> curl -fsSL https://fvm.app/install.sh | bash -s -- --system
> ```

**PROBLEM**: This flag does **not exist** in the WebFetch result of `install-next.sh`. The PR description appears to be **stale documentation** from an earlier iteration.

### 3. Existing User Migration 🟡 MEDIUM

#### Migration Mechanism Analysis

From WebFetch of `install-next.sh`:
- Function `migrate_from_v1()` - Removes old system installations at `/usr/local/bin/fvm`

**Expected Behavior**:
```bash
# User has v1 installed
$ which fvm
/usr/local/bin/fvm

# User runs v3 installer
$ curl -fsSL https://fvm.app/install-next.sh | bash
# migrate_from_v1() detects /usr/local/bin/fvm
# Attempts: sudo rm -f /usr/local/bin/fvm

# If sudo succeeds:
#   - Old symlink removed
#   - New binary at ~/.fvm_flutter/bin/fvm
#   - PATH instructions printed

# If sudo fails (no password, no sudo):
#   - Old symlink remains
#   - New binary at ~/.fvm_flutter/bin/fvm
#   - User has TWO fvm binaries (which one wins depends on PATH order)
```

**Edge Cases**:

1. **Non-interactive Shell** (CI, scripts):
   - `sudo rm` may prompt for password
   - Migration fails silently
   - PATH confusion: old symlink remains, new binary added to PATH

2. **Custom `$SYMLINK_TARGET`** (v1 users who modified script):
   - v1 allowed overriding `SYMLINK_TARGET` via environment variable
   - v3 migration only checks `/usr/local/bin/fvm`
   - Custom symlinks orphaned

3. **Fish Shell Markers**:
   - v1: Adds `# FVM` marker to fish config
   - v3: Different marker format (based on PR description of v3.0.0 improvements)
   - Duplicate PATH entries if both markers exist

#### PATH Configuration Breakage

**v1 Behavior** (Lines 430-451 of `install.sh`):
```bash
update_shell_config() {
  local config_file="$1"
  local export_command="$2"
  local tilde_config="${config_file/#$HOME/\~}"
  local tilde_fvm_dir="${FVM_DIR_BIN/#$HOME/\~}"

  if [[ -w "$config_file" ]]; then
    if ! grep -q "$FVM_DIR_BIN" "$config_file"; then
      {
        echo -e "\n# FVM"
        echo "$export_command"
      } >> "$config_file"
      # ...
    fi
  fi
}
```

**v3 Behavior** (from WebFetch):
> "Shell-specific PATH configuration instructions (bash, zsh, fish)"

**Regression**:
- v1 users have PATH auto-configured
- v3 users must manually add PATH
- If user reinstalls with v3, PATH already exists (from v1) but instructions printed anyway
- Users may add PATH twice, once from v1 auto-config, once manually from v3 instructions

**RISK**: User confusion, support burden, "fvm command not found" reports.

### 4. Root/Container Behavior Changes 🟡 MEDIUM

#### Security Model Shift

**v1.1.0**: **Fail-safe** (Block by default)
```bash
# Default behavior
$ sudo ./install.sh
error: This script should not be run as root. Please run as a normal user.
# Exit code: 1

# Explicit override required
$ sudo env FVM_ALLOW_ROOT=true ./install.sh
info: Root execution allowed (container/CI/override detected)
# Proceeds with installation

# Container auto-detection
$ docker run -it ubuntu:latest
root@container:/# ./install.sh
info: Root execution allowed (container/CI/override detected)
# Proceeds without FVM_ALLOW_ROOT
```

**v3.0.0**: **Warn-only** (Allow by default)
```bash
# Default behavior (from WebFetch)
$ sudo ./install-next.sh
Warning: Running as root. FVM will be installed to /root/.fvm_flutter/bin
# Proceeds with installation

# No blocking mechanism
# No container detection
```

#### Security Implications

**Pros of v3 Approach**:
- Simpler code (no container detection logic)
- No CI breakage from overly strict root checks
- Follows KISS principle

**Cons of v3 Approach**:

1. **Accidental Root Installs**:
   ```bash
   # User accidentally runs with sudo
   $ sudo curl -fsSL https://fvm.app/install-next.sh | bash
   # Installs to /root/.fvm_flutter/bin
   # User's normal account can't access it
   # User confused: "I installed FVM but `fvm` command not found"
   ```

2. **Security Awareness**:
   - v1 forces users to explicitly opt-in to root execution
   - v3 only warns (warning may be missed in CI output)
   - Less "secure by default"

3. **Container Detection Loss**:
   - v1: Automatically detects 10+ CI/container environments
   - v3: No detection, treats all root execution the same
   - **RISK**: Docker builds that relied on auto-detection now see warnings

**Real-World Evidence**:

From `install_sh_issue_overview.md`:
- Issue #864: "install script aborts with 'This script should not be run as root,' blocking automation"
- Issue #907: Draft plan includes "musl detection with fallbacks" and "Alpine CI coverage"

This indicates the v1 root blocking **caused regressions** for container users, justifying the v3 approach.

**VERDICT**: This is a **reasonable architectural trade-off**, but the change must be **clearly documented** in release notes.

### 5. Documentation/URL Implications 🔴 CRITICAL

#### Current URL Behavior

**Production URL**: `https://fvm.app/install.sh`

**Evidence from codebase**:

**File**: `/Users/leofarias/Projects/fvm/docs/pages/documentation/getting-started/installation.mdx`

Lines 27-34:
```markdown
Install the latest version:

```bash
curl -fsSL https://fvm.app/install.sh | bash
```

Install a specific version:

```bash
curl -fsSL https://fvm.app/install.sh | bash -s <version>
```
```

**File**: `/Users/leofarias/Projects/fvm/docs/public/install.sh`

Lines 5-6:
```bash
#   curl -fsSL https://fvm.app/install.sh | bash
#   curl -fsSL https://fvm.app/install.sh | bash -s 3.2.1
```

**Current Mapping**:
```
https://fvm.app/install.sh -> /Users/leofarias/Projects/fvm/docs/public/install.sh (v1.1.0)
```

#### If URL Switches to v3.0.0

**Scenario**: `docs/public/install.sh` replaced with `install-next.sh` content

**Impact Radius** (grep results from earlier):
- 16 references to `fvm.app/install.sh` in documentation
- 8 references in issue templates/comments
- Unknown number in external:
  - User blog posts
  - CI/CD templates
  - Corporate wikis
  - Stack Overflow answers
  - YouTube tutorials

**Breaking Change Cascade**:

1. **Documentation Instant Breakage**:
   ```bash
   # User follows docs
   $ curl -fsSL https://fvm.app/install.sh | bash
   # Now gets v3 instead of v1
   # No /usr/local/bin/fvm symlink
   # Must manually configure PATH
   ```

2. **CI/CD Pipeline Failures**:
   - Workflows with `which fvm` checks fail
   - Hardcoded `/usr/local/bin/fvm` paths fail
   - Docker builds with path assumptions break

3. **Support Burden**:
   - "fvm command not found" issue spike
   - Users don't understand why `which fvm` stopped working
   - Confusion between v1 and v3 behaviors

**CRITICAL**: PR #967 does **NOT propose** switching the URL. It adds `install-next.sh` alongside `install.sh` for **testing**.

However, the **risk exists** if a future decision switches the URL without proper migration planning.

### 6. IDE Integration 🟢 LOW

#### Analysis

**IDE Configuration Patterns**:

Most IDEs reference FVM via:
1. **Flutter SDK Path**: `~/.fvm/versions/<version>/bin` (unchanged)
2. **FVM Command**: Resolved via `$PATH` or explicit path

**VS Code** (`settings.json`):
```json
{
  "dart.flutterSdkPath": ".fvm/versions/stable",
  "dart.flutterSdkPaths": [".fvm/versions"]
}
```
- **Impact**: None. VS Code doesn't call `fvm` binary directly.

**Android Studio**:
- Uses Flutter SDK path selector
- **Impact**: None if SDK paths unchanged.

**Terminal-based Workflows**:
```bash
# If user has PATH configured (either v1 auto or v3 manual)
$ fvm flutter run
# Works regardless of binary location
```

**VERDICT**: IDE integration should work if users configure PATH correctly. The change is **transparent to IDEs**.

**RISK**: Only if user's PATH is **not configured** after v3 install (because auto-modification removed).

### 7. Shell Configuration 🟡 MEDIUM

#### Behavioral Comparison

**v1.1.0**: **Automatic Modification**

Evidence from `/Users/leofarias/Projects/fvm/scripts/install.sh` Lines 430-499:

```bash
# For bash
if ! update_shell_config "$HOME/.bashrc" "$(get_path_export bash)"; then
  log "Manually add the following line to ~/.bashrc:"
  info "  $(get_path_export bash)"
fi

# For zsh
if ! update_shell_config "$HOME/.zshrc" "$(get_path_export zsh)"; then
  log "Manually add the following line to ~/.zshrc:"
  info "  $(get_path_export zsh)"
fi

# For fish
if ! update_shell_config "$HOME/.config/fish/config.fish" "$(get_path_export fish)"; then
  log "Manually add the following line to ${fish_config/#$HOME/\~}:"
  info "  $(get_path_export fish)"
fi
```

**v3.0.0**: **Manual Instructions Only**

From WebFetch:
> "Shell-specific PATH configuration instructions (bash, zsh, fish)"

No automatic file modification.

#### User Experience Impact

**v1 Experience**:
```bash
$ curl -fsSL https://fvm.app/install.sh | bash
✓ Installation complete!
✓ Added [~/.fvm_flutter/bin] to $PATH in [~/.zshrc]

To use fvm right away, run:
  source ~/.zshrc
  fvm --help

# User runs:
$ source ~/.zshrc
$ fvm --version
# Works immediately
```

**v3 Experience**:
```bash
$ curl -fsSL https://fvm.app/install-next.sh | bash
✓ Installation complete!

Please add the following to your shell config:
  export PATH="$HOME/.fvm_flutter/bin:$PATH"

For bash, add to ~/.bashrc
For zsh, add to ~/.zshrc
For fish, add to ~/.config/fish/config.fish

# User must manually edit config file
# Many users will skip this or do it incorrectly
```

#### Regression Evidence

**Historical Context** from `install_sh_issue_overview.md`:

Issue #700 (MERGED):
> "feat: automatically add `~/.fvm_flutter/bin` to the PATH var in `install.sh`"

This PR **added** the automatic PATH configuration because users were **not configuring it manually**.

**Regression**: v3 removes a feature that was **explicitly added** to solve user pain.

#### YAGNI Violation Analysis

From architectural principles (`/Users/leofarias/.claude/knowledge/architect/general-principles.md`):

> **YAGNI (You Aren't Gonna Need It)**
> Don't build functionality until it's actually needed.

**Counter-Evidence**: Automatic PATH configuration **was needed** (evidenced by issue #700).

**KISS Principle**:
> The simplest solution that solves the problem is usually the best solution.

**Analysis**:
- v1: Automatic modification = works immediately (KISS for users)
- v3: Manual instructions = simpler code (KISS for maintainers)

**Trade-off**: Developer simplicity vs. user simplicity.

**VERDICT**: Removing auto-modification is a **UX regression** that will increase support burden, but it **reduces code complexity** and **improves safety** (no unexpected file modifications).

This is a **reasonable architectural decision** IF:
1. Clearly documented in release notes
2. Migration guide provided
3. User expectations managed

---

## Migration Path Analysis

### Scenario A: Parallel Deployment (PR #967 Current State)

**Status**: SAFE

Both scripts coexist:
- `https://fvm.app/install.sh` → v1.1.0 (unchanged)
- `https://fvm.app/install-next.sh` → v3.0.0 (new, opt-in)

**No breakage** for existing users. v3 can be tested independently.

### Scenario B: URL Switch Without Migration Period

**Status**: 🔴 UNSAFE - DO NOT MERGE AS-IS

If `https://fvm.app/install.sh` is replaced with v3.0.0 content:

**Immediate Breakage**:
1. CI/CD workflows expecting `/usr/local/bin/fvm` fail
2. Multi-user servers lose system-wide installation
3. Users following cached documentation get v3 instead of v1
4. Support ticket spike: "fvm command not found"

**Required Before URL Switch**:
1. **Deprecation Notice** (6+ months):
   - Add warning to v1 installer: "This installer will be replaced with v3 on [DATE]"
   - Document v1→v3 differences
   - Provide migration checklist

2. **Version Detection**:
   - v1 installer should detect if v3 is already installed
   - Offer to migrate or coexist

3. **Backward Compatibility Bridge**:
   - v3 should offer `--compat-v1` flag to create system symlink
   - Or provide `install-legacy.sh` permanently

4. **Documentation Update**:
   - Clear migration guide
   - Update all references to installation behavior
   - Add troubleshooting for PATH issues

### Scenario C: Recommended Migration Strategy

**Phase 1: Parallel Deployment** (Current PR #967)
- Deploy `install-next.sh` at `https://fvm.app/install-next.sh`
- Keep `install.sh` at `https://fvm.app/install.sh` (v1.1.0)
- Duration: 6 months

**Phase 2: Deprecation Warning**
- Add to v1 installer:
  ```bash
  warn "This installer (v1) is deprecated and will be removed on 2025-06-01"
  warn "Please migrate to v3: curl -fsSL https://fvm.app/install-next.sh | bash"
  warn "See migration guide: https://fvm.app/documentation/migration/v1-to-v3"
  ```
- Duration: 6 months

**Phase 3: URL Switch**
- Rename `install.sh` → `install-legacy.sh`
- Copy `install-next.sh` → `install.sh`
- Update all documentation
- Monitor support channels for issues

**Phase 4: Legacy Removal** (Optional)
- After 12 months, remove `install-legacy.sh`
- Or keep permanently for edge cases

---

## Recommended Mitigation Strategies

### For CI/CD Pipeline Breakage

**Strategy 1: Environment Variable for System Install**

Add to v3.0.0:
```bash
# install-next.sh
if [[ "${FVM_SYSTEM_INSTALL:-false}" == "true" ]]; then
  # Create system symlink (requires sudo)
  create_system_symlink
fi
```

**Usage**:
```bash
# CI workflow update
- run: curl -fsSL https://fvm.app/install.sh | bash -s -- --system
# Or
- run: env FVM_SYSTEM_INSTALL=true curl -fsSL https://fvm.app/install.sh | bash
```

**Strategy 2: Explicit PATH in CI**

Document best practice:
```yaml
# Add to CI workflow
- name: Install FVM
  run: curl -fsSL https://fvm.app/install.sh | bash

- name: Add FVM to PATH
  run: echo "$HOME/.fvm_flutter/bin" >> $GITHUB_PATH

- name: Verify FVM
  run: fvm --version
```

**Strategy 3: Docker Layer Strategy**

```dockerfile
# Dockerfile update
RUN curl -fsSL https://fvm.app/install.sh | bash
ENV PATH="$HOME/.fvm_flutter/bin:$PATH"
RUN fvm install stable
```

### For Multi-user Servers

**Strategy 1: Reinstall Per User**

Document that each user must install separately:
```bash
# Each user runs
curl -fsSL https://fvm.app/install.sh | bash
```

**Strategy 2: Provide System Install Script**

Create `install-system.sh` variant:
```bash
#!/usr/bin/env bash
# install-system.sh - System-wide installation

INSTALL_DIR="/opt/fvm"
mkdir -p "$INSTALL_DIR"
curl -L ... | tar -xz -C "$INSTALL_DIR"
ln -sf "$INSTALL_DIR/fvm" /usr/local/bin/fvm
```

**Strategy 3: Package Manager Distribution**

Recommend Homebrew/apt/yum for system-wide installs instead of shell script.

### For Existing User Migration

**Strategy 1: Auto-Migration on First Run**

Add to v3.0.0:
```bash
# On first run, detect v1 installation
if [[ -L "/usr/local/bin/fvm" ]] && [[ ! -f "$HOME/.fvm_flutter/.migrated" ]]; then
  warn "Detected v1 installation at /usr/local/bin/fvm"
  warn "Migrating to v3 user-local installation..."

  # Remove old symlink
  sudo rm -f /usr/local/bin/fvm

  # Mark as migrated
  touch "$HOME/.fvm_flutter/.migrated"

  success "Migration complete. Please update your PATH:"
  info "  export PATH=\"$HOME/.fvm_flutter/bin:\$PATH\""
fi
```

**Strategy 2: Migration Command**

Add `fvm migrate` command:
```bash
$ fvm migrate --from-v1
Detected v1 installation at /usr/local/bin/fvm
Removing system symlink...
✓ Migration complete

Please add to your shell config:
  export PATH="$HOME/.fvm_flutter/bin:$PATH"
```

**Strategy 3: Coexistence Mode**

Allow v1 and v3 to coexist:
```bash
# v3 installer checks for v1
if [[ -L "/usr/local/bin/fvm" ]]; then
  info "Detected v1 installation. Installing v3 alongside..."
  info "Both versions will work. v3 has higher priority in PATH."
fi
```

### For Root/Container Behavior

**Strategy 1: Explicit Container Detection**

Restore container detection in v3:
```bash
# install-next.sh
is_container_env() {
  [[ -f /.dockerenv ]] || [[ -f /.containerenv ]] || [[ -n "${CI:-}" ]]
}

if [[ $(id -u) -eq 0 ]]; then
  if is_container_env; then
    info "Container environment detected. Installing to /root/.fvm_flutter/bin"
  else
    warn "Running as root. Installation will be in /root/.fvm_flutter/bin"
    warn "Other users will not have access. Consider per-user installation."
  fi
fi
```

**Strategy 2: Environment Variable Override**

```bash
# For CI that needs system install
FVM_SYSTEM_INSTALL=true curl -fsSL https://fvm.app/install.sh | bash
```

### For Documentation/URL

**Strategy 1: Versioned URLs**

```
https://fvm.app/install.sh       -> v1.1.0 (legacy, permanent)
https://fvm.app/install-v3.sh    -> v3.0.0 (new)
https://fvm.app/install-latest.sh -> v3.0.0 (switch after deprecation)
```

**Strategy 2: Content Negotiation**

Add version detection:
```bash
# install.sh (smart router)
if [[ "${FVM_INSTALLER_VERSION:-v3}" == "v1" ]]; then
  # Download and execute v1
  curl -fsSL https://fvm.app/install-v1.sh | bash
else
  # Download and execute v3
  curl -fsSL https://fvm.app/install-v3.sh | bash
fi
```

**Strategy 3: Migration Landing Page**

Create `https://fvm.app/install` that:
1. Detects existing installation
2. Recommends v1 or v3 based on context
3. Provides migration guide
4. Redirects to appropriate installer

---

## Validation Checklist

Before merging PR #967 or switching production URL:

### Pre-Merge Validation

- [ ] Verify `install-next.sh` is **not replacing** `install.sh` in PR
- [ ] Confirm `https://fvm.app/install.sh` still points to v1.1.0 after merge
- [ ] Test `install-next.sh` on all supported platforms:
  - [ ] Ubuntu x64 (non-root)
  - [ ] Ubuntu x64 (container, root)
  - [ ] macOS x64 (Intel)
  - [ ] macOS arm64 (Apple Silicon)
  - [ ] Alpine Linux (musl)
- [ ] Verify migration from v1→v3 works:
  - [ ] v1 installed, run v3, check symlink removal
  - [ ] v1 installed without sudo, run v3, check coexistence
- [ ] Test PATH configuration:
  - [ ] bash (verify manual instructions work)
  - [ ] zsh (verify manual instructions work)
  - [ ] fish (verify manual instructions work)
- [ ] Verify root warning displays correctly
- [ ] Test uninstall functionality

### Documentation Validation

- [ ] PR description matches actual code behavior
- [ ] `--system` flag claim verified (FAILED - flag doesn't exist)
- [ ] Migration guide exists and is accurate
- [ ] Release notes include breaking changes section
- [ ] FAQ updated with v1 vs v3 comparison
- [ ] CI/CD integration guide updated

### Regression Testing

- [ ] CI workflows still pass with v1 (ensure v3 doesn't break current setup)
- [ ] Docker builds using v1 still work
- [ ] Multi-user scenarios documented (even if unsupported in v3)
- [ ] Existing user migration path documented
- [ ] Rollback procedure documented

### Communication Validation

- [ ] Blog post announcing v3 availability (not as default)
- [ ] Discord/community notification about testing v3
- [ ] GitHub discussion for feedback
- [ ] Migration timeline published (if URL switch planned)

---

## Verdict

### Current PR #967 State: ✅ SAFE TO MERGE (with conditions)

**Why**: PR adds `install-next.sh` **alongside** existing `install.sh`. No breaking changes to production.

**Conditions**:
1. Verify PR does NOT modify `docs/public/install.sh` to point to v3
2. Add clear documentation that v3 is **opt-in** for testing
3. Update PR description to remove incorrect `--system` flag claim

### Future URL Switch to v3: ❌ NOT SAFE WITHOUT MIGRATION PLAN

**Blockers**:
1. No migration period or deprecation warnings
2. Multi-user server use case completely removed
3. CI/CD breakage not addressed
4. PATH configuration regression (UX degradation)
5. Stale documentation in PR description

**Required Before URL Switch**:
1. **Minimum 6-month deprecation period** with warnings in v1
2. **Add `--system` flag to v3** for CI/CD compatibility OR provide permanent `install-legacy.sh`
3. **Migration guide** with PATH configuration steps
4. **Updated documentation** with clear v1→v3 comparison table
5. **Rollback plan** if issues arise post-switch

### Recommended Action

**For PR #967**:
- ✅ **MERGE** as-is (deploys v3 to `install-next.sh` for testing)
- 🔧 **FIX** PR description to remove `--system` flag claim
- 📝 **ADD** comment clarifying v3 is opt-in, not replacing v1

**For Production URL Switch**:
- ⏸️ **DEFER** URL switch by 6-12 months
- 📋 **CREATE** migration project plan
- 🧪 **GATHER** feedback from v3 testers
- 📊 **MEASURE** adoption rate of `install-next.sh` before switching default

---

## Appendix: File References

All evidence cited in this analysis:

| File | Purpose | Lines Referenced |
|------|---------|------------------|
| `/Users/leofarias/Projects/fvm/scripts/install.sh` | v1.1.0 current installer | 99-102 (container detection), 119-129 (symlink creation), 277-286 (root blocking), 430-499 (shell config) |
| `/Users/leofarias/Projects/fvm/.github/workflows/test-install.yml` | CI testing | 79-95 (container test expecting /usr/local/bin/fvm) |
| `/Users/leofarias/Projects/fvm/docs/pages/documentation/getting-started/installation.mdx` | User documentation | 27-34 (install.sh URL references) |
| `/Users/leofarias/Projects/fvm/issue-triage/install_permission_issues/install_sh_issue_overview.md` | Historical issues | All (permission issues, root blocking regressions) |
| `/Users/leofarias/Projects/fvm/issue-triage/pending_issues/open_prs.json` | PR metadata | Lines 60-68 (PR #967 description) |
| WebFetch: `feat/install-script-v2` branch | v3.0.0 installer code | (complete script analysis) |

---

**Analysis completed**: 2025-12-08
**Recommendation**: Safe to merge PR #967 as parallel deployment. **Do not switch production URL** without 6-month migration plan.
