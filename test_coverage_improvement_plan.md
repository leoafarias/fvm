# FVM Test Coverage Improvement Plan

**Generated**: 2025-06-06  
**Current Overall Coverage**: 48.2% (2,748 of 5,702 lines)  
**Target Coverage**: 65-70% for critical paths

## Executive Summary

This document provides a prioritized plan for improving test coverage in FVM, focusing on the most critical user-facing commands and services. The recommendations are ordered by impact and implementation risk, with specific line numbers and code examples.

---

## 🟢 HIGH PRIORITY - Low Risk, High Impact

### 1. `install_command.dart` (Current: 72.7% → Target: 95%)

**Uncovered Lines**: 49-74, 88-90

**Impact**: 
- Used by every FVM user when setting up Flutter versions
- Handles common scenario: `fvm install` without arguments
- Affects project onboarding experience

**Missing Coverage**:
```dart
// Lines 49-74: Install from project config
if (argResults!.rest.isEmpty) {
  final project = context.get<ProjectService>().findAncestor();
  
  if (project == null || !project.hasConfig) {
    throw AppException('No Flutter version provided');
  }
  
  version = project.pinnedVersion;
  shouldSetup = !skipSetup;
}

// Lines 88-90: Invocation getter
String get invocation => 'fvm install <version>';
```

**Test Implementation**:
```dart
// test/commands/install_command_test.dart

group('Install from project config:', () {
  test('should install version from .fvmrc when no args', () async {
    final runner = TestFactory.commandRunner();
    final testDir = createTempDir();
    
    // Setup project with config
    createProjectConfig(
      ProjectConfig(flutter: '3.10.0'),
      testDir,
    );
    runner.workingDirectory = testDir;
    
    final exitCode = await runner.run(['fvm', 'install']);
    
    expect(exitCode, ExitCode.success.code);
    expect(
      runner.context.get<CacheService>().getVersion('3.10.0'),
      isNotNull,
    );
  });

  test('should throw when no args and no project config', () async {
    final runner = TestFactory.commandRunner();
    final testDir = createTempDir();
    runner.workingDirectory = testDir;
    
    expect(
      () => runner.run(['fvm', 'install']),
      throwsA(predicate<AppException>(
        (e) => e.message.contains('No Flutter version provided'),
      )),
    );
  });

  test('should respect skipSetup flag from project config', () async {
    final runner = TestFactory.commandRunner();
    final testDir = createTempDir();
    
    createProjectConfig(
      ProjectConfig(flutter: '3.10.0', skipSetup: true),
      testDir,
    );
    runner.workingDirectory = testDir;
    
    final exitCode = await runner.run(['fvm', 'install']);
    expect(exitCode, ExitCode.success.code);
    // Verify setup was skipped
  });
});
```

---

### 2. `cache_service.dart` - Global Version Methods (Current: 56.4% → Target: 70%)

**Uncovered Lines**: 178-182, 197-201, 204-209

**Impact**:
- Core functionality for `fvm global` command
- Affects system-wide Flutter usage
- Simple getters/setters with high usage

**Missing Coverage**:
```dart
// Lines 178-182: unlinkGlobal
void unlinkGlobal() {
  final link = Link(context.globalFlutterPath);
  if (link.existsSync()) {
    link.deleteSync();
  }
}

// Lines 197-201: isGlobal
bool isGlobal(FlutterVersion version) {
  final global = getGlobal();
  return global != null && global == version;
}

// Lines 204-209: getGlobalVersion (deprecated)
@Deprecated('Use getGlobal instead')
FlutterVersion? getGlobalVersion() {
  return getGlobal();
}
```

**Test Implementation**:
```dart
// test/services/cache_service_test.dart

group('Global version management:', () {
  late TestCommandRunner runner;
  late CacheService cacheService;
  
  setUp(() {
    runner = TestFactory.commandRunner();
    cacheService = runner.context.get<CacheService>();
  });

  test('complete global version lifecycle', () async {
    // Install a version first
    final version = await installTestVersion('3.10.0');
    
    // Test setGlobal
    cacheService.setGlobal(version);
    expect(Link(runner.context.globalFlutterPath).existsSync(), isTrue);
    
    // Test getGlobal
    final global = cacheService.getGlobal();
    expect(global?.name, '3.10.0');
    
    // Test isGlobal
    expect(cacheService.isGlobal(version), isTrue);
    
    final otherVersion = FlutterVersion.parse('3.13.0');
    expect(cacheService.isGlobal(otherVersion), isFalse);
    
    // Test unlinkGlobal
    cacheService.unlinkGlobal();
    expect(Link(runner.context.globalFlutterPath).existsSync(), isFalse);
    expect(cacheService.getGlobal(), isNull);
  });

  test('unlinkGlobal when no global set', () {
    // Should not throw
    expect(() => cacheService.unlinkGlobal(), returnsNormally);
  });

  test('deprecated getGlobalVersion', () async {
    final version = await installTestVersion('stable');
    cacheService.setGlobal(version);
    
    // ignore: deprecated_member_use_from_same_package
    final deprecated = cacheService.getGlobalVersion();
    expect(deprecated, equals(cacheService.getGlobal()));
  });
});
```

---

### 3. `use_command.dart` - Pin Option (Current: 55.6% → Target: 65%)

**Uncovered Lines**: 91-108

**Impact**:
- Enables version pinning from channels
- Prevents unexpected updates
- Common in CI/CD environments

**Missing Coverage**:
```dart
// Lines 91-108: Pin functionality
if (pin && flutterVersion.isChannel) {
  // Get latest release from channel
  final releases = await context.get<ReleasesService>().getReleases();
  final channelVersion = releases.getLatestChannelRelease(
    flutterVersion.name,
  );
  
  if (channelVersion == null) {
    throw AppException(
      'Could not find latest release for channel ${flutterVersion.name}',
    );
  }
  
  flutterVersion = FlutterVersion.parse(channelVersion);
  logger.info('Pinning version $flutterVersion');
}
```

**Test Implementation**:
```dart
// test/commands/use_command_test.dart

group('Pin functionality:', () {
  test('should pin channel to latest release', () async {
    final runner = TestFactory.commandRunner();
    final testDir = createTempDir();
    createFlutterProject(testDir);
    runner.workingDirectory = testDir;
    
    final exitCode = await runner.run(['fvm', 'use', 'stable', '--pin']);
    expect(exitCode, ExitCode.success.code);
    
    // Verify pinned to specific version, not channel
    final project = runner.context.get<ProjectService>().findAncestor()!;
    expect(project.pinnedVersion?.name, isNot('stable'));
    expect(project.pinnedVersion?.name, matches(r'^\d+\.\d+\.\d+'));
  });

  test('should fail gracefully for invalid channel', () async {
    final runner = TestFactory.commandRunner();
    final testDir = createTempDir();
    createFlutterProject(testDir);
    runner.workingDirectory = testDir;
    
    expect(
      () => runner.run(['fvm', 'use', 'invalid-channel', '--pin']),
      throwsA(predicate<AppException>(
        (e) => e.message.contains('Could not find latest release'),
      )),
    );
  });

  test('pin flag ignored for specific versions', () async {
    final runner = TestFactory.commandRunner();
    final testDir = createTempDir();
    createFlutterProject(testDir);
    runner.workingDirectory = testDir;
    
    final exitCode = await runner.run(['fvm', 'use', '3.10.0', '--pin']);
    expect(exitCode, ExitCode.success.code);
    
    final project = runner.context.get<ProjectService>().findAncestor()!;
    expect(project.pinnedVersion?.name, '3.10.0');
  });
});
```

---

## 🟡 MEDIUM PRIORITY - Medium Risk, High Impact

### 4. `ensure_cache.workflow.dart` - Corrupted Cache (Current: 38.7% → Target: 55%)

**Uncovered Lines**: 18-36

**Impact**:
- Critical for reliability and self-healing
- Prevents user frustration with corrupted installations
- Reduces support burden

**Missing Coverage**:
```dart
// Lines 18-36: Handle non-executable Flutter
Future<void> _handleNonExecutable(
  FlutterVersion version,
  CacheFlutterVersion cacheVersion,
  bool shouldInstall,
) async {
  if (shouldInstall) {
    logger.warn('Flutter executable not working correctly. Reinstalling...');
    await context.get<CacheService>().remove(version);
    await setupFlutterWorkflow(version);
  } else {
    throw AppException(
      'Flutter executable at ${cacheVersion.flutterExec} is not working correctly.\n'
      'Run "fvm install ${version.name}" to reinstall.',
    );
  }
}
```

**Test Implementation**:
```dart
// test/workflows/ensure_cache_workflow_test.dart

group('Corrupted cache handling:', () {
  test('should auto-reinstall corrupted cache when shouldInstall=true', () async {
    final runner = TestFactory.commandRunner();
    final workflow = EnsureCacheWorkflow(runner.context);
    
    // Create corrupted cache
    final version = FlutterVersion.parse('3.10.0');
    final cacheDir = createCorruptedFlutterCache(runner.context, version);
    
    // Should reinstall automatically
    final result = await workflow(version, shouldInstall: true);
    
    expect(result.directory, isNot(cacheDir.path));
    expect(File(result.flutterExec).existsSync(), isTrue);
    
    // Verify old corrupted cache was removed
    expect(cacheDir.existsSync(), isFalse);
  });

  test('should throw helpful error when shouldInstall=false', () async {
    final runner = TestFactory.commandRunner();
    final workflow = EnsureCacheWorkflow(runner.context);
    
    final version = FlutterVersion.parse('3.10.0');
    createCorruptedFlutterCache(runner.context, version);
    
    expect(
      () => workflow(version, shouldInstall: false),
      throwsA(predicate<AppException>((e) => 
        e.message.contains('is not working correctly') &&
        e.message.contains('Run "fvm install 3.10.0" to reinstall')
      )),
    );
  });
});

// Helper function
Directory createCorruptedFlutterCache(Context context, FlutterVersion version) {
  final cacheDir = Directory(
    path.join(context.versionsCachePath, version.name),
  )..createSync(recursive: true);
  
  // Create flutter executable that's not actually executable
  final flutterExec = File(
    path.join(cacheDir.path, 'bin', 'flutter'),
  )..createSync(recursive: true);
  
  flutterExec.writeAsStringSync('corrupted');
  
  return cacheDir;
}
```

---

### 5. `cache_service.dart` - Fork Cleanup (Current: 56.4% → Target: 65%)

**Uncovered Lines**: 119-134

**Impact**:
- Prevents cache directory bloat
- Important for fork users
- Clean uninstall experience

**Missing Coverage**:
```dart
// Lines 119-134: Fork directory cleanup
if (flutterVersion.isFork) {
  final forkDir = Directory(
    path.join(context.versionsCachePath, flutterVersion.fork!),
  );
  
  if (forkDir.existsSync()) {
    final contents = forkDir.listSync();
    if (contents.isEmpty) {
      forkDir.deleteSync();
      logger.detail('Removed empty fork directory: ${forkDir.path}');
    }
  }
}
```

**Test Implementation**:
```dart
// test/services/cache_service_test.dart

group('Fork cleanup:', () {
  test('should remove empty fork directory after removing last version', () async {
    final runner = TestFactory.commandRunner();
    final cacheService = runner.context.get<CacheService>();
    
    // Create fork structure
    final forkVersion = FlutterVersion.parse('mycompany/stable');
    final forkDir = Directory(
      path.join(runner.context.versionsCachePath, 'mycompany', 'stable'),
    )..createSync(recursive: true);
    
    // Add some Flutter files
    File(path.join(forkDir.path, 'bin', 'flutter'))
      ..createSync(recursive: true)
      ..writeAsStringSync('#!/bin/bash');
    
    // Remove the version
    await cacheService.remove(forkVersion);
    
    // Fork directory should be removed
    expect(
      Directory(path.join(runner.context.versionsCachePath, 'mycompany')).existsSync(),
      isFalse,
    );
  });

  test('should not remove fork directory with other versions', () async {
    final runner = TestFactory.commandRunner();
    final cacheService = runner.context.get<CacheService>();
    
    // Create multiple fork versions
    final version1 = FlutterVersion.parse('mycompany/stable');
    final version2 = FlutterVersion.parse('mycompany/beta');
    
    Directory(
      path.join(runner.context.versionsCachePath, 'mycompany', 'stable'),
    )..createSync(recursive: true);
    
    Directory(
      path.join(runner.context.versionsCachePath, 'mycompany', 'beta'),
    )..createSync(recursive: true);
    
    // Remove only one version
    await cacheService.remove(version1);
    
    // Fork directory should still exist
    expect(
      Directory(path.join(runner.context.versionsCachePath, 'mycompany')).existsSync(),
      isTrue,
    );
  });
});
```

---

### 6. `use_command.dart` - Flavor Support (Current: 55.6% → Target: 70%)

**Uncovered Lines**: 111-125

**Impact**:
- Enables multi-environment development
- Critical for teams with staging/prod environments
- Complex logic prone to bugs

**Missing Coverage**:
```dart
// Lines 111-125: Flavor version resolution
if (project?.config.flavors.containsKey(flutterVersion.name) ?? false) {
  final flavorVersion = project!.config.flavors[flutterVersion.name]!;
  flutterVersion = FlutterVersion.parse(flavorVersion);
  flavor = version;
  logger.info('Using Flutter version $flutterVersion for flavor $flavor');
}
```

**Test Implementation**:
```dart
// test/commands/use_command_test.dart

group('Flavor support:', () {
  test('should resolve flavor to version from config', () async {
    final runner = TestFactory.commandRunner();
    final testDir = createTempDir();
    
    // Create project with flavors
    createProjectConfig(
      ProjectConfig(
        flutter: 'stable',
        flavors: {
          'production': '3.10.0',
          'development': '3.13.0',
          'staging': 'beta',
        },
      ),
      testDir,
    );
    createFlutterProject(testDir);
    runner.workingDirectory = testDir;
    
    // Use production flavor
    final exitCode = await runner.run(['fvm', 'use', 'production']);
    expect(exitCode, ExitCode.success.code);
    
    // Verify correct version was set
    final project = runner.context.get<ProjectService>().findAncestor()!;
    expect(project.pinnedVersion?.name, '3.10.0');
    expect(project.activeFlavor, 'production');
  });

  test('should handle nested flavor versions', () async {
    final runner = TestFactory.commandRunner();
    final testDir = createTempDir();
    
    createProjectConfig(
      ProjectConfig(
        flutter: 'stable',
        flavors: {
          'dev': 'beta',  // Channel as flavor
        },
      ),
      testDir,
    );
    createFlutterProject(testDir);
    runner.workingDirectory = testDir;
    
    final exitCode = await runner.run(['fvm', 'use', 'dev']);
    expect(exitCode, ExitCode.success.code);
    
    final project = runner.context.get<ProjectService>().findAncestor()!;
    expect(project.pinnedVersion?.name, 'beta');
  });

  test('should prefer version over flavor if both exist', () async {
    final runner = TestFactory.commandRunner();
    final testDir = createTempDir();
    
    // Create a version that matches a flavor name
    await installTestVersion('3.10.0');
    
    createProjectConfig(
      ProjectConfig(
        flutter: 'stable',
        flavors: {'3.10.0': '3.13.0'}, // Weird but possible
      ),
      testDir,
    );
    createFlutterProject(testDir);
    runner.workingDirectory = testDir;
    
    // Should use as version, not flavor
    final exitCode = await runner.run(['fvm', 'use', '3.10.0']);
    expect(exitCode, ExitCode.success.code);
    
    final project = runner.context.get<ProjectService>().findAncestor()!;
    expect(project.pinnedVersion?.name, '3.10.0');
    expect(project.activeFlavor, isNull);
  });
});
```

---

## 🔴 LOWER PRIORITY - Higher Risk or Lower Impact

### 7. `ensure_cache.workflow.dart` - Version Mismatch (Current: 38.7% → Target: 50%)

**Uncovered Lines**: 39-71

**Impact**:
- Handles edge case of moved/renamed Flutter versions
- Interactive user flow increases complexity
- Less common scenario

**Test Implementation Requirements**:
- Requires interactive input simulation
- Complex state setup (mismatched versions)
- Multiple resolution paths to test

---

### 8. `flutter_service.dart` - Fork Errors (Current: 80.9% → Target: 85%)

**Uncovered Lines**: 95-108

**Impact**:
- Already has good coverage
- Fork usage is less common
- Error paths are important but lower priority

---

### 9. `use_version.workflow.dart` - UI Messages (Current: 42.8% → Target: 50%)

**Uncovered Lines**: 58-61, 66-79

**Impact**:
- Purely UI/messaging code
- No functional impact
- VS Code specific messages

---

## Implementation Strategy

### Phase 1 (Week 1)
1. Implement tests for `install_command.dart` - project config scenarios
2. Add global version management tests to `cache_service.dart`
3. Cover pin functionality in `use_command.dart`

### Phase 2 (Week 2)
4. Add corrupted cache handling tests
5. Implement fork cleanup tests
6. Add flavor support tests

### Phase 3 (If needed)
7. Interactive flow tests (version mismatch)
8. Additional error path coverage
9. UI message coverage

## Success Metrics

- Overall coverage increase from 48.2% to 60%+
- Critical commands (install, use) coverage > 80%
- Core services coverage > 70%
- Zero regression in existing tests
- All new tests follow existing patterns

## Testing Best Practices for Implementation

1. **Use existing test utilities**:
   ```dart
   final runner = TestFactory.commandRunner();
   final context = TestFactory.context();
   ```

2. **Clean up test directories**:
   ```dart
   late Directory testDir;
   
   setUp(() {
     testDir = createTempDir();
   });
   
   tearDown(() {
     if (testDir.existsSync()) {
       testDir.deleteSync(recursive: true);
     }
   });
   ```

3. **Mock user input when needed**:
   ```dart
   final logger = TestLogger(context);
   logger.setConfirmResponse('Continue?', true);
   logger.setSelectResponse('Choose option:', 0);
   ```

4. **Verify both success and error cases**:
   ```dart
   test('success case', () async {
     // ...
   });
   
   test('error case', () async {
     expect(
       () => runner.run(['fvm', 'command']),
       throwsA(isA<AppException>()),
     );
   });
   ```

## Notes

- All line numbers are from the current codebase
- Coverage percentages are from the latest test run
- Implementation examples use existing test patterns from the codebase
- Consider running `dart run grinder coverage` after each phase to track progress