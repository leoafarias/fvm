# Issue #421: [Feature Request] fvm install 2: infer the latest minor/patch version when supplying the major version

## Metadata
- **Reporter**: Thor Galle (@th0rgall)
- **Created**: 2022-05-19
- **Reported Version**: 2.x
- **Issue Type**: enhancement
- **URL**: https://github.com/leoafarias/fvm/issues/421

## Problem Summary
The reporter asked for `fvm install 2`/`fvm install 2.10` to behave like other version managers and automatically resolve to the latest matching release. FVM currently requires the exact tag (for example `fvm install 2.10.5`) or a channel (`fvm install stable`).

## Resolution
After evaluating the request we chose to keep installs explicit. Flutter’s release tooling and FVM 4.x both expect concrete versions, and auto-inference would add an extra resolution layer with little demand. The issue was closed on 2025-11-01 with guidance to upgrade to FVM 4.0.0+ and continue pinning exact releases or channels.

## Current Status in v4.0.0
- [ ] Still reproducible
- [ ] Already fixed
- [x] Not applicable to v4.0.0
- [ ] Needs more information
- [ ] Cannot reproduce

## Recommendation
**Action**: closed (won’t implement)

**Reason**: Maintain explicit version selection; users should specify the exact release or channel they need.

## Notes
- Docs include examples for installing specific tags (e.g., `fvm install 3.19.3`) and channels (`fvm install stable`).

---
**Validated by**: Code Agent  
**Date**: 2025-11-01
