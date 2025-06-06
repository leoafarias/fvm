# FVM Test Implementation Prompt & Process Guide

## Overview
This document provides a structured approach to implementing the test improvements outlined in `test_coverage_improvement_plan.md`, following the established testing methodology in `test/TESTING_METHODOLOGY.md`.

---

## Implementation Process

### Step 1: Environment Setup
Before implementing any tests, ensure your environment is ready:

```bash
# Run existing tests to verify baseline
dart test

# Check current coverage
dart run grinder coverage

# Create your test branch
git checkout -b test/improve-coverage-phase-1
```

### Step 2: Test File Organization
For each component being tested, follow this structure:

```
test/
├── commands/
│   ├── install_command_test.dart      # Enhance existing
│   └── use_command_test.dart          # Enhance existing
├── services/
│   └── cache_service_test.dart        # Enhance existing
└── workflows/
    └── ensure_cache_workflow_test.dart # Create new
```

### Step 3: Implementation Template
Use this template for each test file, adapting from the methodology:

```dart
import 'package:fvm/fvm.dart';
import 'package:test/test.dart';

import '../testing_utils.dart';

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
  
  group('Component being tested:', () {
    // Implementation here
  });
}
```

---

## Phase 1 Implementation Guide

### 1. Install Command - Project Config Support

**File**: `test/commands/install_command_test.dart`

**Implementation Checklist**:
- [ ] Add imports and test setup
- [ ] Create test group: `'Install from project config:'`
- [ ] Implement test: 'should install version from .fvmrc when no args'
- [ ] Implement test: 'should throw when no args and no project config'
- [ ] Implement test: 'should respect skipSetup flag from project config'
- [ ] Verify all tests pass
- [ ] Run coverage and confirm improvement

**Key Testing Patterns**:
```dart
// Use TestFactory for runner creation
final runner = TestFactory.commandRunner();

// Create project configuration
createProjectConfig(
  ProjectConfig(flutter: '3.10.0'),
  testDir,
);

// Set working directory
runner.workingDirectory = testDir;

// Test command execution
final exitCode = await runner.run(['fvm', 'install']);

// Verify using context services
final cacheService = runner.context.get<CacheService>();
```

### 2. Cache Service - Global Version Management

**File**: `test/services/cache_service_test.dart`

**Implementation Checklist**:
- [ ] Add test group: `'Global version management:'`
- [ ] Implement test: 'complete global version lifecycle'
- [ ] Implement test: 'unlinkGlobal when no global set'
- [ ] Implement test: 'deprecated getGlobalVersion'
- [ ] Add test group: `'Fork cleanup:'`
- [ ] Implement test: 'should remove empty fork directory'
- [ ] Implement test: 'should not remove fork directory with other versions'

**Key Testing Patterns**:
```dart
// Create service instance
final cacheService = runner.context.get<CacheService>();

// Install test version (helper)
final version = await installTestVersion('3.10.0');

// Test file system operations
expect(Link(runner.context.globalFlutterPath).existsSync(), isTrue);

// Clean assertions
expect(cacheService.getGlobal(), isNull);
```

### 3. Use Command - Pin Functionality

**File**: `test/commands/use_command_test.dart`

**Implementation Checklist**:
- [ ] Add test group: `'Pin functionality:'`
- [ ] Implement test: 'should pin channel to latest release'
- [ ] Implement test: 'should fail gracefully for invalid channel'
- [ ] Implement test: 'pin flag ignored for specific versions'
- [ ] Add test group: `'Flavor support:'`
- [ ] Implement test: 'should resolve flavor to version from config'
- [ ] Implement test: 'should handle nested flavor versions'
- [ ] Implement test: 'should prefer version over flavor if both exist'

**Key Testing Patterns**:
```dart
// Create Flutter project structure
createFlutterProject(testDir);

// Test with flags
final exitCode = await runner.run(['fvm', 'use', 'stable', '--pin']);

// Verify project state
final project = runner.context.get<ProjectService>().findAncestor()!;
expect(project.pinnedVersion?.name, matches(r'^\d+\.\d+\.\d+'));

// Test error conditions
expect(
  () => runner.run(['fvm', 'use', 'invalid-channel', '--pin']),
  throwsA(predicate<AppException>(
    (e) => e.message.contains('Could not find latest release'),
  )),
);
```

---

## Testing Methodology Reminders

### 1. Test Structure (AAA Pattern)
```dart
test('descriptive test name', () async {
  // Arrange - Set up test data and environment
  createProjectConfig(config, testDir);
  
  // Act - Execute the behavior being tested
  final result = await runner.run(['fvm', 'command']);
  
  // Assert - Verify the outcome
  expect(result, equals(expectedValue));
});
```

### 2. User Input Simulation
When testing interactive features:
```dart
final context = TestFactory.context(
  generators: {
    Logger: (context) => TestLogger(context)
      ..setConfirmResponse('Continue?', true)
      ..setSelectResponse('Choose option:', 0),
  },
);
```

### 3. Error Testing Pattern
Always test both success and failure:
```dart
group('error handling:', () {
  test('provides helpful error message', () {
    expect(
      () => runner.runOrThrow(['fvm', 'use', 'non-existent']),
      throwsA(
        isA<AppException>().having(
          (e) => e.message,
          'message',
          contains('not found'),
        ),
      ),
    );
  });
});
```

### 4. Platform-Specific Considerations
```dart
test('handles platform differences', () {
  if (Platform.isWindows) {
    // Windows-specific test
    return;
  }
  // Unix-specific test
});
```

---

## Validation Steps

After implementing each test group:

1. **Run the specific test file**:
   ```bash
   dart test test/commands/install_command_test.dart
   ```

2. **Check for regressions**:
   ```bash
   dart test
   ```

3. **Verify coverage improvement**:
   ```bash
   dart run grinder coverage
   # Check coverage/html_report/index.html
   ```

4. **Ensure code quality**:
   ```bash
   dart analyze
   dart format .
   ```

---

## Common Pitfalls to Avoid

1. **Don't forget cleanup**: Always use `tearDown()` to remove temp directories
2. **Avoid shared state**: Each test should be independent
3. **Mock expensive operations**: Use `MockFlutterService` for git operations
4. **Test edge cases**: Empty configs, missing files, permission errors
5. **Use descriptive names**: Test names should explain what's being tested

---

## Helper Functions Reference

### Project Setup
```dart
// Create basic Flutter project
createFlutterProject(Directory dir)

// Create pubspec.yaml
createPubspecYaml(Directory dir, {String? name, String? sdkConstraint})

// Create FVM config
createProjectConfig(ProjectConfig config, Directory dir)

// Create temporary directory
Directory createTempDir()
```

### Test Utilities
```dart
// Command runner with context
TestFactory.commandRunner({Context? context})

// Test context with custom generators
TestFactory.context({
  String? debugLabel,
  bool privilegedAccess = false,
  Map<Type, ObjectGenerator>? generators,
})

// Install test version (mock)
Future<FlutterVersion> installTestVersion(String version)
```

---

## Success Criteria

Each implemented test group should:
- ✅ Follow the established testing patterns
- ✅ Include both success and error cases
- ✅ Clean up all resources
- ✅ Have descriptive test names
- ✅ Improve coverage for the target file
- ✅ Pass all quality checks (analyze, format)
- ✅ Not break existing tests

---

## Next Steps

1. Start with Phase 1 tests (highest priority, lowest risk)
2. Create pull request after each component is complete
3. Monitor coverage improvements
4. Move to Phase 2 once Phase 1 is merged
5. Document any testing utilities created for reuse

---

## Questions to Ask During Implementation

Before writing each test:
1. What is the user trying to accomplish?
2. What could go wrong?
3. Are there edge cases to consider?
4. Is there existing test code I can reference?
5. Am I testing behavior, not implementation?

After writing each test:
1. Is the test name clear and descriptive?
2. Will this test be maintainable?
3. Have I cleaned up all resources?
4. Does it follow the AAA pattern?
5. Have I tested both success and failure?