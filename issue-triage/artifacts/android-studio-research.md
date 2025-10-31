# Android Studio Integration Findings & Recommendations

**Updated**: 2025-10-31  
**Related GitHub Issues**: #697, #600, #388  
**Maintainers**: Triage team

---

## TL;DR
- Android Studio/IntelliJ does *not* automatically follow the `.fvm/default` or project `.fvm/flutter_sdk` symlinks. Once the IDE SDK path is pointed at the symlink, version switching behaves like VS Code.  
- FVM v4 already inspects `.idea/libraries/Dart_SDK.xml` in `fvm doctor` to verify whether the IDE is following `.fvm/flutter_sdk` (`lib/src/commands/doctor_command.dart:135`). We can reuse that knowledge to offer automation and better diagnostics.  
- Compared with VS Code, the missing pieces are: (1) first-run guidance, (2) optional helpers to rewrite `.idea` artifacts safely, and (3) proactive doctor warnings when Android Studio drifts.  
- Recommendation: deliver a hybrid approach—improve docs + doctor messaging now, then add an opt-in `fvm ide android-studio --sync` helper that updates project XML using the same JSONC-safe patterns employed by the VS Code workflow.

---

## Current IDE Behavior (v4.0.0)
- `fvm global {version}` creates the `.fvm/default` symlink (`lib/src/services/cache_service.dart:172`) and logs a notice if `$PATH` is not aligned (`lib/src/commands/global_command.dart:106`+).  
- When a project runs `fvm use`, FVM maintains `.fvm/flutter_sdk` and the cached SDK under `.fvm/versions/{id}`.  
- Android Studio persists its Flutter SDK decision per project inside `.idea/libraries/Dart_SDK.xml`. The current `fvm doctor` implementation reads that file and expects to see either `$PROJECT_DIR$/.fvm/flutter_sdk` or `$USER_HOME$/.fvm/default` (see logic around lines 135–166 of `lib/src/commands/doctor_command.dart`). If the IDE still points elsewhere, the user receives “Could not find a Flutter SDK…” on open.  
- IntelliJ exposes only a single Flutter SDK path per project. Multi-package workspaces therefore need separate Android Studio windows (documented in `issue-triage/artifacts/issue-388.md`).

---

## Why VS Code Feels Automatic
- FVM ships `UpdateVsCodeSettingsWorkflow` (`lib/src/workflows/update_vscode_settings.workflow.dart`) that:
  - Detects pinned versions in `.fvmrc`.
  - Reads/writes `.vscode/settings.json` and workspace files via JSONC parsing so formatting/comments survive.
  - Sets `dart.flutterSdkPath` to `.fvm/flutter_sdk` relative to either the project root or the workspace file.
- As a result, the IDE follows the symlink after every `fvm use`. Terminals spawned inside VS Code are purposely left alone; users rely on `PATH`.

Takeaway: the “dynamic” experience is achieved by editing human-owned configuration *carefully* with file-format-aware tooling, backed by doctor diagnostics.

---

## Options to Align Android Studio with VS Code

### 1. Documentation & Support Improvements (ship immediately)
- Expand `docs/pages/documentation/guides/global-configuration.mdx` and the Android Studio workflow guide to state explicitly:
  - Project SDK path should target `.fvm/flutter_sdk`.
  - Global installs should target `%USERPROFILE%\.fvm\default` or `~/.fvm/default`.
  - Include screenshots of **File → Project Structure → Flutter** pointing at the symlink.
- Add a troubleshooting FAQ entry: “Android Studio keeps asking to locate Flutter SDK” with the exact steps.
- Update `fvm doctor` messaging to mention the fix when `$PROJECT_DIR$/.fvm/flutter_sdk` is missing.

### 2. Enhanced Diagnostics (short-term)
- Teach `fvm doctor` to surface actionable remediation:
  - When `.idea/libraries/Dart_SDK.xml` lacks `.fvm/flutter_sdk`, print the precise path to choose and link to docs.
  - Optionally check `android/local.properties` for mismatches (for hybrid Android modules).

### 3. Opt-In Configuration Helper (medium-term)
- Provide a new workflow, tentatively `fvm ide android-studio --sync`, gated by a confirmation prompt or CLI flag:
  1. Locate `.idea/libraries/Dart_SDK.xml` and ensure it is XML (abort if malformed or binary).
  2. Parse the XML (using `xml` package) and rewrite the `CLASSES` / `JAVADOC` entries to use `$PROJECT_DIR$/.fvm/flutter_sdk`. Preserve macros and order.
  3. Detect `.idea/misc.xml` and set `<option name="FLUTTER_SDK_PATH" value="...">` if present.
  4. Respect `.fvm/fvm_config.json` overrides (e.g., custom cache path from issue #696).
  5. Backup files (`filename.fvm.bak`) before writing.
- Make the workflow idempotent, emitting success logs similar to VS Code workflow, and integrate into `fvm use` if the user enables an `updateAndroidStudioSettings` flag.

### 4. Stretch: Global Defaults
- The Flutter plugin also stores a user-level default in `flutter_settings.xml` under the JetBrains options directory. Automating that would allow “new projects” to inherit `.fvm/default`, but the path is platform-specific and riskier. Consider only after project-level syncs prove stable.

---

## Risk & Mitigation Summary
| Risk | Impact | Mitigation |
|------|--------|------------|
| Corrupting `.idea` XML | High | Parse/write via XML DOM, keep backups, dry-run flag |
| Mixed JetBrains product versions (AS vs IntelliJ) | Medium | Detect product by reading `.idea/.name` or `product-info.json`; limit automation to recognized formats |
| Symlink restrictions on Windows | Medium | Normalize paths and ensure `PathProvider` resolves to short paths if needed |
| Multi-module monorepos | Medium | Allow per-module overrides; document limitation that IDEA only supports one Flutter SDK per project |
| Maintenance overhead | Low/Medium | Reuse workflow architecture from VS Code (same logging, config toggles) |

---

## Proposed Execution Plan
1. **Docs Sprint (same week)**  
   - Update global configuration + Android Studio pages.  
   - Add FAQ + link from issue #697 when closing.  
2. **Doctor Messaging (next CLI patch)**  
   - Enhance `doctor_command.dart` output with remediation text.  
   - Add automated tests that snapshot the table rows for IDE checks.  
3. **Prototype `fvm ide android-studio --sync` (2–3 days)**  
   - New workflow in `lib/src/workflows/update_android_studio_settings.workflow.dart`.  
   - Unit tests using fixture `.idea` directories.  
   - CLI flag on `fvm use` / `fvm doctor` to trigger sync.  
4. **Beta & Feedback**  
   - Behind `--experimental-ide-sync` flag initially.  
   - Collect logs/issues before enabling by default.

---

## Open Questions
- Should automation touch user-level `flutter_settings.xml`, or is project-level enough?  
- How do we support Android Studio “Preview” channels whose config directories differ?  
- Could we integrate with JetBrains’ Toolbox APIs for safer edits? (Needs more research.)  
- Do we need UI prompts (e.g., `fvm doctor --fix`) before mutating IDE files?

---

## Next Actions
1. Draft documentation update PR (link to issue #600 plan).  
2. Modify `fvm doctor` messaging with explicit `.idea` guidance.  
3. Spike `update_android_studio_settings` workflow using a fixture project to validate XML rewriting.  
4. Sync with Android Studio power users to verify multi-module expectations before enabling automation by default.

---

*Prepared for the FVM triage & tooling teams to close out issue #697 with a concrete path forward.*
