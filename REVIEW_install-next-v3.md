# Code Review: install-next.sh v3.0.0

**Review Date:** 2025-11-14
**Branch:** feat/install-script-v2
**Reviewer:** Code Agent
**Script:** scripts/install-next.sh (306 lines)
**Version:** 3.0.0

---

## Executive Summary

The install-next.sh v3.0.0 represents a **40% code reduction** (513 → 306 lines) with a clear architectural shift from system-wide to user-local installation. The script is **well-designed and not over-engineered**, successfully removing unnecessary complexity while maintaining core functionality.

**Overall Assessment:** ✅ **APPROVED with minor fixes recommended**

### Critical Issues Found: 1
- Migration logic has silent failure bug (affects user feedback accuracy)

### Recommended Improvements: 5
- Test coverage gaps for critical features
- Missing documentation for v1→v3 migration

---

## 1. Correctness Review

### ✅ CORRECT: Version Resolution (lines 68-73)

**Code:**
```bash
get_latest_version() {
  local url
  url="$(curl -fsSLI -o /dev/null -w '%{url_effective}' "https://github.com/${REPO}/releases/latest")" || return 1
  normalize_version "${url##*/}"
}
```

**Assessment:**
- Uses GitHub redirect mechanism properly
- Efficient HEAD request with `-I` flag
- Proper error handling with `|| return 1`
- Version normalization strips 'v' prefix correctly

**Status:** No changes needed

---

### ✅ CORRECT: Platform Detection (lines 205-256)

**OS Detection:**
- Covers Linux and macOS
- Fails gracefully on unsupported platforms

**Architecture Detection:**
- Comprehensive: x64, arm64, arm, riscv64
- Handles architecture aliases (amd64→x64, aarch64→arm64)

**Musl/Glibc Detection:**
- Dual detection: `ldd --version` and `/proc/self/maps`
- Robust for Alpine Linux
- Only applies to Linux x64/arm64 (correct)

**Fallback Logic:**
- Validates URL with HEAD request before download
- Graceful fallback: musl → glibc if musl unavailable
- Clear error messages

**Status:** No changes needed
**Note:** Musl fallback not tested in CI (see Test Coverage section)

---

### ⚠️ BUG FOUND: Migration Logic (lines 98-123)

**Issue: Silent Failure in Migration**

**Current Code:**
```bash
if rm -f "$OLD_SYSTEM_PATH" 2>/dev/null; then
  echo "✓ Removed old system install"
else
  # Try with sudo if available
  if command -v sudo >/dev/null 2>&1; then
    if sudo rm -f "$OLD_SYSTEM_PATH" 2>/dev/null; then
      echo "✓ Removed old system install (required sudo)"
```

**Problem:**
The `-f` flag in `rm -f` forces success (exit code 0) even when the file cannot be removed. This causes the `if` condition to always evaluate to true, leading to:
- "✓ Removed old system install" message even when removal failed
- False success feedback to users
- Actual file may still exist

**Impact:**
- **Severity:** Medium (non-fatal, but misleading)
- Installation continues successfully
- Old system install may remain, causing confusion
- User sees incorrect success message

**Recommended Fix:**

```bash
migrate_from_v1() {
  if [ -L "$OLD_SYSTEM_PATH" ] || [ -f "$OLD_SYSTEM_PATH" ]; then
    echo ""
    echo "Detected old installation at $OLD_SYSTEM_PATH"
    echo "Migrating to user-local install..."

    # Try to remove without sudo first (remove -f flag)
    if rm "$OLD_SYSTEM_PATH" 2>/dev/null; then
      echo "✓ Removed old system install"
    elif command -v sudo >/dev/null 2>&1 && sudo rm "$OLD_SYSTEM_PATH" 2>/dev/null; then
      echo "✓ Removed old system install (required sudo)"
    else
      echo "⚠ Could not remove $OLD_SYSTEM_PATH"
      echo "  You may remove it manually: sudo rm $OLD_SYSTEM_PATH"
    fi
  fi
}
```

**Changes:**
1. Remove `-f` flag from both `rm` commands (lines 106, 111)
2. Consolidate else-if chain for cleaner logic
3. Allow proper error detection while maintaining graceful degradation

---

### ✅ EXCELLENT: Binary Extraction (lines 275-288)

**Assessment:**
- Handles 3 different tarball structures
- Multiple fallbacks with `find` as last resort
- Archive validation before extraction
- Non-fatal binary verification (good design)

**Status:** No changes needed

---

### ⚠️ SAME BUG: Uninstall Logic (lines 125-168)

**Issue:**
Same `-f` flag problem in uninstall function (lines 140, 144)

**Recommended Fix:**
```bash
# Line 139-150 should be:
if [ -L "$OLD_SYSTEM_PATH" ] || [ -f "$OLD_SYSTEM_PATH" ]; then
  if rm "$OLD_SYSTEM_PATH" 2>/dev/null; then
    echo "✓ Removed old system install: $OLD_SYSTEM_PATH"
    removed_any=1
  elif command -v sudo >/dev/null 2>&1 && sudo rm "$OLD_SYSTEM_PATH" 2>/dev/null; then
    echo "✓ Removed old system install: $OLD_SYSTEM_PATH"
    removed_any=1
  else
    echo "⚠ Could not remove $OLD_SYSTEM_PATH (may need sudo)"
  fi
fi
```

**Impact:** Same as migration bug, but less critical since uninstall is explicit operation.

---

## 2. Over-Engineering Analysis

### Comparison: v1 vs v3

| Feature | v1 (513 lines) | v3 (306 lines) | Status |
|---------|----------------|----------------|--------|
| **Lines of Code** | 513 | 306 | ✅ 40% reduction |
| **Color Output** | Yes (5 functions) | No (plain text) | ✅ Simplified |
| **CI Detection** | Yes (~15 vars) | No | ✅ Removed complexity |
| **Shell Config** | Auto-modifies | Prints instructions | ✅ More transparent |
| **System Install** | Default behavior | Removed entirely | ✅ Simpler model |
| **Root Handling** | Complex blocking | Simple warning | ✅ Streamlined |
| **Privilege Escalation** | sudo/doas detection | Minimal sudo use | ✅ Less complex |
| **Symlink Logic** | Yes (system-wide) | No | ✅ User-local only |

### Removed Features (Intentional):

**v1 Features Removed in v3:**
- ❌ Color output functions (28 lines)
- ❌ CI/container detection (`is_container_env`)
- ❌ Automatic shell config modification (bash/zsh/fish)
- ❌ System-wide installation default
- ❌ Privilege escalation helpers (sudo/doas)
- ❌ Symlink creation/removal to `/usr/local/bin`
- ❌ `--system` flag
- ❌ Interactive migration prompts

### What Remains (Essential):

✅ Version resolution
✅ Platform detection (OS/arch/libc)
✅ Download and validation
✅ Extraction with multiple fallbacks
✅ Migration from v1/v2
✅ Clear user instructions

### Verdict: ✅ NOT OVER-ENGINEERED

The v3 script successfully follows **modern tool patterns** (rustup, nvm, pyenv):
- **User-local by default** → No sudo required → More secure
- **Manual PATH setup** → More transparent → Better understanding
- **Single behavior** → Less complexity → Easier to maintain

**Assessment:** The script is appropriately simplified. No unnecessary complexity detected.

---

## 3. Missing Functionality

### A. Test Coverage Gaps

#### ❌ CRITICAL: Musl/Glibc Fallback Not Tested

**Location:** install-next.sh:242-256
**Why Critical:** Alpine Linux users depend on this logic

**Current State:**
- Logic exists and is correct
- No CI test with musl-based system
- Fallback behavior unverified

**Recommendation:**
Add Alpine Linux test job to `.github/workflows/test-install.yml`:

```yaml
test-alpine:
  name: Test Alpine Linux (musl)
  needs: validate
  runs-on: ubuntu-latest
  container: alpine:latest
  steps:
    - uses: actions/checkout@v4

    - name: Install dependencies
      run: apk add --no-cache bash curl tar gzip

    - name: Test musl detection
      run: |
        ./scripts/install-next.sh
        $HOME/.fvm_flutter/bin/fvm --version
        echo "✅ Alpine/musl install successful"
```

**Priority:** High

---

#### ❌ MISSING: Specific Version Installation Test

**Current State:**
- Only tests `latest` version
- Version argument parsing exists (line 176)
- No test for specific version like `./install-next.sh 3.0.0`

**Recommendation:**
Add test case to existing `test-install` job:

```yaml
- name: Test specific version installation
  run: |
    # Uninstall current
    ./scripts/install-next.sh --uninstall

    # Install specific version (use known good version)
    ./scripts/install-next.sh 3.0.0

    export PATH="$HOME/.fvm_flutter/bin:$PATH"
    version=$(fvm --version | grep -oP '\d+\.\d+\.\d+')

    if [[ "$version" != "3.0.0" ]]; then
      echo "❌ Expected version 3.0.0, got $version"
      exit 1
    fi

    echo "✅ Specific version install successful"
```

**Priority:** Medium

---

#### ❌ MISSING: Migration Scenario Test

**Current State:**
- Migration logic exists (lines 98-123)
- No test that creates old v1 install first
- No verification that migration cleanup works

**Recommendation:**
Add migration test job:

```yaml
test-migration:
  name: Test v1 to v3 Migration
  needs: validate
  runs-on: ubuntu-latest
  steps:
    - uses: actions/checkout@v4

    - name: Simulate v1 install
      run: |
        # Create fake v1 system install
        sudo mkdir -p /usr/local/bin
        echo '#!/bin/bash' | sudo tee /usr/local/bin/fvm
        echo 'echo "fake v1 fvm"' | sudo tee -a /usr/local/bin/fvm
        sudo chmod +x /usr/local/bin/fvm

        # Verify v1 install exists
        test -f /usr/local/bin/fvm || exit 1

    - name: Test v3 migration
      run: |
        ./scripts/install-next.sh

        # Verify v3 install
        test -f ~/.fvm_flutter/bin/fvm || { echo "❌ v3 install failed"; exit 1; }

        # Verify v1 cleanup (THIS WILL CATCH THE BUG)
        if test -f /usr/local/bin/fvm; then
          echo "⚠ v1 install still exists after migration"
          # This is acceptable if sudo wasn't available, check message
        fi

        echo "✅ Migration test complete"
```

**Priority:** High (would catch the migration bug)

---

#### ⚠️ OPTIONAL: Architecture Variants

**Current State:**
- Only tests x64 (default CI runners)
- macOS runners support arm64 testing
- No arm64-specific test

**Recommendation:**
Add arm64 test using macOS M1 runners:

```yaml
test-install-arm64:
  name: Test - macOS ARM64
  needs: validate
  runs-on: macos-14  # M1 runner
  steps:
    - uses: actions/checkout@v4
    - name: Verify architecture
      run: uname -m  # Should show arm64
    - name: Test installation
      run: |
        ./scripts/install-next.sh
        export PATH="$HOME/.fvm_flutter/bin:$PATH"
        fvm --version
```

**Priority:** Low (nice to have)

---

#### ⚠️ OPTIONAL: Corrupted Download Test

**Current State:**
- Archive validation exists (lines 270-273)
- No test with corrupted tarball

**Recommendation:**
```yaml
- name: Test corrupted download handling
  run: |
    # Create corrupted tarball
    echo "corrupted data" > /tmp/fvm-test.tar.gz

    # Mock download (would need script modification to test this)
    # This is hard to test without mocking, consider unit tests instead
```

**Priority:** Low (edge case)

---

### B. Documentation Gaps

#### ❌ MISSING: Migration Guide

**Issue:**
No documentation explaining v1→v3 changes for existing users

**Recommendation:**
Create `docs/pages/documentation/getting-started/migration-v3.md`:

```markdown
# Migrating to Installer v3.0

## What Changed

FVM installer v3.0 simplifies installation with a **user-local only** approach.

### Key Changes

| Feature | v1 Installer | v3 Installer |
|---------|--------------|--------------|
| Install Location | `/usr/local/bin/fvm` | `~/.fvm_flutter/bin` |
| Requires sudo | Yes | No |
| PATH modification | Automatic | Manual (you add it) |
| System-wide install | Available with sudo | Not available |

### Migration Steps

1. **Run the new installer** - It will automatically detect and remove old installations:
   ```bash
   curl -fsSL https://fvm.app/install.sh | bash
   ```

2. **Add FVM to your PATH** - Add this line to your shell config:
   ```bash
   export PATH="$HOME/.fvm_flutter/bin:$PATH"
   ```

3. **Restart your shell** or run:
   ```bash
   source ~/.bashrc  # or ~/.zshrc
   ```

### Manual Cleanup (if needed)

If automatic migration fails, remove the old installation manually:
```bash
sudo rm /usr/local/bin/fvm
```

### Why User-Local?

- **No sudo required** - More secure, works in restrictive environments
- **Per-user installs** - Each user can have different FVM versions
- **Follows modern patterns** - Like rustup, nvm, pyenv
```

**Priority:** High (user-facing impact)

---

#### ❌ MISSING: Troubleshooting Section

**Issue:**
No troubleshooting guide in existing docs

**Recommendation:**
Add to `scripts/install.md`:

```markdown
## Troubleshooting

### FVM not found after installation

**Problem:** Running `fvm` shows "command not found"

**Solution:** Add FVM to your PATH:
```bash
export PATH="$HOME/.fvm_flutter/bin:$PATH"
```

Add this line to your shell config (~/.bashrc, ~/.zshrc, etc.) and restart your shell.

### Permission denied errors

**Problem:** Installation fails with "Permission denied"

**Solution:** The v3 installer doesn't require sudo. If you see permission errors:
1. Check `~/.fvm_flutter` directory permissions
2. Ensure you're not running with sudo (not needed)
3. If running as root, FVM will install to `/root/.fvm_flutter/bin`

### Old installation still present

**Problem:** `/usr/local/bin/fvm` still exists after v3 installation

**Solution:** Remove it manually:
```bash
sudo rm /usr/local/bin/fvm
```

### Binary verification failed

**Problem:** Installation completes but "fvm --version" fails

**Solution:** System libraries may be missing. On Linux:
```bash
# Ubuntu/Debian
sudo apt-get install libc6

# Alpine
apk add glibc  # or use musl variant
```
```

**Priority:** Medium

---

#### ⚠️ OPTIONAL: Feature Comparison Table

**Recommendation:**
Add comparison table to README or docs explaining what features were removed and why.

**Priority:** Low (nice to have)

---

### C. Edge Cases

#### ⚠️ MINOR: No Disk Space Check

**Issue:**
No verification that sufficient disk space exists before download

**Impact:** Low (rare, fails gracefully with curl/tar errors)

**Recommendation:** Optional - Add disk space check:
```bash
# Before download (line ~264)
available=$(df -P "$HOME" | awk 'NR==2 {print $4}')
required=50000  # 50MB in KB
if [ "$available" -lt "$required" ]; then
  echo "error: insufficient disk space (need ~50MB)" >&2
  exit 1
fi
```

**Priority:** Low (optional improvement)

---

#### ⚠️ MINOR: No Permission Check on Existing Directory

**Issue:**
If `~/.fvm_flutter` exists with different permissions, installation might fail

**Impact:** Low (rare edge case)

**Recommendation:** Add permission check:
```bash
# After mkdir (line 260)
if [ -d "$INSTALL_BASE" ] && [ ! -w "$INSTALL_BASE" ]; then
  echo "error: $INSTALL_BASE exists but is not writable" >&2
  exit 1
fi
```

**Priority:** Low (optional improvement)

---

## 4. Recommendations Summary

### Critical (Fix Before Release)

1. **Fix migration silent failure bug** (install-next.sh:106, 111, 140, 144)
   - Remove `-f` flag from `rm` commands in migration and uninstall
   - Priority: **HIGH**
   - Impact: User feedback accuracy

### High Priority (Recommended for Release)

2. **Add musl/glibc fallback test** (Alpine Linux CI job)
   - Priority: **HIGH**
   - Impact: Alpine Linux users

3. **Add migration scenario test** (v1→v3 migration test)
   - Priority: **HIGH**
   - Impact: Existing user experience
   - Would catch the migration bug

4. **Create migration guide documentation**
   - Priority: **HIGH**
   - Impact: User onboarding for v1→v3 transition

### Medium Priority (Nice to Have)

5. **Add specific version test** (test `./install.sh 3.0.0`)
   - Priority: **MEDIUM**
   - Impact: Version argument validation

6. **Add troubleshooting documentation**
   - Priority: **MEDIUM**
   - Impact: User support

### Low Priority (Future Improvements)

7. **Add arm64 CI test** (macOS M1 runners)
8. **Add disk space check** (optional defensive programming)
9. **Add permission check** (rare edge case)
10. **Create v1 vs v3 comparison table** (documentation enhancement)

---

## 5. Conclusion

### Strengths

✅ **Excellent simplification** - 40% code reduction without sacrificing functionality
✅ **Modern architecture** - User-local pattern aligns with industry standards
✅ **Robust platform detection** - Comprehensive OS/arch/libc handling
✅ **Good error handling** - Clear messages and graceful degradation
✅ **Strong CI coverage** - Tests major platforms and scenarios
✅ **Not over-engineered** - Appropriate level of complexity

### Issues

⚠️ **One bug found** - Migration silent failure (medium severity, non-fatal)
⚠️ **Test coverage gaps** - Musl fallback and migration not tested
⚠️ **Documentation gaps** - Missing migration guide for existing users

### Final Verdict

**Status:** ✅ **APPROVED for release with minor fixes**

The install-next.sh v3.0.0 is well-designed and represents a significant improvement over v1. The single bug found is non-fatal and easily fixed. Test coverage and documentation gaps are recommended but not blocking for release.

### Recommended Release Path

**Phase 1: Pre-Release (Blocking)**
- Fix migration silent failure bug
- Add musl/glibc CI test

**Phase 2: Release**
- Deploy v3.0.0 as `install-next.sh`
- Create migration guide

**Phase 3: Post-Release (Enhancements)**
- Add specific version test
- Add troubleshooting docs
- Collect user feedback

---

## Appendix: Files Reviewed

- `scripts/install-next.sh` (306 lines) - Main installer
- `docs/public/install-next.sh` (306 lines) - Public copy (identical)
- `.github/workflows/test-install.yml` (146 lines) - CI tests
- `scripts/install.sh` (513 lines) - v1 installer (comparison)
- `scripts/README.md` - Scripts documentation
- `scripts/install.md` - Installation documentation

**Total Files:** 6
**Total Lines Reviewed:** ~1,400

---

**Review Complete**
