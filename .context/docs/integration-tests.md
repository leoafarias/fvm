# FVM Integration Test Suite

This directory contains end-to-end integration tests for FVM that validate real-world usage scenarios with actual Git operations and Flutter SDK installations.

## Overview

The integration test suite is designed to complement the existing fast unit tests by providing thorough validation of FVM's core workflows using real operations rather than mocks.

## Test Structure

### Main Integration Test Command
- **`fvm integration-test`** - Comprehensive Dart command with 38 integration tests covering all major FVM workflows

### Dart Integration Test Framework
- **`integration_test_utils.dart`** - Utilities for creating isolated test environments
- **`installation_workflow_test.dart`** - Dart-based installation workflow tests
- **`project_lifecycle_test.dart`** - Project lifecycle and configuration tests

## Test Coverage

### Phase 1: Basic Command Interface (4 tests)
- Help command functionality
- Version display
- Releases API access
- List command operation

### Phase 2: Installation Workflows (5 tests)
- Channel installation (stable, beta, dev)
- Release version installation
- Git commit installation
- Installation with setup flag
- Project-based installation from .fvmrc

### Phase 3: Project Lifecycle (8 tests)
- Complete `fvm use` workflow
- .fvmrc file generation and validation
- .fvm directory structure creation
- Symlink creation (when privileged access available)
- Flavor configuration and switching
- VS Code settings integration
- .gitignore integration
- Force flag handling

### Phase 4: Version Management (3 tests)
- Global version setting and verification
- Version removal and cache cleanup
- Doctor command diagnostics

### Phase 5: Advanced Commands (5 tests)
- Flutter proxy command (`fvm flutter`)
- Dart proxy command (`fvm dart`)
- Spawn command (`fvm spawn`)
- Exec command (`fvm exec`)
- Flavor command (`fvm flavor`)

### Phase 6: API Commands (4 tests)
- API list endpoint
- API releases endpoint with filtering
- API project endpoint
- API context endpoint

### Phase 7: Fork Management (3 tests)
- Fork addition and registration
- Fork listing and verification
- Fork removal and cleanup

### Phase 8: Configuration Management (2 tests)
- Configuration display and validation
- Configuration setting modification and persistence

### Phase 9: Error Handling (3 tests)
- Invalid version handling
- Invalid command handling
- Corrupted cache recovery

### Phase 10: Cleanup Operations (2 tests)
- Selective version removal
- Destroy command with cache backup/restore

### Phase 11: Final Validation (2 tests)
- System state validation after all tests
- Concurrent operation safety

## Real-World Operations Tested

### Actual Git Operations
- Real Git clones from Flutter repository
- Branch and tag checkout operations
- Git commit hash resolution
- Fork repository management

### File System Changes
- Symlink creation and validation
- .fvmrc configuration file generation
- .fvm directory structure creation
- .gitignore modification
- VS Code settings.json updates

### Flutter SDK Management
- Complete Flutter SDK installations
- SDK setup and dependency downloads
- Version switching and validation
- Cache integrity verification

### Configuration Persistence
- Project configuration management
- Global settings persistence
- Flavor configuration handling
- Cross-session state preservation

## Running the Tests

### Comprehensive Integration Test Suite
```bash
# Run all 38 integration tests
fvm integration-test

# Run in fast mode (skip heavy operations)
fvm integration-test --fast

# Run specific test phase (1-11)
fvm integration-test --phase 3

# Run specific test by number (1-38)
fvm integration-test --test 15

# List all available test phases
fvm integration-test --list-phases

# Run cleanup only
fvm integration-test --cleanup-only
```

### Dart Integration Tests
```bash
# Run Dart-based integration tests
dart test test/integration/
```

## Test Environment

### Isolation
- Each test runs in a clean, temporary environment
- Separate cache directories for test isolation
- Project-specific temporary directories
- Automatic cleanup after test completion

### Requirements
- Real network access for Git operations
- Sufficient disk space for Flutter SDK downloads
- Privileged access for symlink creation (optional)
- Git installed and configured

### Performance Expectations
- **Duration**: 10-30 minutes depending on network speed
- **Disk Usage**: 2-5 GB for Flutter SDK downloads
- **Network**: Significant bandwidth usage for Git clones

## Error Handling

### Graceful Failures
- Network timeout handling
- Invalid version validation
- Corrupted cache recovery
- Permission error management

### Safety Measures
- Cache backup before destructive operations
- Automatic cleanup on test failure
- Isolated test environments
- Non-interference with existing FVM installations

## Maintenance

### Updating Test Versions
Update the test configuration constants in `lib/src/commands/integration_test_command.dart`:
```dart
static const testChannel = 'stable';
static const testRelease = '3.19.0';
static const testCommit = 'fb57da5f94';
```

### Adding New Tests
1. Add new test phases to the IntegrationTestRunner class
2. Follow the existing pattern with `_logTest` and `_logSuccess`
3. Ensure proper cleanup and error handling
4. Update the test summary section and phase mapping

### Debugging Failed Tests
- Check individual test output for specific failures
- Verify network connectivity for Git operations
- Ensure sufficient disk space for SDK downloads
- Check permissions for symlink creation

## Integration with CI/CD

### GitHub Actions
The integration tests can be run in CI environments with:
- Ubuntu/macOS runners
- Sufficient timeout (30+ minutes)
- Network access for Git operations
- Adequate disk space allocation

### Local Development
- Run before major releases
- Use for regression testing
- Validate new feature implementations
- Test cross-platform compatibility

## Contributing

When adding new integration tests:
1. Follow the existing test structure and naming conventions
2. Ensure proper environment isolation and cleanup
3. Add comprehensive validation of real file system changes
4. Include both success and failure scenarios
5. Update this README with new test descriptions
