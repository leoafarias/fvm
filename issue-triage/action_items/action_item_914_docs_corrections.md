# Documentation Structure Corrections for Action Item #914

## Actual FVM Docs Structure

After verifying the actual documentation structure, here are the **corrected paths and details**:

### Current Documentation Structure
```
docs/
├── pages/
│   ├── _meta.json
│   └── documentation/
│       ├── _meta.json              # Top-level navigation
│       ├── getting-started/
│       │   ├── _meta.json         # Section navigation
│       │   ├── index.md           # Overview page
│       │   ├── installation.mdx
│       │   ├── configuration.mdx
│       │   └── faq.md             # FAQ (line 111-132 has Git issue)
│       ├── guides/
│       │   ├── _meta.json
│       │   ├── quick-reference.md
│       │   ├── monorepo.md
│       │   └── ...
│       └── advanced/
│           ├── _meta.json
│           ├── json-api.md
│           └── ...
```

### URL Pattern
- Base: `https://fvm.app`
- Documentation: `https://fvm.app/documentation/{section}/{page}`
- Example: `https://fvm.app/documentation/getting-started/faq`

---

## CORRECTED: Files to Create

### 1. Create Troubleshooting Directory and Files

#### 1.1 Create: `docs/pages/documentation/troubleshooting/_meta.json`
```json
{
  "index": {
    "title": "Troubleshooting"
  },
  "git-safe-directory-windows": {
    "title": "Git Safe Directory (Windows)"
  }
}
```

#### 1.2 Create: `docs/pages/documentation/troubleshooting/index.md`
```markdown
---
id: troubleshooting
title: "Troubleshooting"
---

# Troubleshooting Guide

Common issues and solutions for FVM.

## Windows Issues

- **[Git Safe Directory Error](/documentation/troubleshooting/git-safe-directory-windows)** - "Unable to find git in your PATH" on Windows

## macOS Issues

Coming soon.

## Linux Issues

Coming soon.

## General Issues

- **Flutter version not switching** - Check your PATH configuration
- **Permission errors** - Verify file permissions on cache directory
- **Network issues** - Check proxy settings and firewall

## Need More Help?

- Check our [FAQ](/documentation/getting-started/faq)
- Search [existing issues](https://github.com/leoafarias/fvm/issues)
- [Open a new issue](https://github.com/leoafarias/fvm/issues/new)
```

#### 1.3 Create: `docs/pages/documentation/troubleshooting/git-safe-directory-windows.md`

**Corrected frontmatter** (remove `keywords`, use `id`):
```markdown
---
id: git-safe-directory-windows
title: "Git Safe Directory Error on Windows"
description: "Fix 'Unable to find git in your PATH' error on Windows when using FVM"
---

# Git Safe Directory Error on Windows

## Symptoms

You're running FVM commands on Windows and see:
```
Error: Unable to find git in your PATH.
```

But you know Git is installed because `git --version` works fine in your terminal.

[... rest of content as specified in original action item ...]
```

---

## CORRECTED: Files to Modify

### 2. Update: `docs/pages/documentation/_meta.json`

**Current content:**
```json
{
  "-- Getting Started": {
    "type": "separator",
    "title": "Getting Started"
  },
  "getting-started": {
    "title": "Getting Started",
    "display": "children"
  },
  "-- Guides": {
    "type": "separator",
    "title": "Guides"
  },
  "guides": {
    "title": "Guides",
    "display": "children"
  },
  "-- Advanced": {
    "type": "separator",
    "title": "Advanced"
  },
  "advanced": {
    "title": "Advanced",
    "display": "children"
  }
}
```

**Add troubleshooting section** (after Getting Started, before Guides):
```json
{
  "-- Getting Started": {
    "type": "separator",
    "title": "Getting Started"
  },
  "getting-started": {
    "title": "Getting Started",
    "display": "children"
  },
  "-- Troubleshooting": {
    "type": "separator",
    "title": "Troubleshooting"
  },
  "troubleshooting": {
    "title": "Troubleshooting",
    "display": "children"
  },
  "-- Guides": {
    "type": "separator",
    "title": "Guides"
  },
  "guides": {
    "title": "Guides",
    "display": "children"
  },
  "-- Advanced": {
    "type": "separator",
    "title": "Advanced"
  },
  "advanced": {
    "title": "Advanced",
    "display": "children"
  }
}
```

### 3. Update: `docs/pages/documentation/getting-started/faq.md`

**Location**: Lines 111-132

**Current content:**
```markdown
## Git not found after install on Windows

Some users may be greeted by this error after installing FVM in a project.

```bash
Error: Unable to find git in your PATH.
```

This happens because of a security update from Git where Git now checks for ownership of the folder, trying to ensure that the folder you are using Git in has the same user as the owner as your current user account.
To fix this, we need to mark our repos as safe using the following command:

```bash
git config --global --add safe.directory '*'
```

Restart your terminals and VS Code after running this command. This should fix the issue.

If you don't want to mark all the repos as safe, then you can mark only the Flutter repo as safe by passing the Flutter path instead of `*`:

```bash
git config --global --add safe.directory C:\Users\someUser\flutter\.git\
```
```

**Replace with:**
```markdown
## Git not found after install on Windows

Some users may be greeted by this error after installing FVM in a project:

```bash
Error: Unable to find git in your PATH.
```

**This is not actually a PATH issue.** Git is installed, but it's refusing to operate due to security settings introduced in Git 2.35.2+.

### Quick Fix

Run this command once:

```bash
git config --global --add safe.directory '*'
```

Then restart your terminal and IDE.

### Need More Details?

👉 **See our comprehensive guide**: [Git Safe Directory Error on Windows](/documentation/troubleshooting/git-safe-directory-windows)

This guide includes:
- Detailed explanation of why this happens
- Alternative solutions
- Security implications
- Troubleshooting steps
```

---

## CORRECTED: URL References

### In Documentation
When linking to the new troubleshooting page from within documentation:
```markdown
[Git Safe Directory Error](/documentation/troubleshooting/git-safe-directory-windows)
```

**Full URL**: `https://fvm.app/documentation/troubleshooting/git-safe-directory-windows`

### In Code (Doctor Check)
```dart
'Learn more: https://fvm.app/documentation/troubleshooting/git-safe-directory-windows'
```

### In GitHub Issues
When commenting on issues #569, #589, #789, #914:
```markdown
This issue is now documented with solutions at:
https://fvm.app/documentation/troubleshooting/git-safe-directory-windows

We've also added a `fvm doctor` check that will detect this condition and provide guidance.
```

---

## CORRECTED: Complete File List

### New Files (5 files)
1. ✅ `docs/pages/documentation/troubleshooting/_meta.json` - Navigation config
2. ✅ `docs/pages/documentation/troubleshooting/index.md` - Troubleshooting index
3. ✅ `docs/pages/documentation/troubleshooting/git-safe-directory-windows.md` - Main guide
4. ✅ `lib/src/commands/doctor/checks/git_config_check.dart` - Doctor check
5. ✅ `test/src/commands/doctor/checks/git_config_check_test.dart` - Tests

### Modified Files (3 files)
1. ✅ `docs/pages/documentation/_meta.json` - Add troubleshooting section
2. ✅ `docs/pages/documentation/getting-started/faq.md` - Update lines 111-132
3. ✅ `lib/src/commands/doctor_command.dart` - Register new check

---

## Implementation Checklist

### Phase 1: Documentation Setup
- [ ] Create `docs/pages/documentation/troubleshooting/` directory
- [ ] Create `_meta.json` for troubleshooting section
- [ ] Create `index.md` for troubleshooting overview
- [ ] Create `git-safe-directory-windows.md` with full guide
- [ ] Update main `_meta.json` to add troubleshooting to navigation
- [ ] Update FAQ with link to new guide

### Phase 2: Doctor Check
- [ ] Create `git_config_check.dart` in appropriate location
- [ ] Register check in doctor command
- [ ] Create unit tests
- [ ] Test on Windows with Git 2.46+
- [ ] Test on macOS (should skip)
- [ ] Test on Linux (should skip)

### Phase 3: Verification
- [ ] Local dev server: verify pages render correctly
- [ ] Verify navigation shows troubleshooting section
- [ ] Verify links work (internal and external)
- [ ] Test search functionality finds the page
- [ ] Run `fvm doctor` and verify output format

### Phase 4: Deployment
- [ ] Deploy to staging
- [ ] Verify on staging environment
- [ ] Merge PR
- [ ] Deploy to production
- [ ] Verify production URL works

### Phase 5: Communication
- [ ] Update issues #569, #589, #789, #914 with link
- [ ] Tweet about new troubleshooting guide
- [ ] Update Discord with pinned message

---

## Testing URLs

After deployment, verify these URLs:

✅ Main guide: `https://fvm.app/documentation/troubleshooting/git-safe-directory-windows`
✅ Troubleshooting index: `https://fvm.app/documentation/troubleshooting`
✅ FAQ link works: `https://fvm.app/documentation/getting-started/faq#git-not-found-after-install-on-windows`

---

## SEO Verification

### Meta Tags (in git-safe-directory-windows.md)
The Nextra theme will automatically generate meta tags from the frontmatter:
- `title` → `<title>` tag
- `description` → `<meta name="description">` tag

### Expected Search Results
After indexing, the page should appear for:
- "fvm unable to find git in your path"
- "flutter unable to find git windows"
- "git safe.directory fvm"
- "fvm windows git error"
- "CVE-2022-24765 flutter"

### Structured Data
Nextra automatically handles:
- Open Graph tags
- Twitter Card tags
- Canonical URLs
- Sitemap generation

---

## Notes

### Nextra-Specific Features
- Uses `.md` or `.mdx` (MDX supports React components)
- Frontmatter must have `id` and `title`
- `_meta.json` controls navigation order and titles
- Automatic table of contents from headings
- Automatic prev/next navigation
- Built-in search functionality

### File Extensions
- Use `.md` for pure markdown
- Use `.mdx` if you need JSX/React components (not needed for this guide)

### Path Separators
- In markdown links: use `/` (forward slash)
- In Windows paths shown to users: use `\` (backslash) in text, but `/` in code examples
- In Git config: always use `/` (forward slash)

---

## Quick Reference: Correct Paths

| Purpose | Path |
|---------|------|
| New guide file | `docs/pages/documentation/troubleshooting/git-safe-directory-windows.md` |
| Troubleshooting index | `docs/pages/documentation/troubleshooting/index.md` |
| Navigation config | `docs/pages/documentation/troubleshooting/_meta.json` |
| Main nav config | `docs/pages/documentation/_meta.json` |
| FAQ to update | `docs/pages/documentation/getting-started/faq.md` (lines 111-132) |
| Doctor check | `lib/src/commands/doctor/checks/git_config_check.dart` |
| URL (production) | `https://fvm.app/documentation/troubleshooting/git-safe-directory-windows` |
| Link from docs | `/documentation/troubleshooting/git-safe-directory-windows` |

---

This correction document ensures all paths, file structures, and URLs are accurate for the FVM documentation system using Nextra.
