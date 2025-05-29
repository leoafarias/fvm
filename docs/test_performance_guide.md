# FVM Test Performance Guide

This guide provides tools and strategies for monitoring and optimizing test performance in the FVM project.

## Quick Performance Analysis

### Running Performance Analysis

```bash
# Run tests with timing information
dart test --reporter=expanded

# Run specific test files for focused analysis
dart test test/src/api/api_service_test.dart --reporter=expanded

# Run tests with JSON output for parsing
dart test --reporter=json
```

### Current Performance Baseline

Based on the latest analysis:

- **Total test execution time**: ~31 seconds (unit tests only)
- **Total tests**: 102 unit tests
- **Average time per test**: 303ms
- **Slowest test suite**: `test/src/api/` (2.4s average per test)

## Performance Hotspots

### Critical Issues (Immediate Attention Required)

1. **API Service Tests** (`test/src/api/`)
   - `getCachedVersions` tests taking 11.2s and 7.9s
   - **Root cause**: Actual file system operations and directory scanning
   - **Solution**: Mock file system operations

2. **File Lock Tests** (`test/src/utils/file_lock_test.dart`)
   - Near-simultaneous lock test taking 942ms
   - **Root cause**: Actual file locking with timing dependencies
   - **Solution**: Use fake timers or reduce test complexity

3. **Flutter Releases Tests** (`test/utils/releases_test.dart`)
   - Tests taking 260ms+ due to network/API calls
   - **Root cause**: Real API interactions
   - **Solution**: Mock HTTP responses

### Optimization Strategies

#### 1. Mock External Dependencies

```dart
// Instead of real file operations
final mockFileSystem = MockFileSystem();
when(() => mockFileSystem.directory(any())).thenReturn(mockDirectory);

// Instead of real HTTP calls
final mockClient = MockClient();
when(() => mockClient.get(any())).thenAnswer((_) async => Response('{}', 200));
```

#### 2. Use Test Fixtures

```dart
// Create shared test data
class TestFixtures {
  static const mockFlutterVersions = [
    {'version': '3.10.0', 'channel': 'stable'},
    {'version': '3.11.0', 'channel': 'beta'},
  ];
}
```

#### 3. Optimize Setup/Teardown

```dart
// Use setUpAll for expensive operations
setUpAll(() async {
  // One-time setup for all tests in the group
  await initializeTestEnvironment();
});

// Use setUp only for test-specific setup
setUp(() {
  // Quick per-test setup
  resetMocks();
});
```

## Monitoring Test Performance

### CI/CD Integration

Add performance monitoring to your CI pipeline:

```yaml
# .github/workflows/test.yml
- name: Run Performance Analysis
  run: |
    dart test --reporter=json > test_performance.json
    # Parse JSON output for performance metrics
```

### Performance Regression Detection

```bash
# Run tests with timing and parse output
dart test --reporter=json > current_performance.json

# Use standard Dart test tools for performance monitoring
dart test --reporter=expanded | grep -E "^\s*\d+:\d+\s+\+\d+"
```

### Tracking Performance Over Time

1. **Store performance data**: Save JSON output from each CI run
2. **Create dashboards**: Use tools like Grafana to visualize trends
3. **Set alerts**: Monitor for performance regressions
4. **Regular reviews**: Weekly performance review meetings

## Test Categories by Performance

### Fast Tests (< 100ms)
- Unit tests for models and utilities
- Pure logic tests without I/O
- Mock-based service tests

### Medium Tests (100ms - 500ms)
- Service integration tests with mocked dependencies
- Command tests with mocked file system
- Workflow tests with mocked external calls

### Slow Tests (> 500ms)
- Integration tests with real file operations
- Tests involving actual Flutter SDK operations
- End-to-end workflow tests

## Performance Optimization Checklist

### Before Writing Tests

- [ ] Can this be tested with mocks instead of real dependencies?
- [ ] Is the test focused on a single responsibility?
- [ ] Can expensive setup be shared across multiple tests?

### During Test Development

- [ ] Use `setUp`/`tearDown` efficiently
- [ ] Mock file system operations
- [ ] Mock network calls
- [ ] Avoid unnecessary async operations

### After Writing Tests

- [ ] Run performance analysis
- [ ] Check if test duration is reasonable
- [ ] Consider splitting complex tests
- [ ] Add to appropriate test category

## Tools and Commands

### Dart Test Performance Flags

```bash
# Run tests with timing information
dart test --reporter=expanded

# Run specific test files
dart test test/src/api/api_service_test.dart

# Run tests with coverage (slower)
dart test --coverage=coverage

# Run tests in parallel (faster)
dart test --concurrency=8
```

### Built-in Dart Test Tools

Use Dart's built-in test tools for performance analysis:

- `dart test --reporter=expanded`: Shows detailed timing for each test
- `dart test --reporter=json`: Provides machine-readable output for parsing
- `dart test --concurrency=N`: Controls parallel execution for performance testing

### Performance Thresholds

| Test Type | Threshold | Action |
|-----------|-----------|---------|
| Unit Test | 100ms | Investigate |
| Integration Test | 500ms | Review |
| Workflow Test | 2s | Optimize |
| Any Test | 5s | Critical Issue |

## Best Practices

### Do's
- ✅ Mock external dependencies
- ✅ Use shared test fixtures
- ✅ Focus tests on single responsibilities
- ✅ Monitor performance regularly
- ✅ Set performance budgets

### Don'ts
- ❌ Perform real file I/O in unit tests
- ❌ Make real network calls in tests
- ❌ Create large temporary files
- ❌ Use `sleep()` or `Future.delayed()` unnecessarily
- ❌ Ignore performance regressions

## Troubleshooting Slow Tests

### Identifying Root Causes

1. **Profile individual tests**:
   ```bash
   dart test --reporter=json test/slow_test.dart | grep -E '"time":|"name":'
   ```

2. **Check for I/O operations**:
   - File system access
   - Network calls
   - Process spawning

3. **Look for timing dependencies**:
   - `Future.delayed()`
   - `sleep()`
   - Polling loops

### Common Solutions

1. **Replace real I/O with mocks**
2. **Use fake timers for time-dependent tests**
3. **Reduce test data size**
4. **Parallelize independent tests**
5. **Cache expensive setup operations**

## Future Improvements

### Planned Optimizations

1. **Test parallelization**: Run independent test suites in parallel
2. **Shared test environment**: Reuse Flutter SDK setup across tests
3. **Performance budgets**: Automatic CI failure for slow tests
4. **Test categorization**: Separate fast/slow test suites

### Monitoring Enhancements

1. **Performance dashboards**: Real-time performance tracking
2. **Regression alerts**: Automatic notifications for slowdowns
3. **Historical analysis**: Trend analysis over time
4. **Benchmark comparisons**: Compare against other similar projects
