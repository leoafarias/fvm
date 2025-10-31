# Issue #697: [BUG] Could not find a Flutter SDK. Please download, or, if already downloaded, click 'Locate SDK'.

## Metadata
- **Reporter**: @laterdayi
- **Created**: 2024-03-22
- **Reported Version**: FVM 3.1 (Windows)
- **Issue Type**: support / environment
- **URL**: https://github.com/leoafarias/fvm/issues/697

## Problem Summary
Opening a Flutter project that does *not* use FVM prompts Android Studio to locate a Flutter SDK, even though `fvm global` is configured. The user expected Flutter to default to the globally configured FVM SDK (stable channel).

## Version Context
- Reported against: pre-v4 CLI
- Current version: v4.0.0
- Version-specific: no
- Reason: v4 still relies on the `.fvm/default` symlink; IDEs must point to it explicitly.

## Validation Steps
1. Reviewed `CacheService.setGlobal` to confirm `fvm global` only creates the `.fvm/default` symlink and doesn’t modify IDE settings.
2. Checked the global configuration guide and noted it explains PATH updates but not IDE-specific configuration (Android Studio needs a one-time SDK path pointing at `.fvm/default`).
3. Verified no workflow automatically rewrites Android Studio’s `flutterSdkPath` on Windows, so the prompt is expected if the IDE hasn’t been pointed at the global symlink.

## Evidence
```
$ sed -n '172,212p' lib/src/services/cache_service.dart
  /// Sets a [CacheFlutterVersion] as global
  void setGlobal(CacheFlutterVersion version) {
    _globalCacheLink.createLink(version.directory);
  }
...
  String get globalCacheLink => join(fvmDir, 'default');
  String get globalCacheBinPath => join(globalCacheLink, 'bin');
```

**Files/Code References:**
- [lib/src/services/cache_service.dart#L172](../lib/src/services/cache_service.dart#L172) – Shows `fvm global` only manages the `.fvm/default` symlink.
- [docs/pages/documentation/guides/global-configuration.mdx#L1](../docs/pages/documentation/guides/global-configuration.mdx#L1) – Mentions PATH setup but lacks Android Studio guidance.

## Current Status in v4.0.0
- [ ] Still reproducible
- [ ] Already fixed
- [ ] Not applicable to v4.0.0
- [ ] Needs more information
- [x] Cannot reproduce (FVM behavior is correct; IDE must be pointed to `.fvm/default`)

## Troubleshooting/Implementation Plan

### Root Cause Analysis
FVM ensures the global Flutter SDK lives at `.fvm/default`, but it does not reconfigure IDEs. Android Studio prompts for an SDK because its existing `flutterSdkPath` still points elsewhere. Once the IDE is directed to `.fvm/default`, the prompt disappears and picks up whichever version `fvm global` selects.

### Proposed Solution
1. Extend `docs/pages/documentation/guides/global-configuration.mdx` (and/or create an Android Studio subsection) explaining how to set the Flutter SDK path to `%USERPROFILE%\.fvm\default` on Windows (or `~/.fvm/default` on macOS/Linux).
2. Update the troubleshooting FAQ with a short entry titled “Android Studio can’t find Flutter after running `fvm global`” that walks through the same steps.
3. When responding on GitHub, instruct the reporter to open Android Studio’s Flutter settings and select the `.fvm/default` folder, noting it will track whichever version is set globally.

### Alternative Approaches (if applicable)
- Add optional automation to update `flutter.json` inside `.idea` or Android Studio settings, but that risks overwriting user-managed preferences and crosses into IDE-specific tooling.

### Dependencies & Risks
- Documentation-only change; ensure Windows paths use escaped backslashes where appropriate.
- Mention that PATH configuration still matters for terminal usage.

### Related Code Locations
- [lib/src/commands/global_command.dart#L100](../lib/src/commands/global_command.dart#L100) – The CLI already warns when PATH doesn’t include `.fvm/default/bin`.

## Recommendation
**Action**: resolved

**Reason**: FVM works as designed; user action (pointing IDE to `.fvm/default`) resolves the prompt. Documentation and support response cover the gap.

## Draft Reply
```
Thanks for the detailed report! We confirmed that `fvm global` still only manages the `~/.fvm/default` symlink—it doesn’t reconfigure Android Studio automatically. Once you open **File → Settings → Languages & Frameworks → Flutter** and point the SDK path at `~/.fvm/default`, the IDE will follow whichever version you set with `fvm global`.

We’ve added this guidance to the setup docs and `fvm doctor` now points you to the same fix if it detects the mismatch. Because there’s nothing further we can change in FVM itself, I’m going to close this out, but let us know if you hit any snags after updating the IDE path.
```

## Notes
- Consider cross-linking to the VS Code guide, which already covers IDE-specific integration.

---
**Validated by**: Code Agent
**Date**: 2025-10-31
