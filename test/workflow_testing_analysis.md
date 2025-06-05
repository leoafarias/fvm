# FVM Workflow Testing Analysis & Recommendations

## Executive Summary

This document analyzes user input testing in FVM and proposes simple, practical improvements following KISS, YAGNI, and DRY principles.

## Current State Analysis

### Test Coverage Status

#### Workflows with User Input
| Workflow | Has Tests | Tests User Input | Input Methods Used | Priority |
|----------|-----------|------------------|-------------------|----------|
| `update_melos_settings` | ✅ | ✅ | `confirm()` (2x) | Complete |
| `verify_project` | ❌ | ❌ | `confirm()` | **HIGH** |
| `resolve_project_deps` | ❌ | ❌ | `confirm()` | **HIGH** |
| `check_project_constraints` | ❌ | ❌ | `confirm()` | **HIGH** |
| `ensure_cache` | ❌ | ❌ | `select()` | **MEDIUM** |

#### Commands with User Input
| Command | Has Tests | Tests User Input | Input Methods Used | Priority |
|---------|-----------|------------------|-------------------|----------|
| `destroy` | ❌ | ❌ | `confirm()` | **CRITICAL** |
| `remove` | ⚠️ | ❌ | `confirm()`, `cacheVersionSelector()` | **HIGH** |
| `global` | ⚠️ | ❌ | `cacheVersionSelector()` | **MEDIUM** |
| `use` | ✅ | ❌ | `cacheVersionSelector()` | **MEDIUM** |

### Key Findings

1. **Only 1 out of 9 components** properly tests user input scenarios (`update_melos_settings.workflow`)
2. **Critical destructive operations** (`destroy`, `remove`) lack proper test coverage
3. **No tests exist** for the `select()` method pattern (used in `ensure_cache`)
4. **No tests exist** for `cacheVersionSelector()` pattern (used in 3 commands)
5. The existing `TestLogger` only supports `confirm()` method, not `select()` or `cacheVersionSelector()`

## Identified Issues

### 1. Testing Infrastructure Limitations

#### Current TestLogger Limitations
- Only supports `confirm()` method
- Doesn't support `select()` or `cacheVersionSelector()`
- Pattern matching is simple substring matching (could be more robust)
- No support for multiple sequential prompts of the same type

#### Logger Service Issues
- Line 122: `if (_isTest) return defaultValue;` - This bypasses TestLogger in test mode
- This makes it impossible to test different user responses in tests
- The current approach always returns default value, preventing negative path testing

### 2. Test Coverage Gaps

#### High-Risk Untested Scenarios
1. **Destructive Operations Without Tests**
   - `destroy_command`: Deletes entire FVM cache
   - `remove_command`: Removes Flutter versions
   - Both use confirmations but have no tests

2. **Project Constraint Violations**
   - `check_project_constraints`: No tests for version incompatibility scenarios
   - `verify_project`: No tests for missing pubspec.yaml scenarios

3. **Dependency Resolution Failures**
   - `resolve_project_deps`: No tests for pub get failure scenarios

### 3. Inconsistent Testing Patterns

- Some commands tested in `commands_test.dart` (global approach)
- Others have dedicated test files
- No consistent approach to mocking user input
- Force flag testing is inconsistent

## Recommendations

### 1. Extend Existing TestLogger (KISS)

```dart
/// Extend the existing TestLogger to support all input methods
class TestLogger extends Logger {
  final Map<String, bool> _confirmResponses = {};
  final Map<String, int> _selectResponses = {};
  final Map<String, String> _versionResponses = {};
  
  TestLogger(FvmContext context) : super(context);
  
  void setConfirmResponse(String promptPattern, bool response) {
    _confirmResponses[promptPattern] = response;
  }
  
  void setSelectResponse(String promptPattern, int optionIndex) {
    _selectResponses[promptPattern] = optionIndex;
  }
  
  void setVersionResponse(String promptPattern, String version) {
    _versionResponses[promptPattern] = version;
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
  
  @override
  String select(String? message, {
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
  
  @override
  String cacheVersionSelector(List<CacheFlutterVersion> versions) {
    final prompt = 'Select a version: ';
    outputs.add(prompt);
    for (final entry in _versionResponses.entries) {
      if (prompt.contains(entry.key)) {
        info('User selected version: ${entry.value}');
        return entry.value;
      }
    }
    return super.cacheVersionSelector(versions);
  }
}
```

### 2. Fix Logger Service Test Mode Handling

```dart
// In logger_service.dart, modify the confirm method:
bool confirm(String? message, {required bool defaultValue}) {
  // Remove this line that prevents TestLogger from working:
  // if (_isTest) return defaultValue;
  
  if (_isCI || _skipInput) {
    info(message ?? '');
    warn('Skipping input confirmation');
    warn('Using default value of $defaultValue');
    return defaultValue;
  }
  
  // In test mode, this will use TestLogger's override
  return interact.Confirm(prompt: message ?? '', defaultValue: defaultValue)
      .interact();
}
```

### 3. Simple Test Pattern (YAGNI)

Use the existing test pattern from `update_melos_settings.workflow_test.dart`:

```dart
// Example test for any workflow with confirmation
test('should continue when user confirms', () async {
  final context = TestFactory.context(
    generators: {
      Logger: (context) => TestLogger(context)
        ..setConfirmResponse('prompt text', true),
    },
  );
  
  final workflow = SomeWorkflow(context);
  expect(() => workflow.call(), returnsNormally);
});

test('should throw when user declines', () async {
  final context = TestFactory.context(
    generators: {
      Logger: (context) => TestLogger(context)
        ..setConfirmResponse('prompt text', false),
    },
  );
  
  final workflow = SomeWorkflow(context);
  expect(() => workflow.call(), throwsA(isA<AppException>()));
});
```

### 4. Minimal Implementation Plan

#### Step 1: Fix Core Issue (1 day)
1. Update TestLogger to support `select()` and `cacheVersionSelector()`
2. Fix Logger service test mode handling (remove line 122)

#### Step 2: Test Critical Destructive Operations (2 days)
1. Add test for `destroy_command` confirmation
2. Add test for `remove_command` confirmation

#### Step 3: Test Remaining Workflows (3 days)
1. Copy pattern from `update_melos_settings.workflow_test.dart`
2. Apply to other workflows needing tests

### 5. Simple Testing Guidelines (DRY)

#### Test Only What Matters
For each user input:
1. Test user confirms (Yes path)
2. Test user declines (No path)
3. Test force flag if supported

#### Use Existing Structure
- Keep TestLogger in `test/src/workflows/test_logger.dart`
- Follow existing test file naming conventions
- Copy working patterns from `update_melos_settings.workflow_test.dart`

### 6. What NOT to Do (YAGNI)

#### Avoid Over-Engineering
- ❌ No test templates or abstract base classes
- ❌ No test helpers or builders
- ❌ No code generation
- ❌ No complex interaction logging
- ❌ No occurrence tracking for prompts

#### Keep It Simple
- ✅ Use existing TestFactory pattern
- ✅ Copy working test examples
- ✅ Write straightforward tests

### 7. Focus on What's Needed

#### Immediate Actions
1. Extend TestLogger with missing methods
2. Fix Logger service test bypass
3. Add tests for destructive operations first
4. Use consistent error types (`AppException` for workflow errors, `ForceExit` for user cancellation)

## Conclusion

Only 1 out of 9 components with user input has proper tests. The solution is simple:

1. **Extend TestLogger** - Add `select()` and `cacheVersionSelector()` support
2. **Fix Logger** - Remove test mode bypass (line 122)
3. **Add Tests** - Start with destructive operations (`destroy`, `remove`)
4. **Copy Pattern** - Use existing `update_melos_settings.workflow_test.dart` as template

Estimated effort: 1 week to cover all critical gaps.