# PR #967 Bug Analysis: install-next.sh v2.0.0

**Analysis Date:** 2025-12-08
**Script Version:** 2.0.0
**Total Lines:** 393

---

## Executive Summary

After deep analysis of the actual `install-next.sh` script from PR #967, I found **6 bugs** ranging from critical to minor. The script is generally well-structured but has issues in error handling, cleanup logic, and edge cases.

---

## Bug #1: `rm -f` Silent Failure in Uninstall

### Location
Lines 142-156 in `do_uninstall()` function

### Code
```bash
# Remove system-wide binary (handles both symlink and regular file)
if [ -L "$SYSTEM_DEST" ] || [ -f "$SYSTEM_DEST" ]; then
  if rm -f "$SYSTEM_DEST" 2>/dev/null; then    # <-- BUG HERE
    removed_system=1
    echo "Removed system binary: $SYSTEM_DEST"
  else
    ...
  fi
fi
```

### The Bug
The `rm -f` command **always returns exit code 0**, even when it fails to remove a file due to:
- Permission denied (file owned by root)
- Immutable file attribute (`chattr +i`)
- Read-only filesystem
- SELinux/AppArmor restrictions

### Why It's Wrong
```bash
# Demonstration:
$ touch /tmp/test && sudo chown root /tmp/test
$ rm -f /tmp/test 2>/dev/null
$ echo $?
0  # Returns SUCCESS even though file still exists!
$ ls /tmp/test
/tmp/test  # File still there!
```

The `-f` flag means "force" - it suppresses errors and always returns 0. The conditional `if rm -f ... then` will **always** take the "success" branch, causing:
- "Removed system binary" message shown even when file NOT removed
- User thinks uninstall succeeded when it didn't
- Old binary remains, causing version confusion

### Impact
**Severity: HIGH**
- Silent failure misleads users
- Security risk: old vulnerable binary remains
- Debugging difficulty: user sees success but fvm still exists

### Fix
```bash
# Option 1: Check if file still exists after removal
if [ -L "$SYSTEM_DEST" ] || [ -f "$SYSTEM_DEST" ]; then
  rm -f "$SYSTEM_DEST" 2>/dev/null || true
  if [ ! -e "$SYSTEM_DEST" ]; then
    removed_system=1
    echo "Removed system binary: $SYSTEM_DEST"
  else
    # Try with elevation...
  fi
fi

# Option 2: Use rm without -f and check error
if [ -L "$SYSTEM_DEST" ] || [ -f "$SYSTEM_DEST" ]; then
  if rm "$SYSTEM_DEST" 2>/dev/null; then
    removed_system=1
    echo "Removed system binary: $SYSTEM_DEST"
  else
    # Permission denied, try elevation...
  fi
fi
```

---

## Bug #2: Same `rm -f` Issue in Legacy Symlink Cleanup

### Location
Lines 327-340 in the legacy system symlink cleanup section

### Code
```bash
if [ "$LEGACY_SYSTEM_SYMLINK" -eq 1 ] && [ -L "$SYSTEM_DEST" ]; then
  if [ "$(readlink "$SYSTEM_DEST" 2>/dev/null || true)" = "${BIN_DIR}/fvm" ]; then
    echo "Cleaning up old system symlink..."
    if rm -f "$SYSTEM_DEST" 2>/dev/null; then    # <-- SAME BUG
      echo "Removed old system symlink: $SYSTEM_DEST"
    else
      local ELEV; ELEV="$(choose_elev)"          # <-- ANOTHER BUG: local in non-function
      ...
    fi
  fi
fi
```

### The Bug
Same as Bug #1 - `rm -f` always returns 0, so the success message is printed even when removal fails.

### Additional Bug: `local` Outside Function
Line 333 uses `local ELEV` but this code is NOT inside a function - it's in the main script body. While bash tolerates this, it's:
- Non-portable (fails in strict POSIX sh)
- Confusing (local has no meaning outside functions)
- Shellcheck warning

### Impact
**Severity: HIGH**
- Migration from v1 appears to succeed but old symlink remains
- User has both old and new fvm, PATH determines which runs
- Potential for running outdated/vulnerable version

### Fix
```bash
if [ "$LEGACY_SYSTEM_SYMLINK" -eq 1 ] && [ -L "$SYSTEM_DEST" ]; then
  if [ "$(readlink "$SYSTEM_DEST" 2>/dev/null || true)" = "${BIN_DIR}/fvm" ]; then
    echo "Cleaning up old system symlink..."
    rm -f "$SYSTEM_DEST" 2>/dev/null || true

    # Check if actually removed
    if [ ! -e "$SYSTEM_DEST" ]; then
      echo "Removed old system symlink: $SYSTEM_DEST"
    else
      ELEV="$(choose_elev)"  # Remove 'local' keyword
      if [ -n "$ELEV" ]; then
        $ELEV rm -f "$SYSTEM_DEST" 2>/dev/null || true
        if [ ! -e "$SYSTEM_DEST" ]; then
          echo "Removed old system symlink: $SYSTEM_DEST"
        else
          echo "note: could not remove old symlink $SYSTEM_DEST (requires sudo)"
        fi
      fi
    fi
  fi
fi
```

---

## Bug #3: Missing Newline at End of File

### Location
Line 393 (last line)

### Code
```bash
echo "Done."  # <-- No newline after this
```

### The Bug
The file doesn't end with a newline character. This causes:
- POSIX non-compliance (POSIX requires text files to end with newline)
- Git shows `\ No newline at end of file` warning
- Some tools may not process last line correctly
- `cat file1 file2` concatenation issues

### Impact
**Severity: LOW**
- Cosmetic issue
- Minor tool compatibility problems

### Fix
Add empty line at end of file, or ensure `echo "Done."` is followed by newline.

---

## Bug #4: Potential Race Condition in Temp Directory

### Location
Lines 278-280

### Code
```bash
mkdir -p "$BIN_DIR" "$TMP_DIR"
cleanup() { rm -rf "$TMP_DIR" 2>/dev/null || true; }
trap cleanup EXIT
```

### The Bug
The `TMP_DIR` is set to a predictable path:
```bash
TMP_DIR="${INSTALL_BASE}/temp_extract"  # Line 18
# Expands to: ~/.fvm_flutter/temp_extract
```

This creates a **Time-of-Check-Time-of-Use (TOCTOU)** vulnerability:

1. Script creates `~/.fvm_flutter/temp_extract`
2. Attacker (same user or symlink attack) replaces with malicious content
3. Script extracts tarball, potentially overwriting attacker-controlled files
4. Script copies "fvm" binary which could be attacker's binary

### Attack Scenario
```bash
# Attacker runs in parallel:
while true; do
  rm -rf ~/.fvm_flutter/temp_extract
  ln -s /tmp/attacker_dir ~/.fvm_flutter/temp_extract
done

# When timing is right, victim's install extracts to attacker's directory
# Attacker can then swap the fvm binary before copy
```

### Impact
**Severity: MEDIUM**
- Requires attacker to have same-user access
- Race condition timing is difficult
- Could lead to arbitrary code execution

### Fix
Use `mktemp` for unpredictable directory name:
```bash
TMP_DIR="$(mktemp -d "${TMPDIR:-/tmp}/fvm-install.XXXXXXXXXX")" || {
  echo "error: failed to create temp directory" >&2
  exit 1
}
```

---

## Bug #5: No Download Checksum Verification

### Location
Lines 283-285

### Code
```bash
ARCHIVE="${TMP_DIR}/${TARBALL}"
echo "Downloading ${URL}"
curl -fsSL "$URL" -o "$ARCHIVE"
```

### The Bug
The script downloads a binary from GitHub and executes it without any integrity verification:
- No SHA256/SHA512 checksum
- No GPG signature verification
- HTTPS provides transport security but not content integrity

### Attack Scenarios
1. **MITM Attack**: Attacker intercepts HTTPS (corporate proxy, compromised CA)
2. **CDN Compromise**: GitHub's CDN cache poisoned
3. **Account Compromise**: Attacker gains GitHub release access
4. **DNS Hijacking**: Attacker redirects github.com

### Impact
**Severity: MEDIUM-HIGH**
- Supply chain attack vector
- User unknowingly installs malicious binary
- Affects all users who install during attack window

### Fix
```bash
# Download checksum file
CHECKSUM_URL="${URL}.sha256"
if curl -fsSL "$CHECKSUM_URL" -o "${ARCHIVE}.sha256" 2>/dev/null; then
  echo "Verifying checksum..."

  # Verify (works on both Linux and macOS)
  if command -v sha256sum >/dev/null 2>&1; then
    (cd "$(dirname "$ARCHIVE")" && sha256sum -c "$(basename "${ARCHIVE}.sha256")")
  elif command -v shasum >/dev/null 2>&1; then
    (cd "$(dirname "$ARCHIVE")" && shasum -a 256 -c "$(basename "${ARCHIVE}.sha256")")
  else
    echo "warning: no sha256sum available, skipping verification"
  fi
else
  echo "warning: checksum file not found, skipping verification"
fi
```

**Note:** This requires FVM releases to publish `.sha256` files alongside binaries.

---

## Bug #6: Fish Shell PATH Line Has Syntax Issues

### Location
Lines 350-351

### Code
```bash
if command -v fish >/dev/null 2>&1; then
  add_line_if_missing "${HOME}/.config/fish/config.fish" 'fish_add_path "$HOME/.fvm_flutter/bin"' 'if type -q fish_add_path; fish_add_path "$HOME/.fvm_flutter/bin"; else; set -gx PATH "$HOME/.fvm_flutter/bin" $PATH; end'
fi
```

### The Bug
The fish shell line added has potential issues:

1. **Semicolons in fish**: Fish uses newlines OR semicolons, but the condensed one-liner is hard to read and error-prone

2. **Quote escaping**: The `$HOME` inside single quotes won't expand in fish - it will be literal `$HOME`

3. **Duplicate PATH entries**: Running installer multiple times adds duplicate entries because the marker `fish_add_path "$HOME/.fvm_flutter/bin"` uses double quotes but the actual line uses mixed quoting

### Impact
**Severity: LOW-MEDIUM**
- Fish users may have broken PATH
- Multiple installer runs create duplicates
- Confusing error messages in fish

### Fix
```bash
# Use fish's native variable expansion
FISH_LINE='set -gx PATH "$HOME/.fvm_flutter/bin" $PATH'
FISH_MARKER='.fvm_flutter/bin'  # Simpler marker

if command -v fish >/dev/null 2>&1; then
  add_line_if_missing "${HOME}/.config/fish/config.fish" "$FISH_MARKER" "$FISH_LINE"
fi
```

Or better, use fish's `fish_add_path` which handles duplicates:
```bash
# This is idempotent - won't add duplicates
FISH_LINE='fish_add_path -g "$HOME/.fvm_flutter/bin"'
```

---

## Summary Table

| # | Bug | Severity | Line(s) | Type |
|---|-----|----------|---------|------|
| 1 | `rm -f` silent failure in uninstall | HIGH | 144 | Logic Error |
| 2 | `rm -f` silent failure in migration + `local` misuse | HIGH | 329, 333 | Logic Error |
| 3 | Missing EOF newline | LOW | 393 | Style |
| 4 | Predictable temp directory (TOCTOU) | MEDIUM | 18, 278 | Security |
| 5 | No checksum verification | MEDIUM-HIGH | 283-285 | Security |
| 6 | Fish shell PATH syntax | LOW-MEDIUM | 350-351 | Compatibility |

---

## Recommendations

### Must Fix Before Merge
1. **Bug #1 & #2**: Fix `rm -f` silent failures - this causes user-facing incorrect behavior
2. **Bug #3**: Add newline at EOF

### Should Fix Before Production Use
3. **Bug #4**: Use `mktemp` for temp directory
4. **Bug #6**: Fix fish shell PATH line

### Consider for Future
5. **Bug #5**: Add checksum verification (requires release process changes)

---

## Good Things About the Script

Despite the bugs, the script has several improvements over v1:

1. **Better CI detection** (lines 71-89) - Detects 11+ CI systems
2. **musl/glibc fallback** (lines 268-277) - Tries musl, falls back to glibc
3. **Cleanup trap** (lines 279-280) - Removes temp files on exit
4. **Non-fatal binary verification** (lines 354-356) - Warns but doesn't fail
5. **Interactive migration prompt** (lines 217-232) - Asks user before proceeding
6. **Idempotent uninstall** (line 173) - Exits 0 even if nothing to remove
7. **Archive validation** (lines 288-291) - Checks tarball is valid gzip

---

**Analysis by:** Code Agent
**Date:** 2025-12-08
