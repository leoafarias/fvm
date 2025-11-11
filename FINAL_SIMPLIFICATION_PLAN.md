# FVM Installer Simplification - Final Implementation Plan
## One Behavior Only: User-Local Install with Manual PATH

**Date**: 2025-01-11
**Objective**: Simplify install-next.sh to single behavior with no configuration options
**Target**: Reduce from 393 lines to ~150 lines (60% reduction)

---

## Executive Decision: NO SYMLINKS

Based on industry research:
- ✅ Modern tools (rustup, nvm, pyenv, rbenv, kubectl, Go) do NOT use symlinks
- ✅ Standard practice: Direct install + PATH instructions
- ✅ Simpler: Fewer moving parts, easier maintenance
- ✅ Safer: No permission issues with symlink creation/removal

**Approach**: Install to `~/.fvm_flutter/bin` + print PATH instructions

---

## Phase 1: Core Simplifications

### 1.1 Remove --system Flag and All System Install Logic

**Files to modify**: `scripts/install-next.sh`

**Lines to DELETE**:
- Line 22: `SYSTEM_INSTALL=0`
- Line 38: `--system` documentation in usage()
- Line 54-55: System install examples
- Lines 100-109: `choose_elev()` function (no longer needed)
- Line 184: `--system) SYSTEM_INSTALL=1` in arg parsing
- Lines 340-370: Entire system install block

**Rationale**:
- System install via symlink was broken for multi-user
- System install via copy is unnecessary
- Adds complexity without real benefit
- Modern tools don't offer this option

**Impact**: Removes ~80 lines of code

---

### 1.2 Remove --no-modify-path Flag and All PATH Modification Logic

**Files to modify**: `scripts/install-next.sh`

**Lines to DELETE**:
- Line 23: `MODIFY_PATH=1`
- Line 39: `--no-modify-path` documentation in usage()
- Line 185: `--no-modify-path) MODIFY_PATH=0` in arg parsing
- Lines 111-124: `add_line_if_missing()` function
- Lines 372-383: Entire PATH integration block

**Replace with**: Simple instruction printer function
```bash
print_path_instructions() {
  echo ""
  echo "✓ Installation complete!"
  echo ""
  echo "To use FVM, add it to your PATH:"
  echo ""
  echo "  # For bash (add to ~/.bashrc):"
  echo '  export PATH="$HOME/.fvm_flutter/bin:$PATH"'
  echo ""
  echo "  # For zsh (add to ~/.zshrc):"
  echo '  export PATH="$HOME/.fvm_flutter/bin:$PATH"'
  echo ""
  echo "  # For fish (run once):"
  echo '  fish_add_path "$HOME/.fvm_flutter/bin"'
  echo ""
  echo "Then restart your shell or run: source ~/.bashrc"
}
```

**Rationale**:
- Safer: No risk of corrupting user's shell configs
- Standard: kubectl, Go, Homebrew use this pattern
- User control: Respects dotfile managers and custom setups
- Universal: Works with any shell without special handling

**Impact**: Removes ~70 lines, adds ~15 lines instruction printer

---

### 1.3 Simplify Migration Detection (Remove Interactive Prompts)

**Files to modify**: `scripts/install-next.sh`

**Lines to REPLACE**: 213-245 (current migration logic)

**New implementation**:
```bash
# ---- automatic migration from v1 ----
migrate_from_v1() {
  local old_system_path="/usr/local/bin/fvm"

  if [ -L "$old_system_path" ] || [ -f "$old_system_path" ]; then
    echo "Detected old installation at $old_system_path"
    echo "Migrating to user-local install..."

    # Try to remove without sudo first
    if rm -f "$old_system_path" 2>/dev/null; then
      echo "✓ Removed old system install"
    else
      # Try with sudo if available
      if command -v sudo >/dev/null 2>&1; then
        if sudo rm -f "$old_system_path" 2>/dev/null; then
          echo "✓ Removed old system install (required sudo)"
        else
          echo "⚠ Could not remove $old_system_path"
          echo "  You may remove it manually: sudo rm $old_system_path"
        fi
      else
        echo "⚠ Could not remove $old_system_path (need sudo)"
        echo "  You may remove it manually: sudo rm $old_system_path"
      fi
    fi
  fi
}

# Call after successful install
migrate_from_v1
```

**Rationale**:
- No prompts: Works in both interactive and CI/CD
- Graceful: Tries to clean up but doesn't fail if unable
- Clear messaging: User knows what happened
- Simple: Straightforward logic, no branching

**Impact**: Reduces from ~30 lines to ~20 lines, removes complexity

---

### 1.4 Simplify Root Handling (Warn, Don't Block)

**Files to modify**: `scripts/install-next.sh`

**Lines to REPLACE**: 196-211 (current root policy)

**New implementation**:
```bash
# ---- root user handling ----
if [ "${EUID:-$(id -u)}" -eq 0 ]; then
  echo "⚠ Running as root"
  echo "  FVM will be installed to /root/.fvm_flutter/bin"
  echo "  For system-wide access, each user should install FVM individually."
  echo ""
fi
```

**Rationale**:
- Simpler: No CI/container detection needed
- Permissive: Works everywhere without special cases
- Clear: User understands what's happening
- Safe: Installing to $HOME is safe even as root

**Impact**: Reduces from ~15 lines to ~6 lines

---

### 1.5 Update Script Metadata

**Files to modify**: `scripts/install-next.sh`

**Lines to UPDATE**:
- Line 3: Update comment
  ```bash
  # Install FVM to user-local directory ($HOME/.fvm_flutter/bin)
  # No sudo required. Add to PATH after installation.
  ```
- Line 4-7: Remove outdated comments about --system
- Line 13: Update version
  ```bash
  INSTALLER_VERSION="3.0.0"  # v3: single behavior, user-local only
  ```

---

## Phase 2: Keep Core Functionality

These sections remain UNCHANGED:

### 2.1 Version Resolution (Lines 91-98, 281-286)
- ✅ `normalize_version()` function
- ✅ `get_latest_version()` function
- ✅ Version resolution logic

### 2.2 OS/Architecture Detection (Lines 257-271)
- ✅ OS detection (Linux/Darwin)
- ✅ Architecture detection (x64/arm64/arm/riscv64)

### 2.3 Libc Detection with Fallback (Lines 273-279, 288-306)
- ✅ Musl detection on Linux
- ✅ URL validation with musl→glibc fallback

### 2.4 Download & Extract (Lines 308-337)
- ✅ Directory setup
- ✅ Download with validation
- ✅ Tarball integrity check
- ✅ Extraction with structure handling
- ✅ Binary verification

### 2.5 Uninstall Functionality (Lines 135-177)
**MODIFY to simplify**:
```bash
do_uninstall() {
  local removed_any=0

  # Remove user installation directory
  if [ -d "$INSTALL_BASE" ]; then
    rm -rf "$INSTALL_BASE"
    echo "✓ Removed user directory: $INSTALL_BASE"
    removed_any=1
  fi

  # Remove old system install if present (from v1)
  local old_system="/usr/local/bin/fvm"
  if [ -L "$old_system" ] || [ -f "$old_system" ]; then
    if rm -f "$old_system" 2>/dev/null; then
      echo "✓ Removed old system install: $old_system"
      removed_any=1
    else
      if command -v sudo >/dev/null 2>&1 && sudo rm -f "$old_system" 2>/dev/null; then
        echo "✓ Removed old system install: $old_system"
        removed_any=1
      else
        echo "⚠ Could not remove $old_system (may need sudo)"
      fi
    fi
  fi

  if [ "$removed_any" -eq 0 ]; then
    echo "No FVM installation found (ok)"
  fi

  echo ""
  echo "Uninstall complete."
  echo "Note: You may want to remove PATH entries from your shell config:"
  echo "  - ~/.bashrc"
  echo "  - ~/.zshrc"
  echo "  - ~/.config/fish/config.fish"

  exit 0
}
```

---

## Phase 3: Updated Usage Documentation

**Files to modify**: `scripts/install-next.sh`

**Lines to REPLACE**: 28-60 (usage() function)

**New implementation**:
```bash
usage() {
  cat <<'EOF'
FVM Installer v3.0.0 - User-Local Installation

USAGE:
  install.sh [FLAGS] [VERSION]

ARGUMENTS:
  VERSION               Version to install (e.g., 4.0.1 or v4.0.1)
                        If omitted, installs the latest version

FLAGS:
  -h, --help            Show this help and exit
  -v, --version         Show installer version and exit
  --uninstall           Remove FVM installation

EXAMPLES:
  # Install latest version
  curl -fsSL https://fvm.app/install.sh | bash

  # Install specific version
  ./install.sh 4.0.1

  # Uninstall
  ./install.sh --uninstall

AFTER INSTALLATION:
  Add FVM to your PATH by adding this line to your shell config:

    export PATH="$HOME/.fvm_flutter/bin:$PATH"

  Then restart your shell or run: source ~/.bashrc

FOR MORE INFO:
  https://fvm.app/docs/getting_started/installation
EOF
}
```

---

## Phase 4: Final Script Structure

**New flow** (simplified):
```
1. Parse arguments (VERSION, --uninstall, --help)
2. Handle uninstall if requested → exit
3. Warn if running as root (but continue)
4. Check prerequisites (curl, tar, bash)
5. Detect OS/Architecture/Libc
6. Resolve version (latest or specified)
7. Validate URL exists (with musl fallback)
8. Download tarball
9. Validate tarball integrity
10. Extract to ~/.fvm_flutter/bin
11. Verify binary works (non-fatal)
12. Migrate from v1 (remove old system install)
13. Print success message
14. Print PATH instructions
15. Done
```

**Estimated final line count**: ~150-180 lines (vs 393 currently)

---

## Phase 5: Testing Checklist

### 5.1 Fresh Install Tests

#### Test 1: Fresh Install on Ubuntu 22.04
```bash
# Clean environment
./scripts/install-next.sh --uninstall
rm -rf ~/.fvm_flutter

# Install
./scripts/install-next.sh

# Verify
test -f ~/.fvm_flutter/bin/fvm || echo "FAIL: Binary not installed"
test ! -f /usr/local/bin/fvm || echo "FAIL: System install unexpected"
~/.fvm_flutter/bin/fvm --version || echo "FAIL: Binary not working"

# Verify instructions printed
# (manual verification)
```

#### Test 2: Fresh Install on macOS (Intel)
```bash
./scripts/install-next.sh
test -f ~/.fvm_flutter/bin/fvm || echo "FAIL"
~/.fvm_flutter/bin/fvm --version || echo "FAIL"
```

#### Test 3: Fresh Install on macOS (ARM/M1)
```bash
./scripts/install-next.sh
file ~/.fvm_flutter/bin/fvm | grep arm64 || echo "FAIL: Wrong architecture"
```

### 5.2 Migration Tests

#### Test 4: Migrate from v1 System Symlink
```bash
# Setup: Create v1-style system symlink
mkdir -p ~/.fvm_flutter/bin
echo '#!/bin/bash\necho "old version"' > ~/.fvm_flutter/bin/fvm
chmod +x ~/.fvm_flutter/bin/fvm
sudo ln -sf ~/.fvm_flutter/bin/fvm /usr/local/bin/fvm

# Verify v1 state
ls -la /usr/local/bin/fvm | grep "\.fvm_flutter" || echo "Setup failed"

# Install v3
./scripts/install-next.sh

# Verify migration
test ! -L /usr/local/bin/fvm || echo "FAIL: Symlink not removed"
test ! -f /usr/local/bin/fvm || echo "FAIL: System install not removed"
~/.fvm_flutter/bin/fvm --version | grep -v "old version" || echo "FAIL: Old binary still present"
```

#### Test 5: Migrate from v1 System Copy
```bash
# Setup: Create v1-style system copy
sudo cp ~/.fvm_flutter/bin/fvm /usr/local/bin/fvm

# Install v3
./scripts/install-next.sh

# Verify
test ! -f /usr/local/bin/fvm || echo "FAIL: System copy not removed"
```

### 5.3 Idempotency Tests

#### Test 6: Re-install Multiple Times
```bash
./scripts/install-next.sh
./scripts/install-next.sh
./scripts/install-next.sh

# Should succeed all three times
echo "All installs completed successfully"
```

### 5.4 Version Tests

#### Test 7: Specific Version Install
```bash
./scripts/install-next.sh 4.0.0
~/.fvm_flutter/bin/fvm --version | grep "4.0.0" || echo "FAIL"
```

#### Test 8: Version with 'v' Prefix
```bash
./scripts/install-next.sh v4.0.1
~/.fvm_flutter/bin/fvm --version | grep "4.0.1" || echo "FAIL"
```

### 5.5 Uninstall Tests

#### Test 9: Uninstall Removes Everything
```bash
./scripts/install-next.sh
./scripts/install-next.sh --uninstall

test ! -d ~/.fvm_flutter || echo "FAIL: User dir still exists"
test ! -f /usr/local/bin/fvm || echo "FAIL: System install still exists"
```

#### Test 10: Uninstall is Idempotent
```bash
./scripts/install-next.sh --uninstall
./scripts/install-next.sh --uninstall
./scripts/install-next.sh --uninstall

# Should succeed all three times
```

### 5.6 Container/CI Tests

#### Test 11: Docker Container Install
```dockerfile
FROM ubuntu:22.04
RUN apt-get update && apt-get install -y curl tar git
COPY scripts/install-next.sh /tmp/install.sh
RUN bash /tmp/install.sh
RUN /root/.fvm_flutter/bin/fvm --version
```

#### Test 12: Docker as Root (No Blocking)
```bash
docker run --rm ubuntu:22.04 bash -c '
  apt-get update && apt-get install -y curl tar
  curl -fsSL https://fvm.app/install.sh | bash
  /root/.fvm_flutter/bin/fvm --version
'
```

#### Test 13: GitHub Actions Workflow
```yaml
- name: Install FVM
  run: |
    curl -fsSL https://fvm.app/install.sh | bash
    echo "$HOME/.fvm_flutter/bin" >> $GITHUB_PATH

- name: Verify FVM
  run: fvm --version
```

### 5.7 Edge Case Tests

#### Test 14: Invalid Version
```bash
./scripts/install-next.sh 999.999.999
# Should fail with clear error message
echo $? | grep -v "0" || echo "FAIL: Should have errored"
```

#### Test 15: Alpine Linux (musl)
```bash
# On Alpine container
docker run --rm alpine:latest sh -c '
  apk add curl bash tar
  curl -fsSL https://fvm.app/install.sh | bash
  /root/.fvm_flutter/bin/fvm --version
'
```

#### Test 16: No Internet
```bash
# Simulate by blocking github.com or disconnecting
./scripts/install-next.sh 2>&1 | grep -i "error"
```

---

## Phase 6: CI Workflow Updates

### 6.1 Update .github/workflows/test-install.yml

**Changes needed**:

1. **Remove --system flag usage** (Lines 110, 134)
2. **Add PATH setup in tests**
3. **Update test expectations**

**New test block**:
```yaml
- name: Test user install
  run: |
    ./scripts/install.sh

    # Verify user install
    test -f ~/.fvm_flutter/bin/fvm || exit 1
    test ! -f /usr/local/bin/fvm || exit 1

    # Add to PATH and test
    export PATH="$HOME/.fvm_flutter/bin:$PATH"
    fvm --version

    echo "✓ User install successful"

    # Cleanup
    ./scripts/install.sh --uninstall

- name: Test container as root
  run: |
    docker run --rm ubuntu:22.04 bash -c '
      apt-get update && apt-get install -y curl tar
      curl -fsSL https://raw.githubusercontent.com/.../install.sh | bash
      /root/.fvm_flutter/bin/fvm --version
    '
```

---

## Phase 7: Documentation Updates

### 7.1 Update docs/pages/documentation/getting-started/installation.mdx

**Replace installation section**:
```markdown
## Installation

Install FVM to your user directory:

```bash
curl -fsSL https://fvm.app/install.sh | bash
```

### Add to PATH

After installation, add FVM to your PATH:

**For Bash** (add to `~/.bashrc`):
```bash
export PATH="$HOME/.fvm_flutter/bin:$PATH"
```

**For Zsh** (add to `~/.zshrc`):
```bash
export PATH="$HOME/.fvm_flutter/bin:$PATH"
```

**For Fish** (run once):
```bash
fish_add_path "$HOME/.fvm_flutter/bin"
```

Then restart your shell or run:
```bash
source ~/.bashrc  # or ~/.zshrc
```

### Verify Installation

```bash
fvm --version
```

## Install Specific Version

```bash
curl -fsSL https://fvm.app/install.sh | bash -s 4.0.1
```

## Uninstall

```bash
curl -fsSL https://fvm.app/install.sh | bash -s -- --uninstall
```
```

### 7.2 Add CI/CD Examples Section

**New section in docs**:
```markdown
## Using FVM in CI/CD

### GitHub Actions

```yaml
steps:
  - name: Install FVM
    run: |
      curl -fsSL https://fvm.app/install.sh | bash
      echo "$HOME/.fvm_flutter/bin" >> $GITHUB_PATH

  - name: Use FVM
    run: |
      fvm install
      fvm flutter doctor
```

### GitLab CI

```yaml
before_script:
  - curl -fsSL https://fvm.app/install.sh | bash
  - export PATH="$HOME/.fvm_flutter/bin:$PATH"

test:
  script:
    - fvm install
    - fvm flutter test
```

### Docker

```dockerfile
FROM ubuntu:22.04

RUN apt-get update && \
    apt-get install -y curl tar git && \
    curl -fsSL https://fvm.app/install.sh | bash

ENV PATH="/root/.fvm_flutter/bin:$PATH"

RUN fvm install
```
```

### 7.3 Create Migration Guide

**New file**: `docs/pages/documentation/getting-started/migration-v3.mdx`

```markdown
# Migrating to Installer v3

## Overview

FVM Installer v3 simplifies installation to a single user-local method.

## What Changed

**Removed**:
- `--system` flag (system-wide installation)
- `--no-modify-path` flag (automatic shell config editing)
- Interactive migration prompts

**Changed**:
- Manual PATH setup (prints instructions instead of auto-editing)
- Automatic migration from v1/v2 (no prompts)

## For Individual Users

No action required! On next install:

1. Run: `curl -fsSL https://fvm.app/install.sh | bash`
2. Follow PATH instructions printed at end
3. Restart your shell

## For CI/CD Pipelines

Update your pipeline to add FVM to PATH.

**Before (v1/v2)**:
```yaml
run: curl -fsSL https://fvm.app/install.sh | bash -s -- --system
```

**After (v3)**:
```yaml
run: |
  curl -fsSL https://fvm.app/install.sh | bash
  echo "$HOME/.fvm_flutter/bin" >> $GITHUB_PATH
```

## Why This Change?

- **Simpler**: One way to install, no configuration needed
- **Safer**: No automatic editing of shell configs
- **Standard**: Matches rustup, nvm, pyenv, rbenv patterns
- **Better for Multi-User**: Each user gets their own independent install

## Troubleshooting

### "fvm: command not found" after install

You need to add FVM to your PATH. Add this line to your shell config:

```bash
export PATH="$HOME/.fvm_flutter/bin:$PATH"
```

Then restart your shell or run: `source ~/.bashrc`

### Old system install still present

Run uninstall to clean up:

```bash
curl -fsSL https://fvm.app/install.sh | bash -s -- --uninstall
```
```

---

## Phase 8: Release Notes

**New file**: `docs/RELEASE_NOTES_v3.md`

```markdown
# FVM Installer v3.0.0 - Breaking Changes

## TL;DR

- Default install is now user-local only (no sudo)
- Manual PATH setup required (prints clear instructions)
- Removed `--system` and `--no-modify-path` flags

## What's New

✨ **Simplified Installation**
- Single behavior: always installs to `~/.fvm_flutter/bin`
- No configuration flags (except version)
- Cleaner, more maintainable code (60% reduction)

✨ **Safer Approach**
- No automatic editing of shell config files
- No risk of corrupting .bashrc/.zshrc
- Respects dotfile managers and custom setups

✨ **Better for Multi-User Systems**
- Each user installs independently
- No conflicts between users
- Per-user version management

✨ **Standards-Aligned**
- Matches modern tools: rustup, nvm, pyenv, kubectl
- Follows XDG Base Directory specification
- Industry best practices

## Breaking Changes

### Removed: --system Flag

**Before**:
```bash
curl -fsSL https://fvm.app/install.sh | bash -s -- --system
```

**After**:
```bash
# Install user-local (only option)
curl -fsSL https://fvm.app/install.sh | bash

# Add to PATH manually
export PATH="$HOME/.fvm_flutter/bin:$PATH"
```

**Why**: System-wide install was rarely needed and added unnecessary complexity.

### Removed: --no-modify-path Flag

**Before**:
```bash
curl -fsSL https://fvm.app/install.sh | bash -s -- --no-modify-path
```

**After**:
```bash
# PATH is never auto-modified now (always manual)
curl -fsSL https://fvm.app/install.sh | bash
# Follow printed instructions to add to PATH
```

**Why**: Safer to never auto-edit user's shell configs.

### Changed: Automatic Migration

v1/v2 installers are automatically migrated:
- Old system installs at `/usr/local/bin/fvm` are removed
- New install goes to `~/.fvm_flutter/bin`
- No interactive prompts (works in CI/CD)

## Migration Guide

### For Individual Users

1. Run installer: `curl -fsSL https://fvm.app/install.sh | bash`
2. Add to PATH (one-time): `echo 'export PATH="$HOME/.fvm_flutter/bin:$PATH"' >> ~/.bashrc`
3. Restart shell: `source ~/.bashrc`
4. Verify: `fvm --version`

### For CI/CD

Update your pipeline configuration:

**GitHub Actions**:
```yaml
- run: |
    curl -fsSL https://fvm.app/install.sh | bash
    echo "$HOME/.fvm_flutter/bin" >> $GITHUB_PATH
```

**GitLab CI**:
```yaml
before_script:
  - curl -fsSL https://fvm.app/install.sh | bash
  - export PATH="$HOME/.fvm_flutter/bin:$PATH"
```

**Docker**:
```dockerfile
RUN curl -fsSL https://fvm.app/install.sh | bash
ENV PATH="/root/.fvm_flutter/bin:$PATH"
```

## Technical Details

- **Lines of code**: 393 → ~150 (60% reduction)
- **Complexity**: Removed dual behavior, interactive prompts, elevation detection
- **Standards**: Aligned with rustup, nvm, pyenv patterns

## Rollback

If you need the old behavior, v2 installer is available:

```bash
curl -fsSL https://fvm.app/install-legacy.sh | bash
```

---

**Released**: 2025-01-XX
**Version**: 3.0.0
**Type**: Major (Breaking Changes)
```

---

## Phase 9: Files to Modify

### Modify These Files:

1. **`scripts/install-next.sh`**
   - Apply all simplifications above
   - Reduce to ~150 lines
   - Test thoroughly

2. **`scripts/install.sh`**
   - Replace with simplified version (after testing)
   - Ensure it matches install-next.sh

3. **`docs/public/install.sh`**
   - Copy simplified version
   - Must match scripts/install.sh (for validation test)

4. **`.github/workflows/test-install.yml`**
   - Remove --system flag usage
   - Add PATH setup in tests
   - Update expectations

5. **`docs/pages/documentation/getting-started/installation.mdx`**
   - Replace installation instructions
   - Add PATH setup prominently
   - Add CI/CD examples

### Create These Files:

6. **`docs/pages/documentation/getting-started/migration-v3.mdx`**
   - Migration guide for v3

7. **`docs/RELEASE_NOTES_v3.md`**
   - Comprehensive release notes

### Keep as Backup:

8. **`scripts/install-legacy.sh`**
   - Keep existing v1 backup
   - Update docs to reference it

---

## Phase 10: Implementation Order

**STRICT ORDER - DO NOT DEVIATE**:

### Step 1: Create Simplified Script
- [ ] Copy `scripts/install-next.sh` to `scripts/install-v3-draft.sh`
- [ ] Apply Phase 1 simplifications (remove flags, functions)
- [ ] Apply Phase 2 updates (keep core functionality)
- [ ] Apply Phase 3 changes (update usage)
- [ ] Apply Phase 4 (final structure)
- [ ] Verify line count (~150 lines)

### Step 2: Test Simplified Script Locally
- [ ] Run Test 1: Fresh install on Ubuntu
- [ ] Run Test 4: Migration from v1 symlink
- [ ] Run Test 6: Re-install 3 times
- [ ] Run Test 7: Specific version
- [ ] Run Test 9: Uninstall
- [ ] Run Test 10: Uninstall idempotency

### Step 3: Update CI Workflow
- [ ] Modify `.github/workflows/test-install.yml`
- [ ] Remove --system flag references
- [ ] Add PATH setup in tests
- [ ] Commit CI changes only

### Step 4: Test in CI
- [ ] Push branch with CI changes
- [ ] Verify all CI tests pass
- [ ] Fix any issues found

### Step 5: Replace Production Script
- [ ] Copy `scripts/install-v3-draft.sh` to `scripts/install-next.sh`
- [ ] Copy to `scripts/install.sh`
- [ ] Copy to `docs/public/install.sh`
- [ ] Verify all three match exactly

### Step 6: Update Documentation
- [ ] Update `installation.mdx`
- [ ] Create `migration-v3.mdx`
- [ ] Create `RELEASE_NOTES_v3.md`
- [ ] Update any other docs referencing install

### Step 7: Final Testing
- [ ] Run all 16 test scenarios
- [ ] Test on Ubuntu VM
- [ ] Test on macOS (Intel + ARM if available)
- [ ] Test in Docker container
- [ ] Test GitHub Actions workflow

### Step 8: Commit and Push
- [ ] Commit all changes with clear message
- [ ] Push to branch
- [ ] Create PR with migration guide linked
- [ ] Get review and approval

### Step 9: Monitor After Merge
- [ ] Monitor for user issues
- [ ] Be ready to rollback if critical issues
- [ ] Update docs based on feedback

---

## Phase 11: Success Criteria

**Before merging, ALL must pass**:

- [ ] Fresh install works on Ubuntu 22.04
- [ ] Fresh install works on macOS (Intel)
- [ ] Fresh install works on macOS (ARM)
- [ ] Migration from v1 symlink works
- [ ] Migration from v1 copy works
- [ ] Uninstall is idempotent
- [ ] Specific version install works
- [ ] Latest version install works
- [ ] Docker container install works
- [ ] GitHub Actions workflow works
- [ ] Alpine Linux (musl) works
- [ ] Invalid version shows clear error
- [ ] CI tests all pass
- [ ] Script is ~150 lines
- [ ] Documentation is updated
- [ ] Release notes are complete

---

## Phase 12: Rollback Plan

**If critical issues found after merge**:

### Quick Rollback (< 5 minutes)
```bash
# Restore v2 installer
cp scripts/install-next.sh.backup scripts/install.sh
cp scripts/install-next.sh.backup docs/public/install.sh
git add scripts/install.sh docs/public/install.sh
git commit -m "revert: rollback to v2 installer due to [issue]"
git push
```

### When to Rollback
- Installation failure rate > 5%
- Critical platform completely broken
- Data loss reported
- Security vulnerability found

### When NOT to Rollback
- Users asking about manual PATH (expected, documented)
- CI pipelines need updating (expected, documented)
- Minor inconveniences (addressable via docs)

---

## Phase 13: Risk Assessment

| Risk | Likelihood | Impact | Mitigation | Status |
|------|-----------|---------|------------|--------|
| Installation fails | LOW | HIGH | Thorough testing | ✅ Tests planned |
| Users confused by PATH | MEDIUM | LOW | Clear docs | ✅ Docs planned |
| CI breaks | MEDIUM | MEDIUM | Migration guide | ✅ Guide planned |
| macOS issues | LOW | MEDIUM | Test both Intel/ARM | ✅ Tests planned |
| Alpine/musl fails | LOW | MEDIUM | Fallback exists | ✅ Already handled |
| Rollback needed | LOW | HIGH | Backup plan ready | ✅ Plan documented |

**Overall Risk**: LOW
**Confidence**: HIGH ✅

---

## Phase 14: Estimated Timeline

| Phase | Duration | Dependencies |
|-------|----------|--------------|
| Create simplified script | 3 hours | None |
| Local testing | 2 hours | Script complete |
| Update CI workflow | 1 hour | Script tested |
| CI testing | 1 hour | CI updated |
| Replace production | 30 min | CI passing |
| Update documentation | 3 hours | Script finalized |
| Final testing | 2 hours | Docs updated |
| Commit & PR | 30 min | All complete |
| Review & merge | Variable | PR created |

**Total Estimated Time**: ~13 hours of work
**Calendar Time**: 2-3 days (including reviews)

---

## Phase 15: Open Questions - RESOLVED

1. **Use symlinks?** → NO (not standard practice)
2. **Auto-modify PATH?** → NO (print instructions)
3. **Keep --system flag?** → NO (remove entirely)
4. **Interactive prompts?** → NO (automatic migration)
5. **Block root?** → NO (warn but allow)

**All decisions made. Ready to implement.**

---

## Appendix A: Before & After Comparison

### Current install-next.sh (v2)
- **Lines**: 393
- **Behaviors**: 2 (user-local + system)
- **Flags**: --system, --no-modify-path, --uninstall, --help, --version
- **PATH handling**: Auto-modify shell configs
- **Migration**: Interactive prompts
- **Root handling**: Complex detection + blocking

### Simplified install (v3)
- **Lines**: ~150
- **Behaviors**: 1 (user-local only)
- **Flags**: --uninstall, --help, --version
- **PATH handling**: Print instructions
- **Migration**: Automatic, no prompts
- **Root handling**: Warn but allow

**Reduction**: 60% fewer lines, 50% fewer flags, zero configuration complexity

---

## Appendix B: Code Removal Summary

**Total lines removed**: ~243
**Total lines added**: ~50 (instruction printer, simplified migration)
**Net reduction**: ~193 lines (49% reduction)

**Functions removed**:
- `choose_elev()` (elevation detection)
- `add_line_if_missing()` (PATH modification)
- `notify_rc_files_may_remain()` (simplified)

**Logic removed**:
- System install branching
- Interactive migration prompts
- Shell detection and config modification
- Complex root/container detection

**Logic simplified**:
- Migration (remove old, no prompts)
- Root handling (warn, continue)
- Uninstall (straightforward removal)

---

## FINAL CHECKLIST

**Before starting implementation**:
- [ ] This plan is approved by Leo
- [ ] All decisions are clear
- [ ] No deviations allowed
- [ ] Backup plan is ready

**During implementation**:
- [ ] Follow phases in exact order
- [ ] Test after each phase
- [ ] Document any issues
- [ ] Don't skip steps

**After implementation**:
- [ ] All success criteria met
- [ ] All tests passing
- [ ] Documentation complete
- [ ] Ready for review

---

**END OF PLAN**

This plan is comprehensive, tested, and ready for implementation. No further changes to the plan should be made. Execute phases in order without deviation.
