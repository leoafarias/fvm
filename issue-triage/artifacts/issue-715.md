# Issue #715: [BUG] Cannot change versions to use Dart<3.0 compatible projects

## Metadata
- **Reporter**: @yieniggu
- **Created**: 2024-04-15
- **Reported Version**: Flutter 3.7.12 via FVM
- **Issue Type**: bug (environment)
- **URL**: https://github.com/leoafarias/fvm/issues/715

## Problem Summary
Switching a project to Flutter 3.7.12 with `fvm use 3.7.12` causes `flutter doctor` to report that no Java Development Kit is available, and Android builds fail because `JAVA_HOME` is unset.

## Version Context
- Reported against: FVM 3.x (implied)
- Current version: v4.0.0
- Version-specific: no
- Reason: The behavior stems from Flutter 3.7.x requiring an external JDK; FVM only proxies the Flutter SDK and does not manage Java runtimes.

## Validation Steps
1. Reviewed the issue reproduction data (doctor output and Gradle failure) confirming the error originates from Flutter’s Java toolchain detection.
2. Inspected `lib/src/services/flutter_service.dart` to verify that FVM just prepends the selected SDK’s `bin` directories to `PATH` and otherwise inherits the user environment, leaving `JAVA_HOME` untouched.
3. Cross-checked the current docs and determined FVM lacks guidance about installing or pointing to a JDK when using pre-3.13 Flutter releases.

## Evidence
```
$ sed -n '348,392p' lib/src/services/flutter_service.dart
  Map<String, String> _updateEnvironmentVariables(List<String> paths) {
    ...
    updatedEnvironment['PATH'] = paths.join(separator) + separator + envPath;
    return updatedEnvironment;
  }
  Future<ProcessResult> run(
    String cmd,
    List<String> args, {
    ...
    final environment = _updateEnvironmentVariables([
      _version.binPath,
      _version.dartBinPath,
    ]);
    return _context.get<ProcessService>().run(
          cmd,
          args: args,
          environment: environment,
          ...
        );
```

**Files/Code References:**
- [lib/src/services/flutter_service.dart#L348](../lib/src/services/flutter_service.dart#L348) – Demonstrates FVM only augments `PATH`, so Java detection depends on the user environment.
- [docs/pages/documentation/getting-started/faq.md#L1](../docs/pages/documentation/getting-started/faq.md#L1) – Candidate location to document JDK expectations for older Flutter versions.

## Current Status in v4.0.0
- [ ] Still reproducible
- [ ] Already fixed
- [ ] Not applicable to v4.0.0
- [ ] Needs more information
- [x] Cannot reproduce (FVM works as designed; missing JDK is an environment prerequisite)

## Troubleshooting/Implementation Plan

### Root Cause Analysis
Flutter 3.7.12 predates the bundled Java runtime that ships with newer Flutter SDKs. When FVM switches to that SDK, Flutter’s tooling expects a system-provided JDK via `JAVA_HOME` or PATH. Because FVM does not install or configure Java, the toolchain reports the same error a standalone Flutter install would show on a host lacking JDK 11/17.

### Proposed Solution
1. Add an FAQ entry to `docs/pages/documentation/getting-started/faq.md` clarifying that older Flutter releases require a separate JDK installation and showing how to point Flutter to Android Studio’s embedded JBR or a system JDK (`flutter config --jdk-dir=<path>`).
2. When responding on GitHub, explain that the error is expected for Flutter 3.7.x unless a JDK is available, and link to the updated FAQ plus Flutter’s official Android Java tooling guidance.
3. Encourage users targeting legacy Dart ranges to install OpenJDK 11/17 (matching the Flutter release) and export `JAVA_HOME` or configure `flutter config --jdk-dir`.

### Alternative Approaches (if applicable)
- Automate JDK setup in FVM itself, but this would significantly expand scope and conflict with FVM’s principle of staying close to upstream Flutter tooling.

### Dependencies & Risks
- Documentation change only; ensure guidance remains accurate for future Flutter releases.
- Verify the FAQ update mentions platform-specific locations (Android Studio JBR on Linux/macOS/Windows).

### Related Code Locations
- [lib/src/services/flutter_service.dart#L348](../lib/src/services/flutter_service.dart#L348) – Environment handling when FVM launches Flutter commands.

## Recommendation
**Action**: resolved

**Reason**: Environment setup issue; FVM is functioning correctly. Documentation and support response are sufficient.

## Notes
- Consider linking to Flutter’s Android Java/Gradle migration notes once the FAQ entry is published.

---
**Validated by**: Code Agent
**Date**: 2025-10-31
