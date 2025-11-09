# FVM Install Script v2 Testing Checklist

## Pre-Deployment Testing

Before merging the v2 installer changes, verify all scenarios below work correctly.

---

## 1. Fresh Install Scenarios

### 1.1 User Install (Default)
```bash
# Clean environment
./scripts/install.sh --uninstall
rm -rf ~/.fvm_flutter

# Test default install
./scripts/install.sh

# Verify
[ -f ~/.fvm_flutter/bin/fvm ] || echo "FAIL: Binary not installed"
[ ! -f /usr/local/bin/fvm ] || echo "FAIL: System install unexpected"
fvm --version || echo "FAIL: fvm not in PATH"
```
**Expected**: ✅ User install to `~/.fvm_flutter/bin`, no sudo needed

### 1.2 System Install (Explicit)
```bash
# Clean environment
./scripts/install.sh --uninstall

# Test system install
./scripts/install.sh --system

# Verify
[ -f /usr/local/bin/fvm ] || echo "FAIL: System binary not installed"
[ -f ~/.fvm_flutter/bin/fvm ] || echo "FAIL: User binary also needed"
/usr/local/bin/fvm --version || echo "FAIL: System binary broken"
```
**Expected**: ✅ Binary copied to `/usr/local/bin/fvm`, user binary also present

### 1.3 Install with --no-modify-path
```bash
# Backup shell configs
cp ~/.bashrc ~/.bashrc.bak
cp ~/.zshrc ~/.zshrc.bak 2>/dev/null || true

# Install without PATH modification
./scripts/install.sh --no-modify-path

# Verify
grep -q '.fvm_flutter/bin' ~/.bashrc && echo "FAIL: bashrc modified" || echo "PASS"
grep -q '.fvm_flutter/bin' ~/.zshrc && echo "FAIL: zshrc modified" || echo "PASS"

# Restore configs
mv ~/.bashrc.bak ~/.bashrc
mv ~/.zshrc.bak ~/.zshrc 2>/dev/null || true
```
**Expected**: ✅ Install succeeds, no shell config modifications

---

## 2. Upgrade Scenarios

### 2.1 Upgrade from v1 (System Symlink)
```bash
# Simulate v1 install
mkdir -p ~/.fvm_flutter/bin
echo "#!/bin/bash" > ~/.fvm_flutter/bin/fvm
echo "echo 'FVM v1'" >> ~/.fvm_flutter/bin/fvm
chmod +x ~/.fvm_flutter/bin/fvm
sudo ln -sf ~/.fvm_flutter/bin/fvm /usr/local/bin/fvm

# Verify v1 state
[ -L /usr/local/bin/fvm ] || echo "FAIL: Setup incomplete"

# Run v2 installer (non-interactive)
yes | ./scripts/install.sh

# Verify migration
[ ! -L /usr/local/bin/fvm ] || echo "FAIL: Old symlink not removed"
[ -f ~/.fvm_flutter/bin/fvm ] || echo "FAIL: User binary not installed"
fvm --version || echo "FAIL: fvm broken after upgrade"
```
**Expected**: ✅ Old symlink removed, new user install, migration message shown

### 2.2 Upgrade from v1 with --system
```bash
# Simulate v1 install
mkdir -p ~/.fvm_flutter/bin
sudo ln -sf ~/.fvm_flutter/bin/fvm /usr/local/bin/fvm

# Run v2 installer with system flag
./scripts/install.sh --system

# Verify
[ -f /usr/local/bin/fvm ] || echo "FAIL: System binary not installed"
[ ! -L /usr/local/bin/fvm ] || echo "FAIL: Still a symlink (should be copy)"
```
**Expected**: ✅ System binary is now a copy (not symlink)

### 2.3 Repeated Installs (Idempotency)
```bash
# Install twice
./scripts/install.sh
./scripts/install.sh

# Verify shell configs don't have duplicate PATH entries
PATH_ENTRIES=$(grep -c '.fvm_flutter/bin' ~/.bashrc)
[ "$PATH_ENTRIES" -eq 1 ] || echo "FAIL: Duplicate PATH entries: $PATH_ENTRIES"
```
**Expected**: ✅ No duplicate PATH entries, no errors

---

## 3. Uninstall Scenarios

### 3.1 Uninstall User Install
```bash
# Install then uninstall
./scripts/install.sh
./scripts/install.sh --uninstall

# Verify cleanup
[ ! -d ~/.fvm_flutter ] || echo "FAIL: User dir still exists"
[ ! -f /usr/local/bin/fvm ] || echo "FAIL: System binary still exists"
command -v fvm && echo "FAIL: fvm still in PATH" || echo "PASS"
```
**Expected**: ✅ All FVM files removed

### 3.2 Uninstall System Install
```bash
# Install system then uninstall
./scripts/install.sh --system
./scripts/install.sh --uninstall

# Verify
[ ! -f /usr/local/bin/fvm ] || echo "FAIL: System binary still exists"
[ ! -d ~/.fvm_flutter ] || echo "FAIL: User dir still exists"
```
**Expected**: ✅ Both user and system files removed

### 3.3 Uninstall on Clean System (Idempotency)
```bash
# Uninstall when nothing installed
./scripts/install.sh --uninstall
./scripts/install.sh --uninstall

# Verify
echo "Should complete without errors"
```
**Expected**: ✅ Graceful handling, no errors

---

## 4. Platform-Specific Tests

### 4.1 macOS
```bash
# Test on macOS
uname -s # Should be Darwin

# Install
./scripts/install.sh

# Verify .bash_profile updated (macOS-specific)
[ -f ~/.bash_profile ] && grep -q '.fvm_flutter/bin' ~/.bash_profile || echo "WARN: bash_profile"

# Test architecture detection
arch=$(uname -m)
echo "Architecture: $arch"  # Should be x86_64 or arm64
```
**Expected**: ✅ Correct architecture detected, bash_profile updated

### 4.2 Linux (Ubuntu)
```bash
# Test on Ubuntu
cat /etc/os-release | grep Ubuntu

# Install
./scripts/install.sh

# Verify glibc
ldd --version
```
**Expected**: ✅ Installs correctly, glibc detected

### 4.3 Linux (Alpine/musl)
```bash
# Test on Alpine
cat /etc/os-release | grep Alpine

# Install
./scripts/install.sh

# Verify musl detection and fallback
echo "Check installer output for musl detection"
```
**Expected**: ✅ Detects musl, tries musl binary, falls back to glibc if needed

---

## 5. Special Environment Tests

### 5.1 Container (Docker)
```bash
# In Dockerfile or container
docker run -it --rm ubuntu:latest bash -c '
  apt-get update && apt-get install -y curl tar gzip git
  curl -fsSL https://raw.githubusercontent.com/leoafarias/fvm/main/scripts/install.sh | bash -s -- --system
  /usr/local/bin/fvm --version
'
```
**Expected**: ✅ Detects container, allows root, installs to system

### 5.2 CI Environment
```bash
# Simulate CI (GitHub Actions)
export CI=true

# Install without sudo
./scripts/install.sh

# Should work as root in CI
sudo ./scripts/install.sh
```
**Expected**: ✅ Root allowed in CI, no errors

### 5.3 Root Without CI (Should Block)
```bash
# On non-container, non-CI system
sudo ./scripts/install.sh 2>&1 | grep "refusing to run as root"
[ $? -eq 0 ] || echo "FAIL: Root not blocked"
```
**Expected**: ✅ Error message about root being blocked

### 5.4 Root Override
```bash
# Force root install
sudo env FVM_ALLOW_ROOT=true ./scripts/install.sh --system

# Verify
[ -f /usr/local/bin/fvm ] || echo "FAIL: System install failed"
```
**Expected**: ✅ Root override works

---

## 6. Version Specification Tests

### 6.1 Latest Version
```bash
./scripts/install.sh

# Verify latest
fvm --version | head -n1
```
**Expected**: ✅ Installs most recent release

### 6.2 Specific Version
```bash
./scripts/install.sh 4.0.0

# Verify
fvm --version | grep "4.0.0" || echo "FAIL: Wrong version"
```
**Expected**: ✅ Installs specified version

### 6.3 Version with 'v' Prefix
```bash
./scripts/install.sh v4.0.0

# Verify normalizes correctly
fvm --version | grep "4.0.0" || echo "FAIL: Version normalization failed"
```
**Expected**: ✅ Handles 'v' prefix correctly

---

## 7. Error Handling Tests

### 7.1 Invalid Version
```bash
./scripts/install.sh 999.999.999 2>&1 | grep "asset not found"
[ $? -eq 0 ] || echo "FAIL: Should report asset not found"
```
**Expected**: ✅ Clear error message

### 7.2 No Internet
```bash
# Disconnect network or block github.com
./scripts/install.sh 2>&1 | grep -i "failed\|error"
```
**Expected**: ✅ Graceful error handling

### 7.3 Corrupt Download
```bash
# Simulate corrupt download (requires manual intervention)
# Create fake tarball
echo "corrupt" > /tmp/fvm.tar.gz
# Test would fail validation
```
**Expected**: ✅ Detects corruption, exits with error

---

## 8. Migration Warning Tests

### 8.1 Interactive Migration Warning
```bash
# Simulate v1 system install
sudo ln -sf ~/.fvm_flutter/bin/fvm /usr/local/bin/fvm

# Run v2 interactively (requires manual "yes")
./scripts/install.sh
# Should show warning about migration
```
**Expected**: ✅ Shows migration warning, asks for confirmation

### 8.2 Non-Interactive Migration (Piped)
```bash
# Simulate v1 install
sudo ln -sf ~/.fvm_flutter/bin/fvm /usr/local/bin/fvm

# Run via pipe (non-interactive)
curl -fsSL https://raw.githubusercontent.com/leoafarias/fvm/main/scripts/install.sh | bash

# Should not prompt, just show note
```
**Expected**: ✅ No prompt, shows informational message

---

## 9. Automated CI Tests

### 9.1 Run Full CI Suite
```bash
# Trigger GitHub Actions workflow
git push origin your-branch

# Monitor:
# - validate job (shellcheck)
# - test-install job (ubuntu + macos)
# - test-container job (Docker)
# - test-permissions job (root blocking)
```
**Expected**: ✅ All CI jobs pass

### 9.2 Validation Test Pass
```bash
# Run the Dart validation test locally
dart test test/install_script_validation_test.dart
```
**Expected**: ✅ scripts/install.sh matches docs/public/install.sh

---

## 10. Legacy Script Tests

### 10.1 Legacy Script Still Works
```bash
# Test install-legacy.sh
./scripts/install-legacy.sh

# Verify old behavior (system symlink)
[ -L /usr/local/bin/fvm ] || echo "FAIL: Legacy should create symlink"
```
**Expected**: ✅ Legacy script maintains v1 behavior

---

## Sign-Off Checklist

Before deploying to production:

- [ ] All fresh install scenarios pass
- [ ] All upgrade scenarios pass
- [ ] All uninstall scenarios pass
- [ ] Platform-specific tests pass (macOS, Ubuntu, Alpine)
- [ ] Container/CI tests pass
- [ ] Version specification tests pass
- [ ] Error handling is graceful
- [ ] Migration warnings display correctly
- [ ] CI workflows pass (GitHub Actions)
- [ ] Validation test passes (scripts match docs/public)
- [ ] Legacy script available and works
- [ ] Documentation updated
- [ ] Release notes prepared

---

## Rollback Plan

If critical issues found post-deployment:

1. Revert to legacy:
   ```bash
   cp scripts/install-legacy.sh scripts/install.sh
   cp scripts/install-legacy.sh docs/public/install.sh
   ```

2. Commit and push:
   ```bash
   git add scripts/install.sh docs/public/install.sh
   git commit -m "revert: rollback to v1 installer due to [issue]"
   git push
   ```

3. Keep v2 as `install-v2.sh` for further testing

---

## Notes

- Test on clean VMs/containers when possible
- Check both interactive and non-interactive modes
- Verify shell config files don't get corrupted
- Test with different shells (bash, zsh, fish)
- Monitor for permission errors
- Check both Intel and ARM architectures
