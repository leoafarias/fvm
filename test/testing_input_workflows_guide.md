# Testing Input Workflows Guide

This guide provides a systematic approach to reviewing and implementing tests for workflows that require user input (confirmations, selections, etc.) in the FVM codebase.

## Table of Contents
1. [Overview](#overview)
2. [The TestLogger Pattern](#the-testlogger-pattern)
3. [Step-by-Step Review Process](#step-by-step-review-process)
4. [Implementation Examples](#implementation-examples)
5. [Extending TestLogger](#extending-testlogger)
6. [Best Practices](#best-practices)

## Overview

Many workflows in FVM require user interaction through confirmations or selections. Testing these workflows requires simulating user input, which we achieve using the TestLogger pattern.

### Why Test Input Workflows?
- Ensure proper behavior for both positive and negative user responses
- Verify error handling when users decline operations
- Maintain consistent UX across the application
- Prevent regressions in critical user flows

## The TestLogger Pattern

The TestLogger is a test utility that extends the regular Logger to simulate user input:

```dart
class TestLogger extends Logger {
  final Map<String, bool> _confirmResponses = {};
  
  TestLogger(FvmContext context) : super(context);
  
  void setConfirmResponse(String promptPattern, bool response) {
    _confirmResponses[promptPattern] = response;
  }
  
  @override
  bool confirm(String? message, {required bool defaultValue}) {
    if (message != null) {
      outputs.add(message);
      for (final entry in _confirmResponses.entries) {
        if (message.contains(entry.key)) {
          info('User response: ${entry.value ? "Yes" : "No"}');
          return entry.value;
        }
      }
    }
    return super.confirm(message, defaultValue: defaultValue);
  }
}
```

## Step-by-Step Review Process

### 1. Identify Input Workflows

Search for workflows using user input:

```bash
# Find confirmation prompts
grep -r "logger\.confirm(" lib/

# Find selection prompts  
grep -r "logger\.select(" lib/

# Find cache version selectors
grep -r "logger\.cacheVersionSelector(" lib/
```

### 2. Check Existing Tests

For each workflow found, check if tests exist:

```bash
# Example for a workflow
grep -r "WorkflowName.*test" test/
```

### 3. Analyze the Input Flow

For each workflow, document:
- What prompt is shown to the user
- What the default value is
- What happens on Yes/No or each selection
- What errors might be thrown

### 4. Design Test Scenarios

For each input point, design tests for:
- User accepts (Yes/positive response)
- User declines (No/negative response)
- Default behavior (timeout/CI environment)
- Error scenarios

## Implementation Examples

### Example 1: Testing a Confirmation Workflow

Let's implement tests for `verify_project.workflow.dart`:

```dart
import 'dart:io';
import 'package:fvm/src/models/config_model.dart';
import 'package:fvm/src/services/logger_service.dart';
import 'package:fvm/src/services/project_service.dart';
import 'package:fvm/src/utils/exceptions.dart';
import 'package:fvm/src/workflows/verify_project.workflow.dart';
import 'package:test/test.dart';
import '../testing_utils.dart';
import 'test_logger.dart';

void main() {
  group('VerifyProjectWorkflow', () {
    late TestCommandRunner runner;

    setUp(() {
      runner = TestFactory.commandRunner();
    });

    test('should pass when project has pubspec', () async {
      final testDir = createTempDir();
      createPubspecYaml(testDir);
      
      final project = runner.context.get<ProjectService>()
          .findAncestor(directory: testDir);
      final workflow = VerifyProjectWorkflow(runner.context);
      
      // Should not throw
      expect(() => workflow(project, force: false), returnsNormally);
    });

    test('should pass with force flag even without pubspec', () async {
      final testDir = createTempDir();
      // No pubspec created
      
      final project = runner.context.get<ProjectService>()
          .findAncestor(directory: testDir);
      final workflow = VerifyProjectWorkflow(runner.context);
      
      // Should not throw with force
      expect(() => workflow(project, force: true), returnsNormally);
    });

    group('user confirmation', () {
      test('should continue when user confirms', () async {
        final testDir = createTempDir();
        // No pubspec - will trigger confirmation
        
        // Create context with TestLogger that says Yes
        final context = TestFactory.context(
          generators: {
            Logger: (context) => TestLogger(context)
              ..setConfirmResponse('Would you like to continue?', true),
          },
        );
        
        final customRunner = TestCommandRunner(context);
        final project = customRunner.context.get<ProjectService>()
            .findAncestor(directory: testDir);
        final workflow = VerifyProjectWorkflow(customRunner.context);
        
        // Should not throw when user confirms
        expect(() => workflow(project, force: false), returnsNormally);
        
        // Verify the prompt was shown
        final logger = customRunner.context.get<Logger>();
        expect(
          logger.outputs.any((msg) => msg.contains('No pubspec.yaml detected')),
          isTrue,
        );
      });

      test('should throw ForceExit when user declines', () async {
        final testDir = createTempDir();
        // No pubspec - will trigger confirmation
        
        // Create context with TestLogger that says No
        final context = TestFactory.context(
          generators: {
            Logger: (context) => TestLogger(context)
              ..setConfirmResponse('Would you like to continue?', false),
          },
        );
        
        final customRunner = TestCommandRunner(context);
        final project = customRunner.context.get<ProjectService>()
            .findAncestor(directory: testDir);
        final workflow = VerifyProjectWorkflow(customRunner.context);
        
        // Should throw when user declines
        expect(
          () => workflow(project, force: false),
          throwsA(isA<ForceExit>()),
        );
      });
    });
  });
}
```

### Example 2: Testing Dependency Resolution Confirmation

For `resolve_project_deps.workflow.dart`:

```dart
void main() {
  group('ResolveProjectDependenciesWorkflow', () {
    group('when pub get fails', () {
      test('should continue when user confirms', () async {
        final testDir = createTempDir();
        createPubspecYaml(testDir);
        
        // Create context with TestLogger that says Yes
        final context = TestFactory.context(
          generators: {
            Logger: (context) => TestLogger(context)
              ..setConfirmResponse('continue pinning this version anyway?', true),
          },
        );
        
        // Mock the flutter service to simulate pub get failure
        // ... implementation details ...
        
        final workflow = ResolveProjectDependenciesWorkflow(context);
        
        // Should return true when user confirms
        final result = await workflow(project, version, force: false);
        expect(result, isTrue);
      });

      test('should throw AppException when user declines', () async {
        final testDir = createTempDir();
        createPubspecYaml(testDir);
        
        // Create context with TestLogger that says No
        final context = TestFactory.context(
          generators: {
            Logger: (context) => TestLogger(context)
              ..setConfirmResponse('continue pinning this version anyway?', false),
          },
        );
        
        // Mock the flutter service to simulate pub get failure
        // ... implementation details ...
        
        final workflow = ResolveProjectDependenciesWorkflow(context);
        
        // Should throw when user declines
        expect(
          () async => await workflow(project, version, force: false),
          throwsA(isA<AppException>()
            .having((e) => e.message, 'message', contains('Dependencies not resolved'))),
        );
      });

      test('should skip confirmation with force flag', () async {
        // When force: true, should not ask for confirmation
        // ... implementation ...
      });
    });
  });
}
```

## Extending TestLogger

### Adding Selection Support

To test workflows that use `logger.select()`, extend TestLogger:

```dart
class TestLogger extends Logger {
  final Map<String, bool> _confirmResponses = {};
  final Map<String, int> _selectResponses = {};
  
  TestLogger(FvmContext context) : super(context);
  
  void setConfirmResponse(String promptPattern, bool response) {
    _confirmResponses[promptPattern] = response;
  }
  
  void setSelectResponse(String promptPattern, int optionIndex) {
    _selectResponses[promptPattern] = optionIndex;
  }
  
  @override
  bool confirm(String? message, {required bool defaultValue}) {
    // ... existing implementation ...
  }
  
  @override
  String select(
    String? message, {
    required List<String> options,
    int? defaultSelection,
  }) {
    if (message != null) {
      outputs.add(message);
      for (final entry in _selectResponses.entries) {
        if (message.contains(entry.key)) {
          final index = entry.value;
          if (index >= 0 && index < options.length) {
            info('User selected: ${options[index]}');
            return options[index];
          }
        }
      }
    }
    return super.select(message, options: options, defaultSelection: defaultSelection);
  }
}
```

### Testing Selection Workflows

Example for `ensure_cache.workflow.dart`:

```dart
test('should move SDK when user selects first option', () async {
  final context = TestFactory.context(
    generators: {
      Logger: (context) => TestLogger(context)
        ..setSelectResponse('How would you like to resolve this?', 0), // First option
    },
  );
  
  // ... rest of test implementation
});

test('should remove and reinstall when user selects second option', () async {
  final context = TestFactory.context(
    generators: {
      Logger: (context) => TestLogger(context)
        ..setSelectResponse('How would you like to resolve this?', 1), // Second option
    },
  );
  
  // ... rest of test implementation
});
```

## Best Practices

### 1. Test All Paths
- Always test both positive and negative responses
- Test default behavior (what happens in CI/automated environments)
- Test force flags that bypass confirmations

### 2. Verify Output Messages
```dart
// Always verify the user saw the expected prompt
expect(
  logger.outputs.any((msg) => msg.contains('Expected prompt text')),
  isTrue,
  reason: 'User should see the confirmation prompt',
);
```

### 3. Test Error Messages
```dart
// Verify appropriate error messages when user declines
expect(
  () => workflow.call(),
  throwsA(isA<AppException>()
    .having((e) => e.message, 'message', contains('specific error text'))),
);
```

### 4. Use Descriptive Test Names
```dart
test('should abort cache destruction when user declines confirmation', () {
  // More descriptive than "should handle no response"
});
```

### 5. Group Related Tests
```dart
group('VerifyProjectWorkflow', () {
  group('with valid project', () {
    // Tests for valid scenarios
  });
  
  group('with invalid project', () {
    group('user confirmations', () {
      test('when user confirms', () {});
      test('when user declines', () {});
    });
  });
});
```

### 6. Document Complex Scenarios
```dart
test('should handle SDK conflict resolution', () {
  // When: User has Flutter 3.0.0 installed but in wrong directory
  // And: User tries to install 3.0.0 again
  // Then: Should prompt for conflict resolution
  // And: When user selects "move", should move existing SDK
});
```

## Checklist for New Input Workflow Tests

- [ ] Identify all user input points (confirm, select, etc.)
- [ ] Document what each prompt asks and its default value
- [ ] Create test for positive response (Yes/First option)
- [ ] Create test for negative response (No/Other options)
- [ ] Create test for force flag (if applicable)
- [ ] Verify correct prompts are shown
- [ ] Verify correct actions are taken based on response
- [ ] Verify error handling for negative responses
- [ ] Test in CI context (skipInput scenarios)
- [ ] Add TestLogger responses for all prompts

## Common Patterns

### Pattern 1: Destructive Operations
```dart
// Always default to false for destructive operations
final confirm = logger.confirm(
  'This will delete everything. Continue?',
  defaultValue: false, // Safe default
);
```

### Pattern 2: Optional Enhancements
```dart
// Can default to true for non-destructive enhancements
final confirm = logger.confirm(
  'Would you like to update your configuration?',
  defaultValue: true, // Convenience default
);
```

### Pattern 3: Force Flags
```dart
if (force) {
  logger.warn('Skipping confirmation due to --force flag');
  return true;
}

final confirm = logger.confirm('Continue?', defaultValue: false);
```

## Workflow Test Status

| Workflow | Has Tests | Needs Input Tests | Priority |
|----------|-----------|-------------------|----------|
| update_melos_settings | ✅ | ✅ (Implemented) | - |
| verify_project | ❌ | ✅ | High |
| resolve_project_deps | ❌ | ✅ | High |
| check_project_constraints | ⚠️ | ✅ | Medium |
| ensure_cache (select) | ⚠️ | ✅ | Medium |
| destroy_command | ⚠️ | ✅ | High |
| remove_command | ⚠️ | ❓ (No confirm!) | High |

## Conclusion

Testing input workflows is crucial for maintaining a reliable CLI tool. The TestLogger pattern provides a clean, reusable way to simulate user input in tests. By following this guide, you can ensure all user interactions are properly tested and handle both positive and negative scenarios appropriately.