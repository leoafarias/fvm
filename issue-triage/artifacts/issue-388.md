# Issue #388: [BUG] Intellij IDEA (Android Studio) with multiple flutter packages: cannot configure fvm

## Metadata
- **Reporter**: @fzyzcjy
- **Created**: 2022-02-20
- **Reported Version**: 2.x
- **Issue Type**: limitation (IDE integration)
- **URL**: https://github.com/leoafarias/fvm/issues/388

## Problem Summary
The user wants a single IntelliJ/Android Studio project containing multiple Flutter packages, each pinned to a different SDK via FVM. The IDE exposes only one Flutter SDK path per project, so changing it affects every module. FVM can manage versions on disk, but IntelliJ can’t switch SDK per module today.

## Investigation Summary
1. IntelliJ stores the Flutter SDK path in `.idea/misc.xml` (`<option name="FLUTTER_SDK_PATH" …>`). This value is global for the project; the plugin doesn’t support per-module Flutter SDK selection.
2. FVM already creates `.fvm/flutter_sdk` symlinks per package; the CLI (`fvm flavor` / `fvm spawn`) lets you run commands against any version. The limitation is purely in the IDE UI.
3. Without upstream support, FVM can’t override IDE behavior safely: editing `.idea` files manually would still apply globally and risks corruption.

## Recommendation
**Action**: resolved (document limitation)

**Reason**: The IDE doesn’t allow per-module Flutter SDK paths, so the request is currently unsatisfiable. Provide guidance on workarounds instead of promising tooling changes.

## Suggested Workarounds
- Open each package as a separate Android Studio project so the Flutter SDK path follows the package’s `.fvm/flutter_sdk`.
- Use `fvm flavor` or `fvm spawn` for CLI tasks while keeping Android Studio pointed at your primary SDK.
- Consider filing an IntelliJ Flutter plugin feature request (link from docs).

## Notes
- Update documentation/FAQ to mention the IDE constraint and the recommended approaches.

---
**Validated by**: Code Agent
**Date**: 2025-10-31
