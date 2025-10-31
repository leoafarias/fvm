# Issue #895: Hi, may I ask when version 4.0.0 will be fully released?

## Metadata
- **Reporter**: @HenryGaoGH
- **Created**: 2025-07-20
- **Reported Version**: Asking about FVM 4.0.0 availability
- **Issue Type**: question
- **URL**: https://github.com/leoafarias/fvm/issues/895

## Problem Summary
In July 2025 the reporter noted that documentation already referenced FVM 4.0.0 but package managers (e.g., Homebrew) hadn’t published the release yet.

## Validation Steps
1. Checked `pubspec.yaml` (current branch) — version is `4.0.0`.
2. Inspected the Homebrew tap (`homebrew-fvm/fvm.rb`) and confirmed it now points to the 4.0.0 tarball and sha256.
3. Verified `CHANGELOG.md` lists 4.0.0 (Oct 30 2025 release).

## Evidence
```
$ nl -ba pubspec.yaml | head -n 6
1 name: fvm
4 version: 4.0.0

$ curl -s https://raw.githubusercontent.com/leoafarias/homebrew-fvm/master/fvm.rb | head -n 8
url "https://github.com/leoafarias/fvm/archive/4.0.0.tar.gz"
sha256 "18cf7634..."
```

## Current Status in v4.0.0
- [ ] Still reproducible
- [x] Already fixed / release live
- [ ] Not applicable to v4.0.0
- [ ] Needs more information

## Recommendation
Close as resolved (release is out and distribution updated). Reply with confirmation and links to package manager instructions.

## Classification Recommendation
- Folder: `resolved/`
