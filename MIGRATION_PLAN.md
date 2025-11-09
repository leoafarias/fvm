# FVM Install Script v2 Migration Plan

## Overview
Migrating from install.sh v1 (system-wide by default) to v2 (user-local by default) without intermediate releases.

## Breaking Changes
1. **Default install location**: System-wide (`/usr/local/bin`) → User-local (`~/.fvm_flutter/bin`)
2. **System install method**: Symlink → Copy (when `--system` used)
3. **Shell config updates**: Current shell only → All shells (bash/zsh/fish)
4. **New flag**: `--no-modify-path` to skip shell config modifications

## Migration Strategy

### Phase 1: Prepare Enhanced v2 Script ✓
- Add backwards-compatibility detection
- Add migration warnings for existing system installs
- Auto-cleanup of old symlinks when appropriate
- Preserve legacy script as `install-legacy.sh`

### Phase 2: Update CI/CD
- Update `.github/workflows/test-install.yml` to use `--system` flag where needed
- Ensure container tests still work (they should, as root detection works)

### Phase 3: Documentation Updates
- Update `docs/pages/documentation/getting-started/installation.mdx`
- Add migration guide for existing users
- Update examples to show both user and system install

### Phase 4: Testing Checklist
- [ ] Fresh install (user-local)
- [ ] Fresh install with --system
- [ ] Upgrade from v1 (user had system install)
- [ ] Upgrade from v1 (user had user install)
- [ ] Re-install (idempotency)
- [ ] Uninstall (both user and system)
- [ ] Container/Docker install
- [ ] CI workflow tests pass
- [ ] Multi-user system scenarios

## Files to Modify

### Scripts
- [x] Create `scripts/install-legacy.sh` (copy of current install.sh)
- [ ] Replace `scripts/install.sh` with enhanced install_v2.sh
- [ ] Sync to `docs/public/install.sh` (via release tooling)
- [ ] Sync to `docs/public/install-legacy.sh`

### CI/Workflows
- [ ] `.github/workflows/test-install.yml` - Update container test to use `--system` or handle new default
- [ ] Add test for legacy script compatibility

### Documentation
- [ ] `docs/pages/documentation/getting-started/installation.mdx` - Add system install examples
- [ ] `docs/pages/documentation/getting-started/faq.md` - Add migration FAQ

### Tests
- [ ] Update `test/install_script_validation_test.dart` if needed (should pass as-is)

## Backwards Compatibility Features Added to v2

### 1. Existing System Install Detection
```bash
# Detects if user has old system symlink
if [ -L "/usr/local/bin/fvm" ]; then
  # Warn user about behavior change
  # Offer to upgrade system install or switch to user install
fi
```

### 2. Automatic Symlink Cleanup
```bash
# When doing user install, clean up old system symlink if it points to user bin
if [ "$SYSTEM_INSTALL" -eq 0 ] && [ -L "/usr/local/bin/fvm" ]; then
  if [ "$(readlink /usr/local/bin/fvm)" = "${BIN_DIR}/fvm" ]; then
    # Remove old symlink (not needed for user install)
  fi
fi
```

### 3. Legacy Script Fallback
- Keep `install-legacy.sh` for users who need old behavior
- Document in migration guide

## Communication Plan

### Release Notes
```markdown
## FVM Installer v2.0.0 - Breaking Changes

### TL;DR
- Default install is now user-local (no sudo needed)
- For system-wide install, use: `curl -fsSL https://fvm.app/install.sh | bash -s -- --system`

### What Changed
1. **Default install location**: `~/.fvm_flutter/bin` (was `/usr/local/bin`)
2. **No sudo required** for default install
3. **New flag**: `--system` for system-wide installation
4. **New flag**: `--no-modify-path` to skip shell config

### Migration Guide

#### For Individual Users (Recommended)
No action needed. Next install will be user-local.

#### For System-Wide Installations
If you need FVM available to all users:
```bash
curl -fsSL https://fvm.app/install.sh | bash -s -- --system
```

#### For CI/CD Pipelines
If your pipeline expects `/usr/local/bin/fvm`:
- Option 1: Add `--system` flag to install command
- Option 2: Use `~/.fvm_flutter/bin/fvm` directly
- Option 3: Ensure PATH includes `~/.fvm_flutter/bin`

#### Legacy Script
If you need the old behavior:
```bash
curl -fsSL https://fvm.app/install-legacy.sh | bash
```
```

### Documentation Updates
- Homepage: Show user install as primary method
- Installation page: Add "System Install" section
- FAQ: Add "How do I upgrade from v1?" entry

## Rollback Plan
If critical issues discovered:
1. Revert `scripts/install.sh` to v1 (from `install-legacy.sh`)
2. Keep v2 available as `install-v2.sh` for testing
3. Release notes: "v2 postponed, v1 restored"

## Timeline
1. **Prepare** (1 day): Create enhanced v2 script with compatibility logic
2. **Update CI/Docs** (1 day): Update all references and tests
3. **Test** (1-2 days): Run full test suite, manual testing
4. **Deploy**: Merge to main, release tooling will sync to docs/public
5. **Monitor**: Watch for issues, have rollback ready
