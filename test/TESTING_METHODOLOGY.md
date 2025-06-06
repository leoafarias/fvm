# FVM Testing Methodology Guide

## Core Testing Principles

### Use Testing Utilities
The FVM project provides excellent testing utilities that simplify test creation:

```dart
// Create isolated test context
final context = TestFactory.context(
  debugLabel: 'my-test',
  privilegedAccess: true,
  skipInput: false  // Enable for user input testing
);

// Create command runner for CLI testing
final runner = TestFactory.commandRunner(context: context);
```

### Test Structure Pattern
Follow this consistent pattern for all tests:

```dart
void main() {
  late TestCommandRunner runner;
  late Directory testDir;
  
  setUp(() {
    runner = TestFactory.commandRunner();
    testDir = createTempDir();
  });
  
  tearDown(() {
    if (testDir.existsSync()) {
      testDir.deleteSync(recursive: true);
    }
  });
  
  group('Feature:', () {
    test('specific behavior', () async {
      // Arrange
      createPubspecYaml(testDir);
      createProjectConfig(ProjectConfig(flutter: '3.10.0'), testDir);
      
      // Act
      final exitCode = await runner.run(['fvm', 'command', 'args']);
      
      // Assert
      expect(exitCode, ExitCode.success.code);
    });
  });
}
```

## Testing Different Components

### 1. Command Testing
Test CLI commands using TestCommandRunner:

```dart
group('Install command:', () {
  test('installs specific version', () async {
    final exitCode = await runner.run(['fvm', 'install', '3.10.0']);
    expect(exitCode, ExitCode.success.code);
    
    // Verify version was installed
    final context = runner.context;
    final cacheService = context.get<CacheService>();
    final version = FlutterVersion.parse('3.10.0');
    expect(cacheService.getVersion(version), isNotNull);
  });
  
  test('handles invalid version gracefully', () async {
    expect(
      () => runner.runOrThrow(['fvm', 'install', 'invalid-version']),
      throwsA(isA<AppException>()),
    );
  });
});
```

### 2. Workflow Testing
Test workflows that orchestrate complex operations:

```dart
group('UseVersionWorkflow:', () {
  test('switches Flutter version', () async {
    // Setup project
    createPubspecYaml(testDir);
    
    final project = runner.context.get<ProjectService>()
        .findAncestor(directory: testDir);
    final version = FlutterVersion.parse('3.10.0');
    
    final workflow = UseVersionWorkflow(runner.context);
    await workflow(project, version, force: false);
    
    // Verify version was set
    expect(project.config.flutter, equals('3.10.0'));
  });
});
```

### 3. Service Testing
Test services with proper mocking:

```dart
group('CacheService:', () {
  late CacheService cacheService;
  late Directory tempDir;
  
  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('fvm_cache_test_');
    final context = TestFactory.context();
    when(() => context.versionsCachePath).thenReturn(tempDir.path);
    cacheService = CacheService(context);
  });
  
  test('returns cached version when exists', () {
    final version = FlutterVersion.parse('stable');
    final versionDir = Directory(path.join(tempDir.path, 'stable'))
      ..createSync(recursive: true);
    
    final result = cacheService.getVersion(version);
    expect(result, isNotNull);
    expect(result!.name, equals('stable'));
  });
});
```

## User Input Testing

### Setting Up TestLogger
Use TestLogger to simulate user interactions:

```dart
group('user interactions:', () {
  test('continues when user confirms', () async {
    final context = TestFactory.context(
      generators: {
        Logger: (context) => TestLogger(context)
          ..setConfirmResponse('Would you like to continue?', true),
      },
    );
    
    final runner = TestCommandRunner(context);
    final exitCode = await runner.run(['fvm', 'destroy']);
    expect(exitCode, ExitCode.success.code);
  });
  
  test('aborts when user declines', () async {
    final context = TestFactory.context(
      generators: {
        Logger: (context) => TestLogger(context)
          ..setConfirmResponse('Would you like to continue?', false),
      },
    );
    
    final runner = TestCommandRunner(context);
    expect(
      () => runner.runOrThrow(['fvm', 'destroy']),
      throwsA(isA<ForceExit>()),
    );
  });
});
```

### Testing Selection Prompts
For workflows that present options:

```dart
test('handles user selection', () async {
  final context = TestFactory.context(
    generators: {
      Logger: (context) => TestLogger(context)
        ..setSelectResponse('How would you like to resolve?', 0), // First option
    },
  );
  
  // Test implementation
});
```

## Parameterized Testing

### Using Simple Loops
For testing multiple scenarios, use simple for loops:

```dart
group('version parsing:', () {
  final testCases = [
    ('stable', true),
    ('beta', true),
    ('dev', true),
    ('master', true),
    ('3.10.0', true),
    ('invalid-version', false),
  ];
  
  for (final (input, isValid) in testCases) {
    test('parses "$input" correctly', () {
      if (isValid) {
        expect(() => FlutterVersion.parse(input), returnsNormally);
      } else {
        expect(() => FlutterVersion.parse(input), throwsA(isA<Exception>()));
      }
    });
  }
});
```

### Path Testing Pattern
When testing paths, parameterize within the test group:

```dart
group('path conversions:', () {
  test('converts Windows paths', () {
    expect(convertToPosixPath('C\\Users\\Name'), equals('C/Users/Name'));
  });
  
  test('preserves Unix paths', () {
    expect(convertToPosixPath('/home/user'), equals('/home/user'));
  });
  
  test('handles empty paths', () {
    expect(convertToPosixPath(''), equals(''));
  });
});
```

## Error Testing

### Test Both Success and Failure
Always test error scenarios:

```dart
group('error handling:', () {
  test('provides helpful error for missing Flutter version', () {
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
  
  test('handles permission errors gracefully', () {
    // Skip on Windows where permissions work differently
    if (Platform.isWindows) return;
    
    // Test implementation
  });
});
```

## Test Helpers

### Project Setup Helpers
Use provided helpers to create test projects:

```dart
// Create a Flutter project
final projectDir = createTempDir();
createPubspecYaml(
  projectDir,
  name: 'test_app',
  sdkConstraint: '>=2.17.0 <4.0.0',
);

// Create FVM configuration
createProjectConfig(
  ProjectConfig(flutter: '3.10.0'),
  projectDir,
);

// Create Flutter version constraints
createPubspecLockYaml(
  projectDir,
  dartSdkVersion: '2.19.0',
);
```

### Mock Services
Use MockFlutterService to avoid real git operations:

```dart
final mockFlutterService = MockFlutterService();
when(() => mockFlutterService.runPubGet(any(), any()))
    .thenAnswer((_) async => ProcessResult(0, 0, '', ''));
```

## Best Practices

### 1. Test Organization
- Group related tests using `group()`
- Use descriptive test names that explain the scenario
- Keep tests focused on one behavior

### 2. Test Isolation
- Always clean up temporary resources in `tearDown()`
- Create fresh test contexts for each test
- Avoid shared state between tests

### 3. Assertion Patterns
```dart
// Use specific matchers
expect(result, isNotNull);
expect(version.name, equals('stable'));
expect(files, contains('pubspec.yaml'));

// Test async operations
expect(workflow(), completes);
expect(() async => await workflow(), throwsA(isA<AppException>()));

// Verify file operations
expect(File(path).existsSync(), isTrue);
expect(Directory(path).listSync(), hasLength(3));
```

### 4. Performance Considerations
- Mock expensive operations (git clones, network requests)
- Use `TestFactory.context()` for fast test contexts
- Run related tests in groups to share setup costs

### 5. Platform-Specific Testing
```dart
test('handles platform-specific behavior', () {
  if (Platform.isWindows) {
    // Windows-specific test
  } else {
    // Unix-specific test
  }
});
```

## Testing Checklist

For each new feature or bug fix:

1. **Unit Tests**
   - Test individual functions and methods
   - Test error conditions
   - Test edge cases

2. **Integration Tests**
   - Test command execution
   - Test workflow completion
   - Test file system changes

3. **User Input Tests**
   - Test confirmation prompts (Yes/No)
   - Test selection prompts
   - Test force flag behavior

4. **Error Handling**
   - Test invalid inputs
   - Test missing dependencies
   - Test permission failures

5. **Platform Tests**
   - Test on Windows paths
   - Test on Unix paths
   - Test platform-specific features

## Running Tests

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

## Summary

1. **Use TestFactory** for creating test contexts and runners
2. **Use TestLogger** for simulating user input
3. **Follow the AAA pattern**: Arrange, Act, Assert
4. **Test success and failure** scenarios
5. **Clean up resources** in tearDown()
6. **Use simple patterns** - avoid over-engineering
7. **Mock external dependencies** to keep tests fast
8. **Write descriptive test names** that explain the scenario