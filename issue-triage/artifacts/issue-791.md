# Issue #791: [Feature Request] Namespace versions and branches for Flutter forks

## Metadata
- **Reporter**: @leoafarias
- **Created**: 2024-11-04
- **Issue Type**: feature request (already implemented)
- **URL**: https://github.com/leoafarias/fvm/issues/791

## Summary
Request to namespace forked versions to avoid collisions. Current code already stores fork versions under `~/.fvm/versions/<fork>/<version>` and supports `alias/version` syntax.

## Evidence
```
lib/src/services/cache_service.dart:123-133  // fork directories per alias
lib/src/models/flutter_version_model.dart:142-163  // parse fork prefixes
lib/src/services/flutter_service.dart:142-191      // install from fork into fork-specific directory
```

## Recommendation
Close as implemented.

## Classification Recommendation
- Folder: `resolved/`
