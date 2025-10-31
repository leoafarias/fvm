# Issue #683: [BUG] dependency overrides cause malfunction in fvm commands

## Metadata
- **Reporter**: Kai Puth (@kputh)
- **Created**: 2024-03-07
- **Reported Version**: 3.0.13
- **Issue Type**: bug
- **URL**: https://github.com/leoafarias/fvm/issues/683

## Problem Summary
`fvm use` (and any command that loads project metadata) crashes with `type 'Null' is not a subtype of type 'String'` when the pubspec contains dependency overrides that only specify a hosted `name/url` pair. The override is a valid Flutter/pub feature, but FVM’s parser chokes before it can even switch SDKs.

## Version Context
- Reported against: FVM 3.0.13
- Current version: v4.0.0
- Version-specific: no — the parsing path is unchanged in v4.
- Reason: FVM delegates to the `pubspec` package, which expects a non-null `version` string even for overrides.

## Validation Steps
1. Reproduced stack trace by inspecting `pubspec` package 2.3.0 (pulled from pub.dev). `ExternalHostedReference.fromJson` calls `VersionConstraint.parse(json['version'])` without a null fallback.
2. Confirmed FVM invokes `Pubspec.parse()` in `Project.loadFromDirectory` (`lib/src/models/project_model.dart:41`), so any `Null` version in overrides triggers the downstream failure before FVM reads `.fvmrc`.
3. Verified override syntax from reporter (`hosted: { name: ..., url: ... }`) omits `version`, exactly the scenario unhandled by `pubspec`.
4. Checked `pubspec_parse` release (1.5.0) — still depends on `pubspec` and inherits the same limitation; there’s no FVM-side sanitization.

## Evidence
```
$ sed -n '1,80p' lib/src/models/project_model.dart
    final pubspec = pubspecFile.existsSync()
        ? Pubspec.parse(pubspecFile.readAsStringSync())
        : null;

$ sed -n '60,120p' /tmp/pubspec-2.3.0/lib/src/dependency.dart
  ExternalHostedReference.fromJson(Map json)
      : this(
          json['hosted'] is String ? null : json['hosted']['name'],
          json['hosted'] is String ? json['hosted'] : json['hosted']['url'],
          VersionConstraint.parse(json['version']),
          json['hosted'] is String ? false : true);
```

**Files/Code References:**
- [lib/src/models/project_model.dart#L39](../lib/src/models/project_model.dart#L39) – Parses `pubspec.yaml` on command startup.
- [/tmp/pubspec-2.3.0/lib/src/dependency.dart#L68](../../tmp/pubspec-2.3.0/lib/src/dependency.dart#L68) – `VersionConstraint.parse(json['version'])` assumes a value even for overrides.
- Reporter’s reproduction (fluffychat) uses hosted overrides without version pins, which are valid per pubspec spec.

## Current Status in v4.0.0
- [x] Still reproducible
- [ ] Already fixed
- [ ] Not applicable to v4.0.0
- [ ] Needs more information
- [ ] Cannot reproduce

## Troubleshooting/Implementation Plan

### Root Cause Analysis
Dependency overrides may omit explicit versions because they exist solely to redirect to a different hosted source. The upstream `pubspec` parser requires `version`, so it throws when it sees `null`. FVM does not guard against that exception, causing user commands to fail.

### Proposed Solution
1. Implement a pre-parse sanitizer in `Project.loadFromDirectory`:
   - Parse the YAML via `loadYaml`/`jsonDecode`.
   - When encountering `dependency_overrides` hosted entries without a `version`, inject `'version': '*'` (or a configurable default) before handing the map to `Pubspec.parse`.
   - Alternatively, fork `pubspec`’s parsing logic locally and treat null as `VersionConstraint.any`.
2. Upstream coordination:
   - File/track a fix in `package:pubspec` (and `pubspec_parse`). The change is small: fall back to `VersionConstraint.any` when `json['version']` is null.
   - Pin FVM to the patched versions once released.
3. While waiting on upstream, wrap `Pubspec.parse` in a try/catch; on failure, reparse using the sanitized map so current users have relief.
4. Add regression tests covering overrides with hosted mirrors, both with and without explicit version numbers.

### Alternative Approaches (if applicable)
- Skip parsing dependency overrides altogether (ignore the map for FVM’s purposes). Simpler, but we still need the rest of the pubspec data for `isFlutter` and metadata; sanitizing is safer.

### Dependencies & Risks
- Manual YAML munging must preserve other pubspec semantics; ensure we don’t accidentally mutate the file or mis-handle version constraints that are genuinely invalid.
- Once upstream `pubspec` is fixed, remove the local workaround to avoid divergence.

### Related Code Locations
- [lib/src/models/project_model.dart#L32](../lib/src/models/project_model.dart#L32) – Entry point for project parsing.
- [`pubspec` issue tracker](https://github.com/dart-lang/pubspec/issues) – reference for upstream follow-up.

## Recommendation
**Action**: validate-p1

**Reason**: Valid pubspec syntax currently crashes FVM commands, blocking users from switching SDKs. Needs a high-priority fix or workaround.

## Notes
- Communicate the temporary workaround (`version: any`) in release notes until the fix ships.
- Consider adding a doctor warning when `Pubspec.parse` throws so the failure is clearer.

---
**Validated by**: Code Agent
**Date**: 2025-10-31
