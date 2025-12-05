# Issue & PR Triage Report - December 5, 2025

## Executive Summary

**Current State:**
- 52 open issues
- 13 open PRs
- Last sync: October 31, 2025 (35 days ago)

**Key Findings:**
- 9 issues in `resolved/` folder are now CLOSED on GitHub → need folder cleanup
- Several community PRs are ready for review/merge
- 5 new bugs reported in last 2 months need triage

---

## URGENT: Issues Requiring Immediate Attention

### P0 - Critical Bugs

| Issue | Title | Impact | Recommended Action |
|-------|-------|--------|-------------------|
| **#971** | `fvm install` erases `updateVscodeSettings` | Data loss - user config destroyed | **Fix ASAP** - has clear root cause in issue |
| **#982** | `fvm run` adds newline to output | Breaks tooling (protobuf codegen) | Investigate stdout handling |

### P1 - High Priority

| Issue | Title | Status |
|-------|-------|--------|
| #974 | Binary/symlink cross-user issues | Valid concern - relates to PR #967 |
| #968 | Fail aggressively on SDK setup | UX improvement needed |
| #969 | RISC-V Dart SDK architecture | Upstream Flutter limitation |

---

## PR Status & Recommendations

### Community PRs - Ready for Action

| PR | Title | CI Status | Recommendation |
|----|-------|-----------|----------------|
| **#981** | Fix fork version cache | ✅ All tests pass | **Merge after contributor fixes line 41** - you already reviewed |
| **#962** | Security: full commit hashes | ✅ Vercel passes | **Review for v4 compatibility** - fixes #783 |
| **#775** | Nix Flake support | Mergeable | Review - addresses #811, 15 months old |
| **#845** | ARM64 Docker images | Unknown | Review for v4 - addresses #762, 7 months old |
| **#828** | Dart SDK column in releases | Unknown | Small feature - 9 months old |

### Leo's PRs - Status Check

| PR | Title | Mergeable | Updated | Notes |
|----|-------|-----------|---------|-------|
| **#976** | Git cache mirrored architecture | ✅ Yes | Today | Ready to merge? |
| **#967** | Install script v2 | ✅ Yes | Dec 2 | Major change - relates to #974 feedback |
| **#966** | Archive-based installation | ✅ Yes | Dec 4 | Addresses #688 |
| #965 | FVM MCP server | - | Dec 2 | New package |
| #973 | Update check improvements | - | Nov 14 | Stale? |
| #948 | Dart SDK constraint for Homebrew | - | Oct 31 | Addresses #940 |
| #923 | Testing infrastructure | - | Sep 25 | 2.5 months old |
| #920 | Docs language cleanup | - | Sep 25 | 2.5 months old |

---

## Folder Cleanup Required

### `resolved/` folder → All CLOSED on GitHub

These 9 issues need to be moved to `closed/`:

| Issue | GitHub State |
|-------|--------------|
| #388 | CLOSED |
| #771 | CLOSED |
| #786 | CLOSED |
| #799 | CLOSED |
| #801 | CLOSED |
| #825 | CLOSED |
| #833 | CLOSED |
| #880 | CLOSED |
| #933 | CLOSED |

**Action:** Move all JSON files from `resolved/` to `closed/`

---

## Issues Ready to Close (with PRs)

| Issue | Title | Resolution |
|-------|-------|------------|
| **#783** | Short hash DOS attack | PR #962 ready (pending review) |
| **#688** | FLUTTER_STORAGE_BASE_URL | PR #966 in progress |
| **#762** | ARM64 Docker images | PR #845 ready (needs review) |
| **#811** | Nix package | PR #775 ready (needs review) |

---

## Recent Issues Summary (Oct-Dec 2025)

### Bugs (5 new)
1. **#982** (Nov 28) - fvm run newline - **P0**
2. **#974** (Nov 15) - Binary/symlink issues - **P1**
3. **#971** (Nov 14) - VSCode settings erased - **P0**
4. **#969** (Nov 12) - RISC-V SDK - P2 (upstream)
5. **#968** (Nov 12) - SDK setup error handling - P2

### Older Issues with Recent Activity
- #897 (Jul 24, updated Nov 15) - .bash_profile warning
- #914 (Sep 18, updated Nov 6) - Git not in PATH
- #724 (May 24, updated Nov 12) - Android Studio SDK path

---

## Recommended Action Plan

### Immediate (This Week)

1. **Fix #971** - VSCode settings being erased
   - Root cause identified in issue
   - One-line fix in `project_service.dart`

2. **Review PR #981** - Fork version cache fix
   - All CI passes
   - Just needs contributor to fix one line

3. **Move resolved/ → closed/**
   - All 9 issues confirmed CLOSED on GitHub

### Short-term (Next 2 Weeks)

4. **Review PR #962** - Security fix for #783
   - Check v4 compatibility
   - Merge if tests pass

5. **Investigate #982** - fvm run newline bug
   - Affects protobuf codegen users
   - Check stdout handling in runner

6. **Decide on stale PRs** (#923, #920)
   - 2.5 months old
   - Merge or close?

### Medium-term

7. **Review community PRs** (#775, #845, #828)
   - All waiting 7+ months
   - Close or merge to clear backlog

8. **Merge your feature PRs** (#976, #967, #966)
   - All mergeable
   - Major improvements waiting

---

## Statistics

| Category | Count |
|----------|-------|
| Open Issues | 52 |
| Open PRs | 13 |
| Issues in resolved/ needing cleanup | 9 |
| PRs ready to merge (after fixes) | 2 |
| Critical bugs (P0) | 2 |
| Community PRs waiting review | 5 |

---

## Files to Update

- [x] `pending_issues/open_issues.json` - Synced
- [x] `pending_issues/open_prs.json` - Synced
- [ ] Move `resolved/*.json` → `closed/`
- [ ] Update `sync-summary.md` with new date
- [ ] Add new issues to `validated/` folders
