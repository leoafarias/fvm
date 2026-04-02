# Issue #974 - Technical Analysis: Install Script Cross-User Architecture Concerns

## Issue Details
- **Number**: #974
- **Title**: [BUG] Put the binary in a user directory, then expose it via a system-wide symlink will create many issues
- **Reporter**: @zhengpenghou
- **Status**: Open
- **Label**: bug
- **Created**: November 15, 2025

---

## Executive Summary

The concerns raised in issue #974 are **technically valid** and represent a fundamental architectural problem with the current FVM installation model. The script installs binaries in a per-user directory (`$HOME/.fvm_flutter`) but creates system-wide symlinks (`/usr/local/bin/fvm`), creating security, permission, and maintainability issues in multi-user environments.

**Verdict**: This is a **legitimate architectural flaw**, not a minor bug. The current design violates Unix/Linux multi-user security principles.

---

## Detailed Technical Analysis

### 1. Cross-User Security & Dependency Problem ✅ VALID

**Issue Claim**: "One user's home directory becomes part of another user's runtime environment"

**Code Evidence**:
```bash
# File: scripts/install.sh
# Line 24
FVM_DIR="$HOME/.fvm_flutter"

# Line 26
SYMLINK_TARGET="/usr/local/bin/fvm"

# Lines 414-415
info "Creating symlink: $SYMLINK_TARGET -> $FVM_DIR_BIN/fvm"
create_symlink "$FVM_DIR_BIN/fvm" "$SYMLINK_TARGET"
```

**Analysis**:
When User A (alice) runs the install script:
1. Binary installed at: `/home/alice/.fvm_flutter/bin/fvm`
2. System symlink created: `/usr/local/bin/fvm → /home/alice/.fvm_flutter/bin/fvm`

When User B (bob) runs `fvm`:
```bash
bob@server:~$ which fvm
/usr/local/bin/fvm

bob@server:~$ ls -l /usr/local/bin/fvm
lrwxrwxrwx 1 root root 37 Dec 08 10:00 /usr/local/bin/fvm -> /home/alice/.fvm_flutter/bin/fvm
```

**Problems**:
- Bob's FVM execution depends on Alice's home directory remaining accessible
- If Alice's account is deleted/disabled, Bob's FVM breaks
- If Alice's home is on a network mount that's unavailable, system-wide FVM fails
- Permission issues if Alice's home has restrictive permissions (700)
- Violates principle of least privilege - Alice controls system-wide binary behavior

**Historical Context**:
From `/Users/leofarias/Projects/fvm/issue-triage/install_permission_issues/install_sh_issue_overview.md`:
- Issue #699 (March 2024): Original permission-denied report
- Issue #785 (September 2024): "Using sudo places files under `/root/.fvm`, leaving the invoking user without a working binary"
- Issue #832 (March 2025): Linux users hitting permission denied even under sudo

**Conclusion**: **100% VALID** - This is a security and reliability concern.

---

### 2. Permissions & Sudo Friction ✅ VALID

**Issue Claim**: "A standard user installation requires two incompatible permission levels"

**Code Evidence**:
```bash
# File: scripts/install.sh
# Lines 109-117
ESCALATION_TOOL=''
if [[ "$IS_ROOT" != "true" ]]; then
  for cmd in sudo doas; do
    if command -v "$cmd" &>/dev/null; then
      ESCALATION_TOOL="$cmd"
      break
    fi
  done
fi

# Lines 120-129
create_symlink() {
  local source="$1"
  local target="$2"

  if [[ "$IS_ROOT" == "true" ]]; then
    ln -sf "$source" "$target" || error "Failed to create symlink: $target"
  else
    "$ESCALATION_TOOL" ln -sf "$source" "$target" || error "Failed to create symlink: $target"
  fi
}

# Lines 294-299
if [[ "$IS_ROOT" != "true" ]]; then
  if [[ -z "$ESCALATION_TOOL" ]]; then
    error "Cannot find sudo or doas. Install one or run as root."
  fi
fi
```

**Analysis**:
The script **requires** privilege escalation for non-root users:
1. User writes to `$HOME/.fvm_flutter` (no sudo needed) ✓
2. Script requires sudo/doas to create `/usr/local/bin/fvm` symlink (line 127) ✗

**Failure Scenarios**:
- **No sudo access**: Users without sudo privileges cannot install (common in corporate/university environments)
- **Managed `/usr/local/bin`**: Systems using Nix, Homebrew, or package managers may protect `/usr/local/bin`
- **CI/Container environments**: Addressed via `FVM_ALLOW_ROOT`, but adds complexity
- **Windows WSL**: May have permission model mismatches

**Historical Evidence** (from overview.md):
- Issue #699: "The script uses `/usr/local/bin/fvm` as a link target which requires sudo privileges"
- Issue #796: "Even `sudo curl … | bash` fails because the pipe executes without sustained elevation"
- Issue #816: macOS 15.3 on Apple Silicon - `/usr/local/bin` doesn't exist by default
- Issue #830: PR to allow `SYMLINK_DIR` environment variable to override default

**Current Workarounds in Code**:
Lines 336-346 attempt to create `/usr/local/bin` if missing:
```bash
SYMLINK_DIR="$(dirname "$SYMLINK_TARGET")"
if [[ ! -d "$SYMLINK_DIR" ]]; then
  if [[ "$IS_ROOT" == "true" ]]; then
    mkdir -p "$SYMLINK_DIR" || error "Failed to create directory: $SYMLINK_DIR"
    info "Created directory: $SYMLINK_DIR"
  else
    error "Symlink target directory does not exist: $SYMLINK_DIR

Please create it with: sudo mkdir -p $SYMLINK_DIR"
  fi
fi
```

**Problem**: This **still requires sudo** if the directory doesn't exist, proving the issue.

**Conclusion**: **100% VALID** - The architecture fundamentally requires privilege escalation.

---

### 3. Uninstall Semantics ✅ VALID

**Issue Claim**: "Uninstall removing system-wide symlinks that may affect other users"

**Code Evidence**:
```bash
# File: scripts/install.sh (uninstall mode)
# Lines 143-190
uninstall_fvm() {
  info "Uninstalling FVM..."

  # Check if FVM is installed
  local fvm_found=false

  # Check for FVM directory
  if [[ -d "$FVM_DIR" ]]; then
    fvm_found=true
    info "Found FVM directory: $FVM_DIR"
  fi

  # Check for symlink
  if [[ -L "$SYMLINK_TARGET" ]] && [[ "$(readlink "$SYMLINK_TARGET")" == *"fvm"* ]]; then
    fvm_found=true
    info "Found FVM symlink: $SYMLINK_TARGET"
  fi

  # ...

  # Remove FVM directory
  if [[ -d "$FVM_DIR" ]]; then
    info "Removing FVM directory..."
    rm -rf "$FVM_DIR" || error "Failed to remove $FVM_DIR"
    success "Removed $FVM_DIR"
  fi

  # Remove symlink
  if [[ -L "$SYMLINK_TARGET" ]]; then
    info "Removing FVM symlink..."
    remove_symlink "$SYMLINK_TARGET"
    success "Removed $SYMLINK_TARGET"
  fi

  # ...
}
```

**Analysis**:

**Problem 1: Heuristic-Based Detection**
Line 156: `[[ "$(readlink "$SYMLINK_TARGET")" == *"fvm"* ]]`

This glob pattern matches **any symlink containing "fvm"**, not just FVM installations. Could match:
- `/home/alice/.fvm_flutter/bin/fvm` ✓ (correct)
- `/opt/fvm/bin/fvm` ✗ (false positive - different installation)
- `/home/bob/.fvm_flutter/bin/fvm` ✗ (false positive - Bob's installation)

**Problem 2: System-Wide Impact**
When Alice uninstalls:
1. Line 169: Removes `/home/alice/.fvm_flutter` (only affects Alice) ✓
2. Line 176: Removes `/usr/local/bin/fvm` symlink (affects ALL USERS) ✗

**Multi-User Scenario**:
```bash
# Initial state
/usr/local/bin/fvm → /home/alice/.fvm_flutter/bin/fvm

# Alice uninstalls
alice@server:~$ ./install.sh --uninstall
# Removes /usr/local/bin/fvm

# Bob tries to use FVM
bob@server:~$ fvm --version
bash: fvm: command not found
```

**Problem 3: Race Condition**
If Bob installed FVM **after** Alice:
```bash
# Alice installs first
/usr/local/bin/fvm → /home/alice/.fvm_flutter/bin/fvm

# Bob installs later (overwrites symlink)
/usr/local/bin/fvm → /home/bob/.fvm_flutter/bin/fvm

# Alice uninstalls
alice@server:~$ ./install.sh --uninstall
# Removes /usr/local/bin/fvm (Bob's symlink!)
# Bob's FVM is now broken
```

**Separate uninstall.sh Script**:
The file `/Users/leofarias/Projects/fvm/scripts/uninstall.sh` (lines 16-35) has the **same problems** but **doesn't even check if the symlink points to the current user's home**:

```bash
# File: scripts/uninstall.sh
# Lines 17-18
FVM_DIR="$HOME/.fvm_flutter"
FVM_DIR_BIN="$FVM_DIR/bin"

# Lines 21-25
echo "Uninstalling FVM..."
rm -rf "$FVM_DIR" || {
    echo "Failed to remove FVM directory: $FVM_DIR."
    exit 1
}
```

**Critical Issue**: `uninstall.sh` doesn't even attempt to remove the symlink! It only removes the user's home directory, leaving a **broken symlink** in `/usr/local/bin/fvm`.

**Conclusion**: **100% VALID** - Uninstall logic is dangerous in multi-user environments and inconsistent between scripts.

---

### 4. Home Directory Dependence ✅ VALID

**Issue Claim**: "System binaries should not depend on the installer user's $HOME"

**Code Evidence**:
```bash
# File: scripts/install.sh
# Line 24
FVM_DIR="$HOME/.fvm_flutter"
```

**Analysis**:
The symlink target is **always** the installing user's home:
```bash
/usr/local/bin/fvm → /home/alice/.fvm_flutter/bin/fvm
```

**Brittleness Scenarios**:

1. **Home Directory Move**:
```bash
# Before
alice: /home/alice/.fvm_flutter/bin/fvm

# Admin moves home directories to new mount
alice: /data/home/alice/.fvm_flutter/bin/fvm

# Symlink is now broken
/usr/local/bin/fvm → /home/alice/.fvm_flutter/bin/fvm (ENOENT)
```

2. **Username Change**:
```bash
# User "alice" renamed to "alice.smith" for corporate policy
# Old: /home/alice/.fvm_flutter/bin/fvm
# New: /home/alice.smith/.fvm_flutter/bin/fvm
# Symlink: Still points to /home/alice (broken)
```

3. **Backup/Restore**:
```bash
# System restored from backup where alice's UID was 1001
# New system assigns UID 1001 to different user
# Symlink now points to wrong user's directory
```

4. **Home Directory Permissions**:
```bash
# Alice sets restrictive permissions
alice@server:~$ chmod 700 /home/alice

# Bob tries to run FVM
bob@server:~$ fvm --version
bash: /usr/local/bin/fvm: Permission denied
```

5. **Network Mounts**:
```bash
# Alice's home is on NFS/CIFS mount
# Mount fails or is temporarily unavailable
# System-wide FVM fails for all users
```

**Conventional Unix Practice**:
System-wide binaries should be in system-owned locations:
- `/usr/local/bin/` - System binaries (owned by root)
- `/opt/fvm/` - Optional software packages
- `/usr/bin/` - System distribution binaries

User-specific tools should be in user-owned locations:
- `~/.local/bin/` - User-specific binaries
- `~/bin/` - Traditional user binary directory

**Conclusion**: **100% VALID** - System symlinks should not depend on user home directories.

---

## Root Cause Analysis

### Architectural Decision Tree

The current install script makes this decision:

```
Install FVM
├─ Binary location: $HOME/.fvm_flutter/bin/fvm (user-writable)
└─ Expose via: /usr/local/bin/fvm (system-wide, requires sudo)
```

**Why this choice was made** (inferred from git history):
1. **User convenience**: No sudo needed for FVM's cache/version downloads
2. **Multi-version support**: Each user can have different FVM configurations
3. **Avoid system package conflicts**: Don't conflict with system FVM packages
4. **PATH simplicity**: Users expect `fvm` to "just work" without PATH configuration

**Why it's problematic**:
- Mixes **user-level data** (`~/.fvm_flutter`) with **system-level access** (`/usr/local/bin`)
- Requires **privilege escalation** for user-level tool
- Breaks **multi-user isolation**
- Violates **single responsibility** (user tool vs system tool)

---

## Alternative Architectures (Not Implementing - Analysis Only)

### Option 1: Pure User Installation (Recommended for single-user)
```bash
FVM_DIR="$HOME/.fvm_flutter"
SYMLINK_TARGET="$HOME/.local/bin/fvm"
# User adds ~/.local/bin to PATH in shell config
```
**Pros**: No sudo, no multi-user issues, follows XDG Base Directory spec
**Cons**: Requires PATH configuration, not immediately available

### Option 2: Pure System Installation (Recommended for multi-user)
```bash
FVM_DIR="/opt/fvm"
SYMLINK_TARGET="/usr/local/bin/fvm"
# Requires root/sudo for installation
```
**Pros**: True system-wide installation, no home dependencies
**Cons**: Requires root for installation, single version for all users

### Option 3: Hybrid with User Override (Most flexible)
```bash
# System default
FVM_DIR="${FVM_DIR:-/opt/fvm}"
SYMLINK_TARGET="${SYMLINK_TARGET:-/usr/local/bin/fvm}"

# User override
FVM_DIR="${FVM_DIR:-$HOME/.fvm_flutter}"
SYMLINK_TARGET="${SYMLINK_TARGET:-$HOME/.local/bin/fvm}"
```
**Pros**: Supports both single-user and multi-user scenarios
**Cons**: More complex, requires clear documentation

### Option 4: Package Manager Integration
- Homebrew (macOS): `brew install fvm`
- APT (Debian/Ubuntu): `apt install fvm`
- DNF (Fedora/RHEL): `dnf install fvm`
- Arch AUR: `yay -S fvm`

**Pros**: Follows distribution conventions, proper multi-user support
**Cons**: Requires package maintenance, slower updates

---

## Impact Assessment

### Affected User Scenarios

| Scenario | Current Behavior | Issue Severity |
|----------|------------------|----------------|
| **Single-user desktop** | Works (requires sudo once) | Low - Annoying but functional |
| **Multi-user server** | First user "owns" system FVM | **Critical** - Security/reliability risk |
| **Corporate workstation** | May fail if no sudo access | **High** - Installation blocked |
| **CI/Container** | Requires `FVM_ALLOW_ROOT=true` | Medium - Workaround exists |
| **Managed systems (Nix, etc.)** | May conflict with package manager | **High** - May break system |
| **NFS/CIFS home mounts** | Unreliable (network dependency) | **High** - Random failures |

### Security Implications

**CWE-668: Exposure of Resource to Wrong Sphere**
> The product exposes a resource to the wrong control sphere, providing unintended actors with inappropriate access to the resource.

Alice's home directory (user sphere) is exposed to system-wide execution (system sphere).

**CWE-362: Concurrent Execution using Shared Resource with Improper Synchronization**
> The program contains a code sequence that can run concurrently with other code, and it uses a shared resource that is accessible across multiple users/processes, but the program does not properly synchronize the resource.

Multiple users can install/uninstall concurrently, causing race conditions on the shared symlink.

---

## Historical Context & Evolution

### Timeline of Permission-Related Fixes

From `/Users/leofarias/Projects/fvm/issue-triage/install_permission_issues/install_sh_issue_overview.md`:

1. **March 2024 (#699)**: Original issue reported - "requires sudo privileges"
2. **March 2024 (#700)**: PR adds PATH automation - doesn't fix root cause
3. **September 2024 (#785)**: sudo issue persists - files under `/root/.fvm`
4. **November 2024 (#796)**: Pop!_OS - symlink permission failure
5. **January 2025 (#816)**: macOS 15.3 - `/usr/local/bin` doesn't exist
6. **March 2025 (#830)**: PR adds `SYMLINK_DIR` variable - partial mitigation
7. **June 2025 (#862)**: Major refactor - adds security checks
8. **June 2025 (#864)**: Root block breaks CI - regression
9. **September 2025 (#907-909)**: Multiple robustness PRs
10. **September 2025 (#932)**: Install script v3.0.0 - still uses same architecture

**Observation**: Despite 17+ issues and PRs addressing install script problems, the **fundamental architecture** has not changed. All fixes have been **mitigation strategies**, not architectural solutions.

---

## Code References Summary

### install.sh Key Lines

| Line(s) | Code | Issue |
|---------|------|-------|
| 24 | `FVM_DIR="$HOME/.fvm_flutter"` | User-specific path for system-wide tool |
| 26 | `SYMLINK_TARGET="/usr/local/bin/fvm"` | Hardcoded system path |
| 109-117 | `ESCALATION_TOOL` detection | Requires sudo/doas |
| 120-129 | `create_symlink()` | Uses sudo for system symlink |
| 156 | `readlink "$SYMLINK_TARGET" == *"fvm"*` | Weak heuristic, false positives |
| 169 | `rm -rf "$FVM_DIR"` | User-specific cleanup |
| 176 | `remove_symlink "$SYMLINK_TARGET"` | System-wide impact |
| 336-346 | Create `/usr/local/bin` if missing | Still requires sudo |
| 414-415 | `create_symlink "$FVM_DIR_BIN/fvm" "$SYMLINK_TARGET"` | Links user dir to system path |

### uninstall.sh Key Lines

| Line(s) | Code | Issue |
|---------|------|-------|
| 17-18 | `FVM_DIR="$HOME/.fvm_flutter"` | Only removes current user's dir |
| 22-25 | `rm -rf "$FVM_DIR"` | Doesn't remove symlink |
| 30-33 | Check if `fvm` command exists | Doesn't validate ownership |

---

## Validation Status

| Concern | Status | Evidence | Severity |
|---------|--------|----------|----------|
| **1. Cross-user weirdness** | ✅ VALID | Lines 24, 26, 414-415 | **Critical** |
| **2. Permissions & sudo friction** | ✅ VALID | Lines 109-129, 294-299 | **High** |
| **3. Uninstall semantics** | ✅ VALID | Lines 156, 176 + uninstall.sh | **High** |
| **4. Home directory dependence** | ✅ VALID | Line 24 hardcoded to `$HOME` | **Medium** |

---

## Recommendations for Triage

### Priority Classification
**P1 - High Priority**

**Rationale**:
- Affects multi-user systems (servers, shared workstations)
- Security implications (CWE-668, CWE-362)
- Long-standing issue (17+ related issues since March 2024)
- Architectural flaw, not isolated bug

### Suggested Actions

1. **Validate with Leo**:
   - Confirm intended use case (single-user vs multi-user)
   - Decide on architectural direction (see Options 1-4 above)
   - Determine breaking change tolerance

2. **Document Current Limitations**:
   - Add prominent warning in installation docs
   - Clarify multi-user behavior in README
   - Document workarounds for affected scenarios

3. **Long-term Solution**:
   - Design RFC for installation architecture v2
   - Consider package manager distribution
   - Evaluate user-local-only installation default

4. **Short-term Mitigation**:
   - Improve uninstall script to check symlink ownership
   - Add `--user-only` flag for user-local installation
   - Enhance documentation for multi-user environments

### Related Issues to Cross-Reference
- #699, #700, #785, #796, #816, #818, #830, #832, #857, #862, #864, #907, #908, #909, #932, #946, #949

---

## Conclusion

Issue #974 accurately identifies a **fundamental architectural problem** with FVM's installation model. All four concerns are **technically valid and well-founded**:

1. ✅ **Cross-user security risk** - User home dependencies for system tools
2. ✅ **Permission friction** - Mixed privilege requirements
3. ✅ **Unsafe uninstall** - System-wide impact from user actions
4. ✅ **Home directory coupling** - Brittle path dependencies

This is **not a bug to fix** but an **architecture to redesign**. The current model works acceptably for single-user desktop installations but fundamentally breaks Unix/Linux multi-user security principles.

**Recommendation**: Classify as **P1-High**, engage with Leo for architectural direction, and consider breaking changes in FVM 5.0.

---

**Analysis Date**: December 8, 2025
**Analyst**: Code Agent
**Files Analyzed**:
- `/Users/leofarias/Projects/fvm/scripts/install.sh`
- `/Users/leofarias/Projects/fvm/scripts/uninstall.sh`
- `/Users/leofarias/Projects/fvm/issue-triage/install_permission_issues/install_sh_issue_overview.md`

**Issue URL**: https://github.com/leoafarias/fvm/issues/974
