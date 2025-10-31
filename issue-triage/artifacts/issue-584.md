# Issue #584: [BUG] Unable to change the `context.flutterUrl`

## Metadata
- **Reporter**: Jim Cook (@oravecz)
- **Created**: 2023-12-09
- **Reported Version**: 2.4.1
- **Issue Type**: documentation/UX gap
- **URL**: https://github.com/leoafarias/fvm/issues/584

## Problem Summary
FVM supports overriding the Flutter Git remote via configuration (`fvm config --flutter-url …`) or environment (`FVM_FLUTTER_URL`, `FLUTTER_GIT_URL`), but the user couldn’t discover how to do this. They attempted several approaches without success because the capability isn’t documented clearly.

## Version Context
- Reported against: 2.4.1
- Current version: v4.0.0
- Version-specific: no — the feature exists but lacks docs/tutorials.

## Validation Steps
1. Reviewed `FvmContext.flutterUrl` — it prioritizes configuration/environment overrides.
2. Confirmed `FvmConfig` wiring (`ConfigOptions.flutterUrl`, `AppConfigService._loadEnvironment`) supports both `FVM_FLUTTER_URL` and Flutter’s `FLUTTER_GIT_URL`.
3. Checked documentation: the configuration guide only lists `flutterUrl` in a table; no dedicated “Custom Flutter Remote” section or CLI examples.

## Evidence
```
$ sed -n '88,130p' lib/src/services/app_config_service.dart
      if (config is EnvConfig) {
        appConfig = appConfig.copyWith.$merge(
          AppConfig(
            ...
            flutterUrl: config.flutterUrl,
          ),
        );
      }

$ sed -n '120,150p' lib/src/utils/context.dart
  String get flutterUrl => config.flutterUrl ?? kDefaultFlutterUrl;
```

**Files/Code References:**
- [lib/src/services/app_config_service.dart#L88](../lib/src/services/app_config_service.dart#L88) – Merges env/config overrides.
- [lib/src/utils/context.dart#L120](../lib/src/utils/context.dart#L120) – Reads the resolved URL.

## Current Status in v4.0.0
- [x] Still reproducible (docs issue)
- [ ] Already fixed
- [ ] Not applicable to v4.0.0
- [ ] Needs more information
- [ ] Cannot reproduce

## Troubleshooting/Implementation Plan

### Proposed Improvements
1. Add a dedicated documentation section (e.g., “Using a custom Flutter mirror”) covering:
   - `fvm config --flutter-url https://internal.git/flutter.git`
   - `FVM_FLUTTER_URL` and `FLUTTER_GIT_URL`
   - Verifying with `fvm config`/`fvm doctor`.
2. Include examples for restored network environments (mirrors, intranet setups) and mention interactions with other settings (e.g., when combined with fork aliases).
3. Update `fvm config --help` output and the CLI docs to highlight available keys, especially `flutter-url`.
4. Ensure the error message when clone fails references the current remote, helping users notice misconfiguration.

### Alternative Approaches
- CLI addition: `fvm config show` already prints YAML; could underline the remote URL there.

### Dependencies & Risks
- Pure documentation and messaging changes; no code risk.

### Related Code Locations
- [docs/pages/documentation/getting-started/configuration.mdx](../docs/pages/documentation/getting-started/configuration.mdx).
- CLI help strings for `ConfigOptions.flutterUrl`.

## Recommendation
**Action**: validate-p3

**Reason**: Functionality already exists; we need clearer docs and CLI messaging.

## Notes
- Consider linking this section when documenting mirror setups (related to issue #688).

---
**Validated by**: Code Agent
**Date**: 2025-10-31
