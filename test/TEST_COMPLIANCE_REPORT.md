# FVM Test Suite Compliance Report

## Overview

This report provides a comprehensive analysis of the FVM test suite compliance with the testing methodology defined in `TESTING_METHODOLOGY.md`. It identifies areas that need updates and provides guidance for implementing best practices.

## Executive Summary

- **Total Test Files Reviewed**: 35+ files
- **Files Following Best Practices**: ~40%
- **Files Needing Updates**: ~60%
- **Critical Issues**: Missing tearDown blocks, manual mocking instead of TestFactory

## Priority Updates Required

### 🔴 High Priority (13 files)

#### 1. Service Tests - Replace Manual Mocking with TestFactory (6 files)

**Files affected:**
- `test/services/app_config_service_test.dart` (needs complete rewrite)
- `test/services/cache_service_test.dart`
- `test/services/fork_cache_test.dart`
- `test/services/get_all_versions_test.dart`
- `test/src/services/project_service_test.dart`

**Current Issue:**
```dart
// ❌ BAD: Manual mocking
class _MockFVMContext extends Mock implements FVMContext {}

setUp(() {
  mockContext = _MockFVMContext();
  when(() => mockContext.versionsCachePath).thenReturn(tempDir.path);
  // ... more manual setup
});
```

**Best Practice:**
```dart
// ✅ GOOD: Use TestFactory
setUp(() {
  final context = TestFactory.context(
    debugLabel: 'cache-service-test',
    privilegedAccess: true,
  );
  
  tempDir = Directory.systemTemp.createTempSync('fvm_test_');
  when(() => context.versionsCachePath).thenReturn(tempDir.path);
  
  cacheService = CacheService(context);
});
```

#### 2. Workflow Tests - Add Missing tearDown Blocks (6 files)

**Files affected:**
- `test/src/workflows/resolve_project_deps_workflow_test.dart`
- `test/src/workflows/setup_gitignore.workflow_test.dart`  
- `test/src/workflows/update_melos_settings.workflow_test.dart`
- `test/src/workflows/update_project_references.workflow_test.dart`
- `test/src/workflows/update_vscode_settings.workflow_test.dart`
- `test/src/workflows/verify_project_workflow_test.dart`

**Current Issue:**
```dart
// ❌ BAD: No cleanup
test('workflow test', () {
  final testDir = createTempDir();
  // ... test implementation
  // No cleanup!
});
```

**Best Practice:**
```dart
// ✅ GOOD: Proper cleanup pattern
group('WorkflowTest:', () {
  late TestCommandRunner runner;
  final tempDirs = <Directory>[];
  
  setUp(() {
    runner = TestFactory.commandRunner();
  });
  
  tearDown(() {
    // Clean up ALL temp directories
    for (final dir in tempDirs) {
      if (dir.existsSync()) {
        dir.deleteSync(recursive: true);
      }
    }
    tempDirs.clear();
  });
  
  // Helper to track directories
  Directory createTrackedTempDir() {
    final dir = createTempDir();
    tempDirs.add(dir);
    return dir;
  }
  
  test('specific behavior', () {
    final testDir = createTrackedTempDir();
    // ... test implementation
  });
});
```

#### 3. Command Test - Add setUp/tearDown (1 file)

**File affected:**
- `test/commands/fork_command_test.dart`

**Current Issue:**
```dart
// ❌ BAD: Creates runner in each test
test('test 1', () {
  final runner = TestFactory.commandRunner();
  // ...
});

test('test 2', () {
  final runner = TestFactory.commandRunner();
  // ...
});
```

**Best Practice:**
```dart
// ✅ GOOD: Shared setup
group('Fork command:', () {
  late TestCommandRunner runner;
  
  setUp(() {
    runner = TestFactory.commandRunner();
  });
  
  tearDown(() {
    // Clean up any global state changes
    final context = runner.context;
    final config = context.get<AppConfigService>();
    // Remove test forks from global config
  });
  
  test('specific behavior', () async {
    final exitCode = await runner.run(['fvm', 'fork', 'stable', 'my-fork']);
    expect(exitCode, ExitCode.success.code);
  });
});
```

### 🟡 Medium Priority (5 files)

#### 1. Add Failure Test Cases

**Files affected:**
- `test/commands/alias_command_test.dart`
- `test/commands/flutter_command_test.dart`
- `test/src/commands/api_command_test.dart`

**Example Pattern:**
```dart
group('Command error handling:', () {
  test('handles invalid arguments gracefully', () {
    expect(
      () => runner.runOrThrow(['fvm', 'install', 'invalid-version']),
      throwsA(isA<AppException>()),
    );
  });
  
  test('provides helpful error messages', () {
    expect(
      () => runner.runOrThrow(['fvm', 'use', 'non-existent']),
      throwsA(
        isA<AppException>().having(
          (e) => e.message,
          'message',
          contains('Flutter version "non-existent" not found'),
        ),
      ),
    );
  });
});
```

#### 2. Change setUpAll to setUp

**File affected:**
- `test/commands/flutter_command_test.dart`

**Current Issue:**
```dart
// ❌ AVOID: Shared state between tests
setUpAll(() {
  runner = TestFactory.commandRunner();
});
```

**Best Practice:**
```dart
// ✅ GOOD: Fresh state for each test
setUp(() {
  runner = TestFactory.commandRunner();
});
```

#### 3. Expand Test Coverage

**File affected:**
- `test/src/services/flutter_service_test.dart`

Add tests for missing service methods following this pattern:
```dart
group('FlutterService:', () {
  late FlutterService flutterService;
  late TestContext context;
  
  setUp(() {
    context = TestFactory.context();
    flutterService = FlutterService(context);
  });
  
  group('runPubGet:', () {
    test('executes successfully', () async {
      // Test implementation
    });
    
    test('handles failure gracefully', () async {
      // Test error case
    });
  });
  
  // Add groups for other service methods
});
```

### 🟢 Low Priority (4 files)

#### 1. Minor Code Updates
- Fix typo in `test/models/flutter_version_model_test.dart` (line 5: "correclty" → "correctly")
- Move misplaced test in `test/utils/helpers_test.dart` into appropriate group
- Add setUp block to main group in `test/commands/install_command_test.dart`
- Add more failure cases to `test/src/commands/api_command_test.dart`

## Best Practices Reference

### 1. User Input Testing

Use `TestLogger` for simulating user interactions:

```dart
group('Interactive commands:', () {
  test('continues when user confirms', () async {
    final context = TestFactory.context(
      generators: {
        Logger: (context) => TestLogger(context)
          ..setConfirmResponse('Delete all versions?', true),
      },
    );
    
    final runner = TestCommandRunner(context);
    final exitCode = await runner.run(['fvm', 'destroy']);
    expect(exitCode, ExitCode.success.code);
  });
  
  test('handles user selection', () async {
    final context = TestFactory.context(
      generators: {
        Logger: (context) => TestLogger(context)
          ..setSelectResponse('Choose version:', 1), // Select second option
      },
    );
    
    // Test implementation
  });
});
```

### 2. Parameterized Testing

For testing multiple scenarios:

```dart
group('Version parsing:', () {
  final testCases = [
    ('stable', true, 'channel'),
    ('beta', true, 'channel'),
    ('3.10.0', true, 'release'),
    ('invalid', false, null),
  ];
  
  for (final (input, isValid, type) in testCases) {
    test('parses "$input" correctly', () {
      if (isValid) {
        final version = FlutterVersion.parse(input);
        expect(version.name, equals(input));
        expect(version.type, equals(type));
      } else {
        expect(
          () => FlutterVersion.parse(input),
          throwsA(isA<Exception>()),
        );
      }
    });
  }
});
```

### 3. Platform-Specific Testing

```dart
test('handles platform-specific paths', () {
  if (Platform.isWindows) {
    expect(convertPath('C:\\Users\\Test'), equals('C:/Users/Test'));
  } else {
    expect(convertPath('/home/user'), equals('/home/user'));
  }
});

test('skips on incompatible platforms', () {
  if (Platform.isWindows) {
    return; // Skip test on Windows
  }
  
  // Unix-specific test implementation
});
```

### 4. Test Organization Checklist

For each test file, ensure:

- [ ] Uses `TestFactory.commandRunner()` for command tests
- [ ] Uses `TestFactory.context()` for service tests  
- [ ] Has proper `setUp()` and `tearDown()` blocks
- [ ] Cleans up all temporary resources
- [ ] Tests both success and failure paths
- [ ] Uses descriptive test names
- [ ] Groups related tests with `group()`
- [ ] Follows AAA pattern (Arrange, Act, Assert)
- [ ] Uses `TestLogger` for user input when applicable
- [ ] Handles platform-specific behavior appropriately

## Examples of Well-Written Tests

### 1. Excellent User Input Testing
- `test/src/commands/destroy_command_test.dart`
- `test/src/commands/remove_command_test.dart`

### 2. Comprehensive Workflow Testing
- `test/src/workflows/verify_project_workflow_test.dart`
- `test/src/workflows/update_melos_settings.workflow_test.dart`

### 3. Thorough Utility Testing
- `test/src/utils/file_lock_test.dart`
- `test/utils/compare_semver_test.dart`

## Testing Commands

```bash
# Run all tests
dart test

# Run specific test file
dart test test/commands/install_command_test.dart

# Run tests with coverage
dart run grinder coverage

# Run tests matching pattern
dart test --name "install"

# Run tests in watch mode
dart test --reporter expanded --watch
```

## Next Steps

1. **Immediate Actions:**
   - Fix all missing tearDown blocks in workflow tests
   - Start replacing manual mocks with TestFactory in service tests

2. **Short-term Goals:**
   - Add failure test cases to commands with limited coverage
   - Update fork_command_test.dart structure

3. **Long-term Improvements:**
   - Achieve consistent testing patterns across all files
   - Consider adding integration tests for end-to-end workflows
   - Set up automated checks to ensure new tests follow the methodology

## Conclusion

The FVM test suite has a solid foundation but needs updates to fully comply with the testing methodology. The most critical issues are:

1. **Resource Management**: Many tests create temporary directories without proper cleanup
2. **Test Utilities**: Service tests use manual mocking instead of TestFactory
3. **Test Coverage**: Some commands lack failure case testing

By addressing these issues systematically, starting with high-priority items, the test suite will become more maintainable, reliable, and easier to extend.