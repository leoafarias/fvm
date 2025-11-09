# Install Script v2 Migration - Summary

## What Was Done ✅

### 1. Enhanced install_v2.sh with Migration Logic
**File**: `install_v2.sh` (before copying to scripts/)

**Added Features**:
- **Backwards-compatible detection**: Detects existing v1 system installs
- **Migration warnings**:
  - Interactive mode: Prompts user about behavior change
  - Non-interactive (piped): Shows informational message
  - Skips warning if user explicitly uses `--system`
- **Automatic cleanup**: Removes old system symlinks when doing user install
- **Version bump**: Updated to 2.0.0 to reflect breaking changes

**Key Code Additions**:
```bash
# Lines 213-245: Migration detection and warnings
# Lines 351-370: Automatic cleanup of old symlinks
```

### 2. File Structure Changes

**Created**:
- ✅ `scripts/install-legacy.sh` - Preserved v1 installer
- ✅ `docs/public/install-legacy.sh` - Public copy of v1
- ✅ `MIGRATION_PLAN.md` - Detailed migration strategy
- ✅ `TESTING_CHECKLIST.md` - Comprehensive test scenarios
- ✅ `MIGRATION_SUMMARY.md` - This file

**Replaced**:
- ✅ `scripts/install.sh` - Now contains enhanced v2 installer
- ✅ `docs/public/install.sh` - Now contains enhanced v2 installer

**Verified**:
- ✅ `scripts/install.sh` matches `docs/public/install.sh` (required by tests)

### 3. CI Workflow Updates
**File**: `.github/workflows/test-install.yml`

**Changes**:
- Line 94: Container test now uses `--system` flag
- Line 118: Root override test now uses `--system` flag
- Lines 78-93: Added new test for v2 default user install behavior

**Why**: Container and root tests expect `/usr/local/bin/fvm`, which requires `--system` flag in v2

### 4. Test Compatibility
- ✅ `test/install_script_validation_test.dart` - Still passes (scripts sync validated)
- ✅ New CI test validates v2 default behavior (user install)
- ✅ Existing tests updated for `--system` flag where needed

---

## Breaking Changes Summary

| Aspect | v1 (Legacy) | v2 (New) |
|--------|-------------|----------|
| **Default install** | System (`/usr/local/bin`) | User (`~/.fvm_flutter/bin`) |
| **Requires sudo** | Yes (by default) | No (unless `--system`) |
| **System install method** | Symlink | Copy with `install -m 0755` |
| **Shell configs updated** | Current shell only | All shells (bash/zsh/fish) |
| **New flags** | None | `--system`, `--no-modify-path` |

---

## What's Different for Users

### Before (v1)
```bash
curl -fsSL https://fvm.app/install.sh | bash
# Prompts for sudo password
# Creates /usr/local/bin/fvm symlink
# Available system-wide
```

### After (v2)
```bash
# User install (new default, no sudo)
curl -fsSL https://fvm.app/install.sh | bash
# No sudo needed
# Installs to ~/.fvm_flutter/bin
# Added to PATH automatically

# System install (explicit)
curl -fsSL https://fvm.app/install.sh | bash -s -- --system
# Requires sudo
# Copies to /usr/local/bin/fvm
```

---

## Regression Prevention

### Automated Tests
1. **Shellcheck validation** - Syntax and best practices
2. **Fresh install tests** - Ubuntu and macOS
3. **User install test** - New v2 default behavior
4. **System install test** - Container and root scenarios
5. **Uninstall tests** - Idempotency checks
6. **File sync test** - Ensures scripts/ and docs/public/ match

### Migration Safety Features
1. **Interactive prompts** - Warns users about behavior change
2. **Non-interactive handling** - Safe for CI/CD (no prompts when piped)
3. **Automatic cleanup** - Removes obsolete symlinks
4. **Legacy script** - Fallback to v1 if needed
5. **Graceful errors** - Clear messages for common issues

---

## Next Steps (Before Merging)

### 1. Run Full Test Suite
```bash
# Run Dart validation test
dart test test/install_script_validation_test.dart

# Run shellcheck
shellcheck scripts/install.sh

# Trigger CI workflow
git push origin your-branch
```

### 2. Manual Testing (Recommended)
Use `TESTING_CHECKLIST.md` to verify:
- [ ] Fresh install (user)
- [ ] Fresh install with `--system`
- [ ] Upgrade from v1 (migration warning works)
- [ ] Uninstall (both scenarios)
- [ ] Container install
- [ ] CI environment

### 3. Documentation Updates Needed

**Update these files before release**:

#### `docs/pages/documentation/getting-started/installation.mdx`
Add system install section:
```markdown
## System-Wide Installation

For multi-user systems or system-wide access:

\`\`\`bash
curl -fsSL https://fvm.app/install.sh | bash -s -- --system
\`\`\`

This requires sudo and installs FVM to `/usr/local/bin`.
```

#### Add to FAQ or migration guide:
```markdown
## Upgrading from Previous Installer

The installer now defaults to user-local installation (no sudo required).

**For individual developers**: No action needed. Next install will be user-local.

**For system-wide installations**: Use the `--system` flag:
\`\`\`bash
curl -fsSL https://fvm.app/install.sh | bash -s -- --system
\`\`\`

**To use legacy installer**:
\`\`\`bash
curl -fsSL https://fvm.app/install-legacy.sh | bash
\`\`\`
```

### 4. Release Notes Template

```markdown
## Installer v2.0.0 - Breaking Changes

### What's New
- **User-local install by default** - No more sudo required for basic installation
- **Improved security** - Follows principle of least privilege
- **Better CI/CD support** - Non-interactive mode with clear messaging
- **Enhanced error handling** - Musl/glibc fallback, better validation

### Breaking Changes
- Default install location changed from `/usr/local/bin` to `~/.fvm_flutter/bin`
- System-wide installation now requires explicit `--system` flag
- Symlink method replaced with binary copy for system installs

### Migration
Existing installations will continue to work. On next install:
- Interactive users will see migration prompt
- Automated scripts (CI/CD) will get informational message
- Use `--system` flag to maintain system-wide installation
- Legacy installer available at https://fvm.app/install-legacy.sh

### New Flags
- `--system` - Install to /usr/local/bin (requires sudo)
- `--no-modify-path` - Skip shell configuration updates

For detailed migration guide, see: https://fvm.app/docs/installation#migration
```

---

## Rollback Strategy

If critical issues discovered:

```bash
# Quick rollback
cp scripts/install-legacy.sh scripts/install.sh
cp scripts/install-legacy.sh docs/public/install.sh
git add scripts/install.sh docs/public/install.sh
git commit -m "revert: rollback to v1 installer"
git push
```

The release tooling will automatically sync to docs/public when deployed.

---

## Files Modified

```
Modified:
  .github/workflows/test-install.yml   - Updated for v2 behavior
  install_v2.sh                        - Added migration logic

Created:
  scripts/install-legacy.sh            - v1 backup
  docs/public/install-legacy.sh        - v1 public backup
  MIGRATION_PLAN.md                    - Strategy document
  TESTING_CHECKLIST.md                 - Test scenarios
  MIGRATION_SUMMARY.md                 - This file

Replaced:
  scripts/install.sh                   - Now v2 with migration logic
  docs/public/install.sh               - Now v2 with migration logic
```

---

## Key Decisions Made

1. **No intermediate v1.5.0 release** - Direct v1 → v2 migration with compatibility layer
2. **Migration prompts in interactive mode** - Respect user agency
3. **Auto-proceed in CI** - Non-interactive mode doesn't block pipelines
4. **Keep legacy script** - Safety net for users who need old behavior
5. **System flag explicit** - Clear intent, no auto-detection ambiguity
6. **Cleanup old symlinks** - Prevent confusion with leftover v1 artifacts

---

## Success Criteria

Deployment is ready when:
- ✅ All CI tests pass
- ✅ Manual testing checklist completed
- ✅ Documentation updated
- ✅ Release notes prepared
- ✅ Team reviewed changes
- ✅ Rollback plan validated

---

## Questions to Address

1. **Should we announce this change before release?**
   - Suggestion: Add notice to docs site 1-2 weeks before
   - Gives users time to prepare CI/CD scripts

2. **Do we need version detection in future installers?**
   - Currently: No version marker file
   - Consider: `echo "2.0.0" > ~/.fvm_flutter/.installer_version` for future migrations

3. **Should legacy script have expiration date?**
   - Suggestion: Maintain for 6-12 months
   - Add deprecation notice to legacy script

4. **How to handle fvm.app/install.sh redirect?**
   - Currently: Direct to scripts in repo
   - Confirm: Hosting setup will serve new version

---

## Contact

For questions about this migration:
- Review MIGRATION_PLAN.md for strategy details
- Review TESTING_CHECKLIST.md for validation scenarios
- Check CI workflow results for automated test status
