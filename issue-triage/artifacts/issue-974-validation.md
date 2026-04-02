# Issue #974: [BUG] Put the binary in a user directory, then expose it via a system-wide symlink will create many issues

## Metadata
- **Reporter**: zhengpenghou
- **Created**: 2025-11-15
- **Reported Version**: Not specified (install script issue)
- **Issue Type**: bug/architectural
- **URL**: https://github.com/leoafarias/fvm/issues/974

## Problem Summary
The install script places the FVM binary in a user-specific directory (`$HOME/.fvm_flutter`) but creates a system-wide symlink (`/usr/local/bin/fvm`). This architectural pattern creates four distinct problems:
1. Cross-user security concerns (User B executes code from User A's home)
2. Unnecessary sudo requirement for per-user installs
3. Confusing uninstall semantics in multi-user environments
4. Fragile home directory dependency for system binary

## Version Context
- Reported against: install script (scripts/install.sh)
- Current version: v4.0.0
- Version-specific: No - affects all versions using current install script
- Reason: Architectural issue in install script, not version-dependent

## Validation Steps
1. Analyzed install script architecture at `scripts/install.sh`
2. Compared with industry standards (rustup, nvm, npm, Homebrew)
3. Reviewed XDG Base Directory Specification for user-local binaries
4. Cross-referenced with existing install permission issues (#699, #785, #832, etc.)

## Evidence

**Install Script Architecture (scripts/install.sh):**
```bash
# Line 24: Binary location in user home
FVM_DIR="$HOME/.fvm_flutter"

# Line 26: System-wide symlink target
SYMLINK_TARGET="/usr/local/bin/fvm"
```

**Symlink Creation Requiring Sudo (lines 109-129):**
```bash
create_symlink() {
  local source="$1"
  local target="$2"

  if [[ "$IS_ROOT" == "true" ]]; then
    ln -sf "$source" "$target"
  else
    "$ESCALATION_TOOL" ln -sf "$source" "$target"  # Requires sudo
  fi
}
```

**Files/Code References:**
- [scripts/install.sh:24](../scripts/install.sh#L24) - FVM_DIR definition
- [scripts/install.sh:26](../scripts/install.sh#L26) - SYMLINK_TARGET definition
- [scripts/install.sh:109-129](../scripts/install.sh#L109-L129) - Symlink creation with sudo
- [scripts/install.sh:143-190](../scripts/install.sh#L143-L190) - Uninstall logic

## Current Status in v4.0.0
- [x] Still reproducible
- [ ] Already fixed
- [ ] Not applicable to v4.0.0
- [ ] Needs more information
- [ ] Cannot reproduce

## Troubleshooting/Implementation Plan

### Root Cause Analysis
The install script mixes two incompatible installation paradigms:
1. **Per-user install**: Binary stored in `$HOME/.fvm_flutter`
2. **System-wide access**: Symlink in `/usr/local/bin`

This creates a hybrid that inherits the drawbacks of both approaches:
- Requires sudo (system-wide drawback)
- Still user-specific (per-user drawback)
- Cross-user security exposure
- Fragile on home directory changes

**Industry Standard Violation**: No major CLI tool (rustup, nvm, npm, Homebrew) uses this pattern. Tools either:
- Install fully per-user (`~/.local/bin`, no sudo) - nvm, npm
- Install fully system-wide (`/opt`, `/usr/local`, requires sudo) - rustup multi-user

### Proposed Solution

**Option 1: Pure Per-User Install (Recommended)**
```bash
FVM_DIR="$HOME/.local/share/fvm"      # Data/binaries (XDG compliant)
FVM_BIN="$HOME/.local/bin"            # User executables
# No sudo required
# Add $HOME/.local/bin to PATH
```

Implementation steps:
1. Change `FVM_DIR` to `$HOME/.local/share/fvm` (XDG DATA)
2. Change symlink target to `$HOME/.local/bin/fvm`
3. Remove sudo/doas requirement entirely
4. Add PATH configuration guidance for `~/.local/bin`
5. Update uninstall to only remove user-local files

**Option 2: System-Wide Install (For Containers/CI)**
```bash
FVM_DIR="/opt/fvm"                    # System location
FVM_BIN="/opt/fvm/bin"
# Symlink: /usr/local/bin/fvm -> /opt/fvm/bin/fvm
# Requires sudo for installation
```

### Alternative Approaches
- **Hybrid with ENV detection**: Default to per-user, allow `FVM_SYSTEM_INSTALL=1` for system-wide
- **Package manager distribution**: Rely on Homebrew/APT/Winget for system installs
- **PR #967** already in progress: Implements user-local default installation

### Dependencies & Risks
- **Breaking change**: Users with existing `/usr/local/bin/fvm` symlinks will need migration
- **PATH configuration**: Users must have `~/.local/bin` in PATH
- **Multi-user scenarios**: System-wide option needed for shared servers/containers
- **Related PRs**: #967 (installer v2) already addresses this

### Related Code Locations
- [scripts/install.sh](../scripts/install.sh) - Main install script
- [scripts/uninstall.sh](../scripts/uninstall.sh) - Uninstall script
- [docs/pages/documentation/getting-started/installation.md](../docs/pages/documentation/getting-started/installation.md) - Installation docs

## Recommendation
**Action**: validate-p1

**Reason**: Architecturally valid security and usability concern. Violates industry best practices. Already being addressed by PR #967 which implements user-local default installation. Should be tracked until PR #967 merges.

## Notes
- **17+ related issues** since March 2024 trace back to this architectural decision (#699, #785, #796, #816, #832, #864, etc.)
- **PR #967** (installer v2, user-local default) directly addresses this issue
- **Security classifications**: CWE-668 (Wrong Sphere), CWE-362 (Race Conditions)
- Issue accurately identifies problems that work "acceptably" only for single-user desktop installs
- XDG Base Directory Specification recommends `$HOME/.local/bin` for user executables

---
**Validated by**: Code Agent
**Date**: 2025-12-08
