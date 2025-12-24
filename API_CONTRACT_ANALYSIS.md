# FVM API Contract Analysis Report

**Analysis Date:** 2025-12-24
**Codebase:** FVM v4.0.5
**Focus:** Interface consistency, breaking changes, documentation accuracy, type safety, configuration schema

---

## Executive Summary

The FVM codebase demonstrates a generally well-structured API with clear public exports and good use of modern Dart patterns. However, there are several API contract issues that could impact maintainability, extensibility, and consumer experience:

**Key Findings:**
- ✅ **Strengths:** Clear public API surface, good type safety with nullability, well-defined configuration schema
- ⚠️ **Concerns:** Inconsistent error handling patterns, mixed sync/async boundaries, silent failures in config parsing
- 🔴 **Critical:** Potential breaking changes in version matching logic, undocumented null return behaviors

---

## 1. Public API Consistency

### 1.1 Export Surface Analysis

**File:** `/home/user/fvm/lib/fvm.dart`

The public API is clearly defined with 19 explicit exports:
- 6 models (config, project, version models)
- 2 services (cache, project)
- 3 releases models
- 8 utilities (exceptions, helpers, extensions, etc.)

**Issue #1: Selective Service Exposure**
```dart
// Public exports
export 'package:fvm/src/services/cache_service.dart';
export 'package:fvm/src/services/project_service.dart';
export 'package:fvm/src/services/releases_service/releases_client.dart';

// NOT exported (internal only):
// - FlutterService
// - GitService
// - ProcessService
// - LoggerService
```

**Impact:** API consumers cannot directly access key services like `FlutterService` or `GitService`, limiting extensibility. However, this may be intentional encapsulation.

### 1.2 Return Type Inconsistencies

**Issue #2: Mixed Nullable Return Patterns**

**Location:** `/home/user/fvm/lib/src/services/cache_service.dart`

```dart
// Returns null on not found
CacheFlutterVersion? getVersion(FlutterVersion version) {
  final versionDir = getVersionCacheDir(version);
  if (!versionDir.existsSync()) return null;  // Silent failure
  return CacheFlutterVersion.fromVersion(version, directory: versionDir.path);
}

// Returns null on invalid
CacheFlutterVersion? getGlobal() {
  final version = getGlobalVersion();
  if (version == null) return null;
  try {
    final validVersion = FlutterVersion.parse(version);
    return getVersion(validVersion);
  } on FormatException catch (e) {
    logger.warn('Global version "$version" could not be parsed: $e. ...');
    return null;  // Logs warning but returns null
  }
}

// Throws exception
void moveToSdkVersionDirectory(CacheFlutterVersion version) {
  final sdkVersion = version.flutterSdkVersion;
  if (sdkVersion == null) {
    throw AppException(  // Throws instead of returning null
      'Cannot move to SDK version directory without a valid version',
    );
  }
  // ...
}
```

**Problem:** Inconsistent error signaling:
- `getVersion()` returns `null` silently
- `getGlobal()` logs warning then returns `null`
- `moveToSdkVersionDirectory()` throws exception

**Recommendation:** Standardize on one approach or document when each pattern is used.

### 1.3 Async/Sync Boundary Inconsistencies

**Issue #3: Mixed Synchronous/Asynchronous Operations**

**Location:** `/home/user/fvm/lib/src/services/cache_service.dart`

```dart
// Synchronous
CacheFlutterVersion? getVersion(FlutterVersion version) { ... }
void remove(FlutterVersion version) { ... }
void setGlobal(CacheFlutterVersion version) { ... }

// Asynchronous
Future<List<CacheFlutterVersion>> getAllVersions() async { ... }
Future<CacheIntegrity> verifyCacheIntegrity(...) async { ... }
```

**Analysis:**
- File operations are mostly sync, but directory listing is async
- `verifyCacheIntegrity()` is async because it calls `isExecutable()` (which checks file permissions)
- This creates an inconsistent mental model for API consumers

**Location:** `/home/user/fvm/lib/src/services/releases_service/releases_client.dart`

```dart
// All operations are async (network calls)
Future<FlutterReleasesResponse> fetchReleases({...}) async { ... }
Future<bool> isVersionValid(String version) async { ... }
Future<FlutterSdkRelease> getLatestChannelRelease(String channel) async { ... }

// But cache access is synchronous
void clearCache() { _cachedReleases = null; }
```

**Recommendation:** Document sync vs async patterns clearly in API docs.

### 1.4 Method Naming Consistency

**Issue #4: Inconsistent Getter/Method Patterns**

```dart
// ProjectService - uses verb naming
Project findAncestor({Directory? directory}) { ... }
String? findVersion() { ... }
Project update(Project project, {...}) { ... }

// CacheService - mix of noun/verb patterns
CacheFlutterVersion? getVersion(FlutterVersion version) { ... }  // get*
Future<List<CacheFlutterVersion>> getAllVersions() async { ... }  // getAll*
void remove(FlutterVersion version) { ... }  // remove (verb)
CacheFlutterVersion? getGlobal() { ... }  // get* (but behaves like findGlobal)
String? getGlobalVersion() { ... }  // get* (returns name, not object)
```

**Observation:** Mostly consistent, but `getGlobal()` vs `getGlobalVersion()` creates ambiguity about return types.

---

## 2. Breaking Change Risks

### 2.1 Deprecated APIs

**Finding:** Only **1 deprecated method** found in entire codebase:

```dart
// lib/src/services/cache_service.dart:190
@Deprecated('Use getVersionCacheDir(FlutterVersion) instead')
Directory getVersionCacheDirByName(String version) {
  return Directory(path.join(context.versionsCachePath, version));
}
```

**Risk Level:** ⚠️ Low - well-marked with clear migration path

**Recommendation:**
- Set deprecation timeline for removal
- Add `@Since()` annotation to replacement method
- Consider adding deprecation to CHANGELOG

### 2.2 Public vs Internal Boundary Clarity

**Issue #5: Unclear Public/Internal Boundaries**

**Public exports** (`lib/fvm.dart`):
```dart
export 'package:fvm/src/utils/helpers.dart';  // Exposes ALL helpers
export 'package:fvm/src/utils/extensions.dart';  // Exposes ALL extensions
```

**Problem:** Utilities like `assignVersionWeight()`, `lookUpDirectoryAncestor()`, and all extensions are public but feel like internal helpers.

**Example from** `/home/user/fvm/lib/src/utils/helpers.dart`:
```dart
// Public API (exported)
String assignVersionWeight(String version) {
  /// Assigns weight: git commits (500.0.0), master (400.0.0), etc.
  if (isPossibleGitCommit(version)) { version = '500.0.0'; }
  // ... internal logic
}

// Also public
T? lookUpDirectoryAncestor<T>({...}) { ... }
```

**Risk:** Changes to these "internal" utilities could break external consumers who depend on them.

**Recommendation:**
- Create separate `utils/public.dart` and `utils/internal.dart`
- Only export public utilities
- Use `@internal` annotation for truly internal APIs

### 2.3 Version Parsing Breaking Changes

**Issue #6: Critical - Version Parsing Logic Changes**

**Location:** `/home/user/fvm/lib/src/models/flutter_version_model.dart:74`

```dart
factory FlutterVersion.parse(String version) {
  // Match pattern: [fork/]version[@channel]
  final pattern = RegExp(
    r'^(?:(?<fork>[^/]+)/)?(?<version>[^@]+)(?:@(?<channel>\w+))?$',
  );
  final match = pattern.firstMatch(version);

  if (match == null) {
    throw FormatException('Invalid version format: $version');
  }
  // ...
}
```

**Risk:** Any changes to version format parsing would be a **breaking change** for:
- Stored configuration files (`.fvmrc`)
- Command-line arguments
- Programmatic API consumers

**Current Supported Formats:**
- `stable` (channel)
- `3.19.0` (release)
- `v3.19.0` (release with v prefix)
- `3.19.0@stable` (release with channel)
- `fork/3.19.0` (fork + version)
- `fork/stable` (fork + channel)
- `custom_name` (custom versions)

**Recommendation:**
- Document supported version formats in API docs
- Add format validation tests
- Use semantic versioning for any format changes

### 2.4 Configuration Schema Evolution

**Issue #7: Silent Config Field Ignoring**

**Location:** `/home/user/fvm/lib/src/models/config_model.dart`

```dart
@MappableClass(ignoreNull: true)
class ProjectConfig extends FileConfig with ProjectConfigMappable {
  final String? flutter;
  final Map<String, String>? flavors;
  // ... other fields
}
```

**Behavior:** Unknown fields in `.fvmrc` are **silently ignored** due to `ignoreNull: true` and dart_mappable's default behavior.

**Test:**
```json
{
  "flutter": "3.19.0",
  "unknownField": "will be ignored",  // No error, no warning
  "typo": "also ignored"
}
```

**Risk:**
- Typos in config files go unnoticed
- Future config additions might conflict with user's custom fields
- No validation feedback for users

**Recommendation:** Add validation layer that warns about unknown keys.

---

## 3. Documentation Accuracy

### 3.1 Documentation Coverage Analysis

**Overall Assessment:** ⚠️ **Moderate** - Good coverage on models, sparse on services

**Well-Documented:**
- ✅ All model classes have class-level documentation
- ✅ Most public fields have inline documentation
- ✅ Complex algorithms (version parsing, cache verification) have comments

**Poorly Documented:**
- ❌ Service method return values (what null means)
- ❌ Exception types that can be thrown
- ❌ Side effects of methods (filesystem changes, cache updates)
- ❌ Thread safety / concurrency guarantees

### 3.2 Documentation Style Issues

**Issue #8: Missing @return and @throws Documentation**

**Finding:** Zero uses of JavaDoc-style @param/@return/@throws in entire codebase

```bash
$ grep -r "@param\|@return\|@throws" lib/
# No matches found
```

**Current Style:**
```dart
/// Retrieves the pinned Flutter SDK version within the project.
///
/// Returns `null` if no version is pinned.
@MappableField()
FlutterVersion? get pinnedVersion { ... }
```

**Better Style:**
```dart
/// Retrieves the pinned Flutter SDK version within the project.
///
/// Returns the pinned [FlutterVersion] if configured, or `null` if no
/// version is pinned in the project's `.fvmrc` file.
///
/// Example:
/// ```dart
/// final project = Project.loadFromDirectory(Directory.current);
/// final version = project.pinnedVersion;  // May be null
/// ```
@MappableField()
FlutterVersion? get pinnedVersion { ... }
```

### 3.3 Behavior Documentation Gaps

**Issue #9: Undocumented Null Semantics**

**Location:** `/home/user/fvm/lib/src/services/cache_service.dart:76`

```dart
/// Returns a [CacheFlutterVersion] from a [version]
CacheFlutterVersion? getVersion(FlutterVersion version) {
  final versionDir = getVersionCacheDir(version);
  // Return null if version does not exist
  if (!versionDir.existsSync()) return null;

  return CacheFlutterVersion.fromVersion(version, directory: versionDir.path);
}
```

**Documentation says:** "Returns a CacheFlutterVersion from a version"
**Actual behavior:** Returns `null` if version directory doesn't exist

**Missing:**
- When does it return null vs throw?
- Can it throw exceptions? (Yes, if directory exists but is corrupted)
- What happens if permissions are denied?

**Issue #10: Version Matching Logic Underdocumented**

**Location:** `/home/user/fvm/lib/src/services/cache_service.dart:318`

```dart
/// Determines if [configured] and [cached] versions should be considered
/// matching.
///
/// Matching rules:
/// 1. Exact string match (after normalizing leading 'v'/'V' prefix)
/// 2. If either has build metadata (+xxx), both must match exactly
/// 3. If both have pre-release identifiers (-xxx), both must match exactly
/// 4. If [configured] has pre-release but [cached] does not, match on
///    `major.minor.patch` (allows dev builds to match stable SDKs)
/// 5. If [cached] has pre-release but [configured] does not, require exact match
/// 6. For non-semver versions (e.g., git refs), catches [FormatException] and
///    falls back to normalized string equality with a warning logged
@visibleForTesting
bool versionsMatch(String configured, String cached) { ... }
```

**Good:** Comprehensive rules documented
**Problem:** Marked `@visibleForTesting` but used in production code (verifyCacheIntegrity)
**Issue:** Rule #4 vs #5 asymmetry not explained (why different behavior?)

---

## 4. Type Safety at Boundaries

### 4.1 Null Safety Analysis

**Overall:** ✅ **Excellent** - Comprehensive use of nullable types throughout

**Examples:**
```dart
// Clear nullable contracts
final String? flutter;
final Map<String, String>? flavors;
CacheFlutterVersion? getVersion(FlutterVersion version) { ... }

// Non-nullable when guaranteed
final String name;
final VersionType type;
```

### 4.2 Potential Null Issues

**Issue #11: Unsafe Null Assumptions in Parsing**

**Location:** `/home/user/fvm/lib/src/services/releases_service/models/flutter_releases_model.dart:117`

```dart
final dev = currentRelease['dev'] as String?;
final beta = currentRelease['beta'] as String?;
final stable = currentRelease['stable'] as String?;

final devRelease = hashReleaseMap[dev];      // Could be null
final betaRelease = hashReleaseMap[beta];    // Could be null
final stableRelease = hashReleaseMap[stable]; // Could be null

final channels = Channels(
  beta: betaRelease!,    // Force unwrap! Runtime error if null
  dev: devRelease!,      // Force unwrap! Runtime error if null
  stable: stableRelease!, // Force unwrap! Runtime error if null
);
```

**Risk:** If Flutter releases JSON is malformed or missing channels, app crashes with null assertion error instead of graceful handling.

**Recommendation:** Add validation:
```dart
if (devRelease == null || betaRelease == null || stableRelease == null) {
  throw AppException('Invalid releases data: missing required channels');
}
```

### 4.3 Type Safety at Config Boundaries

**Issue #12: Unsafe Dynamic Casts**

**Location:** `/home/user/fvm/lib/src/models/project_model.dart:175`

```dart
String? _dartToolGeneratorVersion(String projectPath) {
  final file = File(join(_dartToolPath(projectPath), 'package_config.json'));

  return file.existsSync()
      ? (jsonDecode(file.readAsStringSync())
          as Map<String, dynamic>)['generatorVersion'] as String?
      : null;
}
```

**Problems:**
1. `as Map<String, dynamic>` can fail if JSON is not an object
2. `['generatorVersion']` might not exist
3. `as String?` assumes value is String or null, could be int/bool/etc

**Better Approach:**
```dart
String? _dartToolGeneratorVersion(String projectPath) {
  final file = File(join(_dartToolPath(projectPath), 'package_config.json'));
  if (!file.existsSync()) return null;

  try {
    final json = jsonDecode(file.readAsStringSync());
    if (json is! Map<String, dynamic>) return null;

    final version = json['generatorVersion'];
    return version is String ? version : null;
  } on FormatException {
    return null;  // Invalid JSON
  }
}
```

### 4.4 Generic Type Safety

**Issue #13: Dependency Injection Type Safety**

**Location:** `/home/user/fvm/lib/src/utils/context.dart:188`

```dart
T get<T>() {
  if (_dependencies.containsKey(T)) {
    return _dependencies[T] as T;  // Unsafe cast
  }
  if (_generators.containsKey(T)) {
    final generator = _generators[T] as Generator;
    _dependencies[T] = generator(this);
    return _dependencies[T];  // Unsafe cast
  }
  throw Exception('Generator for $T not found');
}
```

**Risk:** If `_dependencies[T]` is wrong type, runtime cast error
**Recommendation:** Use generic constraints or validation

---

## 5. Configuration Schema

### 5.1 Schema Definition

**Location:** `/home/user/fvm/lib/src/models/config_model.dart`

**Schema Hierarchy:**
```
Config (abstract)
├── EnvConfig (environment variables)
├── FileConfig (abstract, adds file-specific fields)
│   ├── AppConfig (global app config)
│   │   └── LocalAppConfig (mutable version)
│   └── ProjectConfig (project .fvmrc)
```

**Core Fields:**
```dart
// Config (base)
final String? cachePath;
final bool? useGitCache;
final String? gitCachePath;
final String? flutterUrl;

// FileConfig (adds)
final bool? privilegedAccess;
final bool? runPubGetOnSdkChanges;
final bool? updateVscodeSettings;
final bool? updateGitIgnore;
final bool? updateMelosSettings;

// AppConfig (adds)
final bool? disableUpdateCheck;
final DateTime? lastUpdateCheck;
final Set<FlutterFork> forks;

// ProjectConfig (adds)
final String? flutter;
final Map<String, String>? flavors;
```

### 5.2 Environment Variable Mapping

**Issue #14: Well-Defined but Underdocumented Env Vars**

**Location:** `/home/user/fvm/lib/src/models/config_model.dart:31`

```dart
String get envKey => 'FVM_${_recase.constantCase}';

// Generates:
ConfigOptions.cachePath    → FVM_CACHE_PATH
ConfigOptions.useGitCache  → FVM_USE_GIT_CACHE
ConfigOptions.gitCachePath → FVM_GIT_CACHE_PATH
ConfigOptions.flutterUrl   → FVM_FLUTTER_URL
```

**Also supported:**
```dart
// lib/src/services/app_config_service.dart
const String flutterGitUrl = 'FLUTTER_GIT_URL';  // Aliased to FVM_FLUTTER_URL
'FVM_HOME'  // Legacy fallback for FVM_CACHE_PATH
```

**Documentation Gap:** These env vars are documented in code but not in README or public API docs.

### 5.3 Configuration Merging Strategy

**Location:** `/home/user/fvm/lib/src/services/app_config_service.dart:33`

```dart
static AppConfig createAppConfig({
  required LocalAppConfig globalConfig,
  required Config? envConfig,
  required ProjectConfig? projectConfig,
  required AppConfig? overrides,
}) {
  // Merge order (last wins):
  // 1. globalConfig
  // 2. envConfig
  // 3. projectConfig
  // 4. overrides

  final validConfigs =
      [globalConfig, envConfig, projectConfig, overrides].whereType<Config>();

  var appConfig = AppConfig();
  for (final config in validConfigs) {
    appConfig = appConfig.copyWith.$merge(config);
  }
  return appConfig;
}
```

**Precedence Order:**
1. Global config (`~/.config/fvm/.fvmrc` or `~/Library/Application Support/fvm/.fvmrc`)
2. Environment variables
3. Project config (`.fvmrc`)
4. Runtime overrides

**Issue #15: Merge Semantics Unclear**

**Problem:** What happens when merging nullable bools?

```dart
// Global config
{ "useGitCache": true }

// Project config
{ "useGitCache": null }

// Result: ???
```

**Actual behavior:** `copyWith.$merge()` preserves non-null values, so result is `true`.
**Documentation:** Not specified anywhere in API docs.

### 5.4 Unknown Key Handling

**Issue #16: Silent Unknown Key Ignoring**

**Current Behavior:**
```json
// .fvmrc
{
  "flutter": "3.19.0",
  "typo_flavors": {},  // Typo - silently ignored
  "experimental": true  // Unknown field - silently ignored
}
```

**Code:**
```dart
@MappableClass(ignoreNull: true)  // Also ignores unknown keys
class ProjectConfig extends FileConfig { ... }

static ProjectConfig fromJson(String json) {
  return ProjectConfig.fromMap(jsonDecode(json));  // No validation
}
```

**Risk:**
- User typos go unnoticed
- Future FVM versions might add fields that conflict
- No migration path for deprecated fields

**Recommendation:**
```dart
static ProjectConfig fromJson(String json) {
  final map = jsonDecode(json);
  final knownKeys = {'flutter', 'flavors', 'cachePath', ...};
  final unknownKeys = map.keys.where((k) => !knownKeys.contains(k));

  if (unknownKeys.isNotEmpty) {
    logger.warn('Unknown config keys: ${unknownKeys.join(', ')}');
  }

  return ProjectConfig.fromMap(map);
}
```

### 5.5 Legacy Config Support

**Issue #17: Dual Config File Maintenance**

**Location:** `/home/user/fvm/lib/src/models/config_model.dart:250`

```dart
static ProjectConfig? loadFromDirectory(Directory directory) {
  final configFile = File(p.join(directory.path, kFvmConfigFileName));  // .fvmrc

  if (configFile.existsSync()) {
    return ProjectConfig.fromJson(configFile.readAsStringSync());
  }

  // Fall back to legacy config file
  final legacyConfigFile = File(
    p.join(directory.path, kFvmDirName, kFvmLegacyConfigFileName),  // .fvm/fvm_config.json
  );

  if (legacyConfigFile.existsSync()) {
    return ProjectConfig.fromJson(legacyConfigFile.readAsStringSync());
  }

  return null;
}
```

**Also maintains both files:**
```dart
// lib/src/services/project_service.dart:104
projectConfig.write(config.toJson());           // Write .fvmrc
legacyConfigFile.write(config.toLegacyJson());  // Write .fvm/fvm_config.json
```

**Good:** Excellent backward compatibility
**Concern:** No deprecation timeline or migration path documented
**Risk:** Dual maintenance burden forever

---

## 6. Critical Issues Summary

### High Priority

1. **Null Assertion Crashes in Release Parsing** (Issue #11)
   - **Location:** `flutter_releases_model.dart:117`
   - **Impact:** App crashes if Flutter releases API returns unexpected data
   - **Fix:** Add null checks before force unwrapping

2. **Version Matching Logic Inconsistency** (Issue #10)
   - **Location:** `cache_service.dart:318`
   - **Impact:** Asymmetric pre-release matching rules could cause confusion
   - **Fix:** Document rationale or make symmetric

3. **Silent Config Field Ignoring** (Issue #16)
   - **Location:** All config models
   - **Impact:** User typos and mistakes go unnoticed
   - **Fix:** Add unknown key validation with warnings

### Medium Priority

4. **Inconsistent Error Handling** (Issue #2)
   - **Impact:** API consumers don't know when to expect null vs exceptions
   - **Fix:** Standardize error signaling patterns

5. **Unclear Public/Internal Boundaries** (Issue #5)
   - **Impact:** Internal utilities exposed as public API
   - **Fix:** Use `@internal` annotation, split utils

6. **Unsafe Dynamic Casts** (Issue #12)
   - **Impact:** Potential runtime errors on malformed data
   - **Fix:** Add proper type checking

### Low Priority

7. **Documentation Gaps** (Issues #8, #9)
   - **Impact:** Harder for API consumers to use correctly
   - **Fix:** Add comprehensive doc comments

8. **Legacy Config Indefinite Support** (Issue #17)
   - **Impact:** Maintenance burden
   - **Fix:** Document deprecation timeline

---

## 7. Recommendations

### Immediate Actions

1. **Add Null Safety Guards**
   ```dart
   // In flutter_releases_model.dart
   if (devRelease == null || betaRelease == null || stableRelease == null) {
     throw AppException('Invalid releases data: missing required channels');
   }
   ```

2. **Standardize Error Handling**
   - Document in CONTRIBUTING.md when to use:
     - Return `null` (expected absence, e.g., optional config)
     - Throw `AppException` (user error, e.g., invalid input)
     - Throw `StateError` (programming error, e.g., invalid state)

3. **Add Config Validation**
   ```dart
   static ProjectConfig fromJson(String json) {
     final map = jsonDecode(json);
     _validateConfig(map);  // Warn on unknown keys
     return ProjectConfig.fromMap(map);
   }
   ```

### Short-term Improvements

4. **Enhance Documentation**
   - Add "API Stability" section to README
   - Document all environment variables
   - Add examples for each public API method

5. **Clarify Public API**
   - Add `@internal` annotation to internal utilities
   - Create `lib/src/internal/` directory
   - Only export truly public APIs

6. **Improve Type Safety**
   - Replace unsafe casts with proper type checking
   - Add validation at all JSON parsing boundaries
   - Use sealed classes for sum types where appropriate

### Long-term Strategy

7. **API Versioning Strategy**
   - Document breaking change policy
   - Use semantic versioning strictly
   - Maintain CHANGELOG with API changes

8. **Deprecation Process**
   - Set timeline for legacy config removal (e.g., v5.0)
   - Add deprecation warnings to legacy config usage
   - Provide migration tool

9. **Schema Validation**
   - Consider JSON Schema for config files
   - Add `fvm doctor` command to validate config
   - Provide helpful error messages for invalid configs

---

## 8. API Contract Checklist

### Current State

- ✅ Public API clearly exported in `lib/fvm.dart`
- ✅ Strong null safety throughout
- ✅ Comprehensive use of immutable models
- ✅ Good backward compatibility (legacy config support)
- ⚠️ Mixed error handling patterns (null vs exceptions)
- ⚠️ Some internal APIs exposed publicly
- ⚠️ Silent config validation failures
- ❌ Inconsistent async/sync boundaries
- ❌ Limited API documentation
- ❌ No versioning policy documented

### Ideal State Targets

- [ ] All public APIs have comprehensive documentation
- [ ] Consistent error handling across all services
- [ ] Clear internal vs public API separation
- [ ] Config validation with helpful errors
- [ ] Documented API stability guarantees
- [ ] JSON Schema for config files
- [ ] Type-safe dependency injection
- [ ] Async/sync patterns documented and consistent

---

## 9. Testing Recommendations

### API Contract Tests Needed

1. **Version Parsing Tests**
   ```dart
   test('parse rejects invalid formats with clear errors', () {
     expect(() => FlutterVersion.parse('invalid/version/format'),
            throwsA(isA<FormatException>()));
   });
   ```

2. **Config Validation Tests**
   ```dart
   test('warns on unknown config keys', () {
     final json = '{"flutter": "3.19.0", "unknownKey": "value"}';
     expect(() => ProjectConfig.fromJson(json),
            printsWarning(contains('unknownKey')));
   });
   ```

3. **Null Safety Tests**
   ```dart
   test('handles malformed releases data gracefully', () {
     final malformed = '{"releases": [], "current_release": {}}';
     expect(() => FlutterReleasesResponse.fromJson(malformed),
            throwsA(isA<AppException>()));
   });
   ```

---

## 10. Conclusion

The FVM codebase demonstrates a **generally well-designed API** with strong type safety and clear separation of concerns. The main API contract issues are:

**Strengths:**
- Clear public API surface
- Excellent null safety
- Good backward compatibility
- Well-structured configuration hierarchy

**Areas for Improvement:**
- **Error handling consistency** - Standardize null vs exception patterns
- **API documentation** - Add comprehensive docs for all public methods
- **Config validation** - Warn on unknown keys and typos
- **Type safety** - Remove unsafe casts at boundaries
- **Public/internal separation** - Use @internal for internal APIs

**Critical Fixes Needed:**
1. Null safety guards in release parsing
2. Config unknown key validation
3. Standardized error handling documentation

Overall API contract maturity: **7/10** - Solid foundation with room for improvement in consistency and documentation.

---

**Report Generated:** 2025-12-24
**Analyzer:** Claude Code (Sonnet 4.5)
**Files Analyzed:** 72 Dart files in `/home/user/fvm/lib/`
