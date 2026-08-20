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
- Current version: v4.1.1
- Version-specific: no
- Reason: v4 still creates the global `default` link under the configured FVM cache; IDEs must point to it explicitly or discover its `bin` directory from `PATH`.

## Validation Steps
1. Reviewed `CacheService.setGlobal` to confirm `fvm global` only creates the `<FVM cache>/default` link and doesn’t modify IDE settings.
2. Checked the global configuration guide and confirmed that the missing IDE-specific setup requires Android Studio to point at `<FVM cache>/default`.
3. Verified no workflow automatically rewrites Android Studio’s `flutterSdkPath` on Windows, so the prompt is expected if the IDE hasn’t been pointed at the global symlink.
4. Validated Android Studio Quail 2 (2026.1.2) with Flutter plugin 95.0.0: the plugin selected a different Flutter installation found on `PATH` instead of the isolated FVM global SDK. The plugin accepts the FVM SDK root when selected explicitly, but JetBrains may resolve the link to its current cached target.
5. Repeated the project-switch flow through Android Studio’s Flutter settings. Typing the exact `.fvm/flutter_sdk` path initially displayed the link, but committing the field changed it to `/Users/leofarias/fvm/versions/3.41.2`. After `fvm use 3.44.6`, the filesystem link targeted 3.44.6 while Android Studio’s saved SDK metadata remained on 3.41.2. `fvm doctor` reported that saved metadata accurately, but was corroborating evidence rather than the UI/runtime proof.

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
- [lib/src/services/cache_service.dart](../../lib/src/services/cache_service.dart) – Shows `fvm global` only manages the global cache link.
- [lib/src/utils/context.dart](../../lib/src/utils/context.dart) – Defines the global link as `<FVM cache>/default`.
- [docs/pages/documentation/guides/android-studio.mdx](../../docs/pages/documentation/guides/android-studio.mdx) – Documents project, global, `PATH`, and symlink-resolution behavior.

## Current Status in v4.1.1
- [x] Still reproducible as an IDE-integration limitation
- [ ] Already fixed
- [ ] Not applicable to v4.1.1
- [ ] Needs more information
- [ ] Cannot reproduce

The exact “Could not find a Flutter SDK” prompt depends on whether Android Studio can find another Flutter installation. In validation it selected a different SDK from `PATH`, which confirms the same underlying behavior: `fvm global` is not registered with the IDE automatically.

## Troubleshooting/Implementation Plan

### Root Cause Analysis
FVM ensures the global Flutter SDK is linked at `<FVM cache>/default`, but it does not reconfigure IDEs. By default, that path is `$HOME/fvm/default` on macOS/Linux and `C:\Users\<user>\fvm\default` on Windows. Android Studio prompts for an SDK—or selects another SDK from `PATH`—when it has not been pointed at that link.

Some JetBrains versions resolve SDK links to their current cached target. Selecting the FVM link fixes initial discovery, but users may need to reselect it after `fvm global` changes versions.

`fvm doctor` can identify whether the saved JetBrains metadata contains the FVM link or a concrete SDK path. It does not run Android Studio, so users should also confirm the path and version displayed in the IDE after switching.

### Documentation Solution
1. Add a focused Android Studio/IntelliJ guide covering both `.fvm/flutter_sdk` for pinned projects and `<FVM cache>/default` for global fallback.
2. Document the actual default cache paths, `PATH` ordering, SDK-root selection, and the JetBrains symlink-resolution limitation.
3. Link the guide from global configuration, project configuration, common workflows, and the FAQ.

### Alternative Approaches (if applicable)
- Add optional automation for JetBrains project SDK metadata, but that risks overwriting user-managed preferences and crosses into IDE-specific tooling.

### Dependencies & Risks
- Documentation-only change; ensure Windows paths use escaped backslashes where appropriate.
- Mention that PATH configuration still matters for terminal usage.

### Related Code Locations
- [lib/src/commands/global_command.dart](../../lib/src/commands/global_command.dart) – The CLI already reports the required `<FVM cache>/default/bin` path when a different Flutter installation is active.

## Recommendation
**Action**: resolved

**Reason**: FVM works as designed; user action (pointing the IDE to `<FVM cache>/default`) resolves the prompt. Documentation and support response cover the gap.

## Draft Reply
```
Thanks for the detailed report! We confirmed that `fvm global` manages the `<FVM cache>/default` link but does not reconfigure Android Studio automatically. Open **File → Settings → Languages & Frameworks → Flutter** and select the actual global SDK root: normally `C:\Users\<user>\fvm\default` on Windows or `$HOME/fvm/default` on macOS/Linux, and `<FVM_CACHE_PATH>/default` when using a custom cache. Select the root folder, not its `bin` directory.

Android Studio can resolve that link to the current cached version, so after changing `fvm global`, verify the version shown in the IDE and reselect the FVM path if it is stale. Since this is IDE configuration rather than an FVM installation failure, this issue can remain closed as answered.
```

## Notes
- The focused Android Studio/IntelliJ guide and cross-links were added in the documentation working tree.

---
**Validated by**: Code Agent
**Date**: 2026-08-11

## Closure Outcome

Closed on GitHub on 2026-08-11 as completed/working as intended. The reply points Android Studio to the configured FVM global default link and leaves project-specific IDE gaps in #724 and #767.
