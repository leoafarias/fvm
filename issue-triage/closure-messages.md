# Closure Messages for Issues & PRs

## Issues to Close (Already Resolved)

### Issue #915 - Documentation broken links
```
Thanks for reporting this! This has been fixed in PR #937 and is now live on fvm.app. The documentation links now correctly resolve to `/documentation/getting-started/installation` and related pages.

Closing as resolved in v4.0.0.
```

### Issue #944 - 404 for /documentation/installation
```
Fixed in PR #937. The Getting Started page now uses explicit paths that correctly resolve to the installation guide. Thanks for catching this!

Closing as resolved in v4.0.0.
```

### Issue #935 - RISC-V architecture support
```
Fixed in PR #946! RISC-V (riscv64) architecture is now supported in the install scripts. The binaries have been available since v4.0.0 was released - we just needed to add the architecture detection logic.

Closing as resolved in v4.0.0.
```

### Issue #938 - Cannot resolve symbolic links (doctor crash)
```
Fixed in PR #947! The `fvm doctor` command now properly guards against missing symlinks when `local.properties` exists but no version is pinned.

Closing as resolved in v4.0.0.
```

---

## PRs to Close (Already Implemented)

### PR #840 - @twogood - Add newline after `.fvm/` in .gitignore

```
Thanks for this contribution @twogood!

This fix was already implemented in commit 50fa23b9 (Aug 23, 2025) as part of a broader set of bug fixes. The `.gitignore` workflow now ensures files end with a proper newline.

Closing as already resolved, but we really appreciate you taking the time to contribute! 🙏

Resolves #839
```

### PR #838 - @ipcjs - Create symlink in ~/.local/bin
**Check first**: Is #832 resolution related to this PR? If so:
```
Thanks for this PR @ipcjs!

Closing as issue #832 has been resolved. If you feel this approach is still valuable, please feel free to reopen with context on how it improves upon the current solution.

Appreciate the contribution! 🙏
```

---

## Old PRs Likely Obsolete (Check First, Then Close)

### PR #727 - @rsanjuan87 - Update not listed (May 2024)
**Action**: Check if v4.0.0 changes make this obsolete
```
Thanks for this PR @rsanjuan87!

With the release of v4.0.0, the update mechanisms have been significantly refactored. Could you check if this issue still exists in the latest release? If so, please feel free to reopen or create a new PR based on the current codebase.

Closing as potentially obsolete with v4.0.0. Thanks for your contribution! 🙏
```

### PR #806 - @j-j-gajjar - Version format validation (Dec 2024)
**Action**: Test if this behavior is still wanted/needed
```
Thanks for this PR @j-j-gajjar!

With the release of v4.0.0, version handling has been updated. Before we can merge this, could you:
1. Rebase on the current main branch
2. Confirm this validation is still needed with the v4.0.0 behavior
3. Update tests if necessary

Let us know if you're still interested in maintaining this PR. Otherwise, we'll close it for now. Thanks! 🙏
```

### PR #824 - @alanionita - Clean up Linux docs (Feb 2025)
**Action**: Check if docs were already updated
```
Thanks @alanionita!

The documentation has gone through several updates during the v4.0.0 release cycle. Could you check if these changes are still needed on the current docs site (fvm.app)?

If so, please rebase on main and we'll get this merged. Otherwise, closing as likely resolved. Thanks for the contribution! 🙏
```

---

## PRs Needing Review (Priority Order)

### 🔥 High Priority

#### PR #775 - @mikeborodin - Nix Flake support
- **Validated Issue**: #811 (P2-Medium)
- **Age**: 14 months (Sep 2024)
- **Status**: Needs rebase on v4.0.0
- **Review Focus**:
  - Does flake.nix work with v4.0.0?
  - Is this the right approach for Nix support?
  - Community interest confirmed in issue #811

#### PR #845 - @AngeloAvv - arm64 docker images
- **Validated Issue**: #762 (P2-Medium)
- **Age**: 6 months (May 2025)
- **Status**: Needs review
- **Review Focus**:
  - Does this work with current Dockerfile?
  - CI/CD pipeline updates needed?
  - Test multi-arch builds

#### PR #929 - @loic-peron-inetum-public - Standalone executables
- **Issue**: #891
- **Age**: Recent (Sep 2025)
- **Status**: Active development
- **Review Focus**:
  - What's the use case?
  - Does it work with v4.0.0?
  - Breaking changes?

### 📋 Medium Priority

#### PR #834 - @shinriyo - Wildcard support for remove
- **Validated Issue**: #833 (P3-Low)
- **Age**: 7 months (Mar 2025)
- **Status**: Simple change, needs review
- **Review Focus**:
  - Does the wildcard pattern work correctly?
  - Edge cases (empty matches, invalid patterns)?
  - UX: Should there be confirmation?

#### PR #905 - @YannickRtz - Update PATH docs
- **Age**: 2 months (Sep 2025)
- **Status**: Quick docs review
- **Review Focus**:
  - Is the PATH documentation accurate for v4.0.0?
  - Merge or suggest improvements

#### PR #828 - @filippo-signorini - Dart SDK column
- **Age**: 7 months (Mar 2025)
- **Status**: Nice-to-have feature
- **Review Focus**:
  - Does it still work?
  - Is the output format good?
  - Rebase needed?

---

## Issues Still Needing PRs

### P1-High (No PR)
- **#940** - Homebrew Dart SDK 3.2.6 version conflict
- **#914** - Windows git safe.directory auto-config

### P3-Low (No PR)
- **#933** - Chocolatey title improvement

---

## Review Workflow Recommendation

1. **Week 1**: Priority PRs
   - [ ] PR #775 (Nix) - Ask contributor to rebase
   - [ ] PR #845 (arm64 docker) - Test and merge
   - [ ] PR #929 (standalone) - Review and decide

2. **Week 2**: Medium priority + Cleanup
   - [ ] PR #834 (wildcard) - Quick review and merge
   - [ ] PR #905 (PATH docs) - Quick review and merge
   - [ ] Close obsolete PRs (#727, #806, #824, #838, #840)

3. **Week 3**: Create PRs for remaining validated issues
   - [ ] #940 (Homebrew)
   - [ ] #914 (Windows git)
   - [ ] #933 (Chocolatey)
