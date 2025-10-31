# Issue #782: `Bad substitution` in when calling global packages

## Metadata
- **Reporter**: @dickermoshe
- **Created**: 2024-09-16
- **Reported Version**: Docs (v3.x)
- **Issue Type**: documentation bug
- **URL**: https://github.com/leoafarias/fvm/issues/782

## Problem Summary
The docs tell users to create shim scripts containing `fvm flutter ${@:1}` / `fvm dart ${@:1}`. On Linux these shims often run under `/bin/sh`, which does not support the `${@:1}` bash extension, leading to `bad substitution`. The correct portable form is `"$@"`.

## Version Context
- Reported against: documentation for v3.x
- Current version: v4.0.0
- Version-specific: no
- Reason: The doc snippet is still present in v4.0.0 and continues to produce the error.

## Validation Steps
1. Located the offending snippet in `docs/pages/documentation/guides/running-flutter.mdx:69-77`.
2. Confirmed `/bin/sh` on Ubuntu reproduces `bad substitution` when executing the example.
3. Verified no updated guidance exists elsewhere in the docs.

## Evidence
```
docs/pages/documentation/guides/running-flutter.mdx:69-77  // Uses ${@:1} causing bad substitution
```

**Files/Code References:**
- [docs/pages/documentation/guides/running-flutter.mdx:69](../docs/pages/documentation/guides/running-flutter.mdx#L69) – Doc snippet that must be updated to `"$@"`.

## Current Status in v4.0.0
- [x] Still reproducible
- [ ] Already fixed
- [ ] Not applicable to v4.0.0
- [ ] Needs more information
- [ ] Cannot reproduce

## Troubleshooting/Implementation Plan

### Root Cause Analysis
Documentation uses bash-specific parameter expansion inside scripts likely executed by `/bin/sh`. This causes shell errors for users following the instructions verbatim.

### Proposed Solution
1. Update the docs to recommend `fvm flutter "$@"` / `fvm dart "$@"`.
2. Add explicit shebang (`#!/usr/bin/env bash`) if the doc wants to demonstrate bash-specific syntax, or keep scripts POSIX-compliant.
3. Add a short explanation that `"$@"` forwards all arguments safely.
4. Optionally provide a PowerShell example for Windows parity.

### Alternative Approaches
- Could suggest using aliases or PATH symlinks instead of scripts; still mention in doc.

### Dependencies & Risks
- Documentation update only.

### Related Code Locations
- [docs/pages/documentation/guides/running-flutter.mdx](../docs/pages/documentation/guides/running-flutter.mdx) – Single place requiring the edit.

## Recommendation
**Action**: validate-p2  
**Reason**: Documentation fix required before closing; issue remains reproducible in current docs.

## Draft Reply
```
Thanks for catching this! The docs still show `fvm flutter ${@:1}`, which only works in bash. We’re updating the guide to use the portable form `fvm flutter "$@"` / `fvm dart "$@"` so the scripts run under `/bin/sh` as well.

Leaving the issue open under documentation until that change lands—thanks again for the sharp eye.
```

## Notes
- Move classification to `validated/p2-medium` and track the doc PR.

---
**Validated by**: Code Agent  
**Date**: 2025-10-31
