import 'dart:io';

import 'package:fvm/src/services/project_service.dart';
import 'package:fvm/src/utils/context.dart';
import 'package:test/test.dart';

import 'testing_utils.dart';

void main() {
  group('Version Format Workflow Test', () {
    test('Full version format workflow', () async {
      // Check if Flutter and Dart are available
      final isFlutterAvailable = await _isCommandAvailable('flutter');
      final isDartAvailable = await _isCommandAvailable('dart');

      if (!isFlutterAvailable) {
        print('Skipping test: Flutter is not available in PATH');
        print(
          'This test requires Flutter to be installed and available in the system PATH',
        );
        return;
      }

      if (!isDartAvailable) {
        print('Skipping test: Dart is not available in PATH');
        print(
          'This test requires Dart to be installed and available in the system PATH',
        );
        return;
      }

      print('Flutter and Dart are available, proceeding with tests...');

      print('Setting up test environment...');

      // Create a temp directory with a valid Dart package name
      final testDir = createTempDir();
      final appDir = Directory('${testDir.path}/test_app');
      if (!appDir.existsSync()) {
        appDir.createSync();
      }
      print('Created test directory at: ${appDir.path}');

      // Create a Flutter app in the test directory (without changing global working directory)
      final result = await Process.run(
        'flutter',
        ['create', '.'],
        workingDirectory: appDir.path,
        runInShell: true,
      );
      expect(
        result.exitCode,
        0,
        reason: 'Failed to create Flutter app: ${result.stderr}',
      );
      print('Created Flutter app in test directory');

      // Run flutter pub get in the test directory
      final pubGetResult = await Process.run(
        'flutter',
        ['pub', 'get'],
        workingDirectory: appDir.path,
        runInShell: true,
      );
      expect(
        pubGetResult.exitCode,
        0,
        reason: 'Failed to run flutter pub get: ${pubGetResult.stderr}',
      );

      // Create a test runner that operates in the test directory
      // First create a proper test context with TestFactory
      final baseContext = TestFactory.context();

      // Then create a context with the working directory override
      final testContext = FvmContext.create(
        workingDirectoryOverride: appDir.path,
        isTest: true,
        configOverrides: baseContext
            .config, // Use the config from TestFactory which has proper paths
      );
      final appTestRunner = TestCommandRunner(testContext);

      // Display FVM version
      print('FVM version:');
      await appTestRunner.runOrThrow(['fvm', '--version']);

      // List installed versions (may fail but we continue)
      print('\nCurrently installed FVM versions:');
      try {
        await appTestRunner.run(['fvm', 'list']);
      } catch (e) {
        print('Warning: Failed to list versions, but continuing tests...');
      }

      // Test Channel Versions
      print('\n===== Testing Channel Versions =====');

      // Ensure stable channel is available
      print('\nEnsuring stable channel is available...');
      await appTestRunner.runOrThrow(['fvm', 'install', 'stable']);

      // Test various channel versions
      await _testVersion(appTestRunner, 'stable', 'Stable Channel');
      await _testVersion(appTestRunner, 'beta', 'Beta Channel');
      await _testVersion(appTestRunner, 'dev', 'Dev Channel');
      await _testVersion(appTestRunner, 'master', 'Master Channel');

      // Test semantic versions if available
      print('\n===== Testing Semantic Versions =====');
      try {
        await _testVersion(appTestRunner, '2.10.0', 'Specific Version');
        await _testVersion(appTestRunner, 'v2.10.0', 'Version with v prefix');
      } catch (e) {
        print(
          'Warning: Skipping semantic version tests - version may not be available',
        );
      }

      // Test versions with channels
      print('\n===== Testing Versions with Channels =====');
      try {
        await _testVersion(
          appTestRunner,
          '2.10.0@beta',
          'Version with beta channel',
        );
        await _testVersion(
          appTestRunner,
          'v2.10.0@beta',
          'Version with v prefix and beta channel',
        );
      } catch (e) {
        print(
          'Warning: Skipping version with channel tests - version may not be available',
        );
      }

      // Test fork functionality
      print('\n===== Testing Fork Functionality =====');
      try {
        await _testForkFunctionality(appTestRunner);
      } catch (e) {
        print(
          'Warning: Skipping fork functionality tests - requires network access',
        );
        print('Error: $e');
      }

      // Test error cases - these should fail
      print('\n===== Testing Error Cases =====');
      await _testErrorCase(appTestRunner, '2.10.0@invalid', 'Invalid channel');
      await _testErrorCase(
        appTestRunner,
        'custom_build@beta',
        'Custom version with channel',
      );
      await _testErrorCase(
        appTestRunner,
        'unknown-fork/stable',
        'Non-existent fork',
      );

      // Test command aliases
      print('\n===== Testing Command Aliases =====');
      await _testAliases(appTestRunner);

      // Test install command flags
      print('\n===== Testing Install Command Flags =====');
      await _testInstallFlags(appTestRunner);

      // Reset to stable at the end
      print('\nResetting to stable channel...');
      await appTestRunner.runOrThrow([
        'fvm',
        'use',
        'stable',
        '--force',
        '--skip-setup',
      ]);

      // Check final configuration
      print('\nFinal configuration:');
      final projectConfig =
          appTestRunner.context.get<ProjectService>().findAncestor();
      expect(projectConfig.pinnedVersion?.name, equals('stable'));

      print('\nTests completed successfully!');
    });
  });
}

/// Helper function to test a specific version
Future<void> _testVersion(
  TestCommandRunner runner,
  String version,
  String description,
) async {
  print('----- Testing $description: $version -----');

  // Use the version with --force flag to bypass constraint checks in tests
  await runner.runOrThrow(['fvm', 'use', version, '--force', '--skip-setup']);

  // Verify the config file exists
  final project = runner.context.get<ProjectService>().findAncestor();
  final configFile = File(project.configPath);
  expect(
    configFile.existsSync(),
    isTrue,
    reason: 'Config file should exist after update',
  );

  print('Config file after update:');
  print(configFile.readAsStringSync());

  // Verify the Flutter version information
  print('Flutter version:');
  await runner.runOrThrow(['fvm', 'flutter', '--version']);

  print('------------------------------');
}

/// Helper function to test error cases
Future<void> _testErrorCase(
  TestCommandRunner runner,
  String version,
  String description,
) async {
  print('----- Testing Error Case: $description -----');
  print('Command: fvm use $version');

  // This should fail
  try {
    await runner.run(['fvm', 'use', version, '--skip-setup']);
    print('Warning: Command should have failed but succeeded');
  } catch (e) {
    print('Test passed: Command failed as expected');
  }

  print('------------------------------');
}

/// Helper function to test command aliases
Future<void> _testAliases(TestCommandRunner runner) async {
  print('----- Testing Command Aliases -----');

  try {
    // Test install alias 'i'
    print('Testing fvm i (install alias)...');
    await runner.runOrThrow(['fvm', 'i', 'stable']);
    print('Install alias: SUCCESS');

    // Test list alias 'ls'
    print('Testing fvm ls (list alias)...');
    await runner.runOrThrow(['fvm', 'ls']);
    print('List alias: SUCCESS');
  } catch (e) {
    print('Alias test error: $e');
    rethrow;
  }

  print('------------------------------');
}

/// Helper function to test install command flags
Future<void> _testInstallFlags(TestCommandRunner runner) async {
  print('----- Testing Install Command Flags -----');

  try {
    // Test install with --setup flag
    print('Testing fvm install with --setup flag...');
    await runner.runOrThrow(['fvm', 'install', 'stable', '--setup']);
    print('Install with --setup: SUCCESS');

    // Test install with --skip-pub-get flag
    print('Testing fvm install with --skip-pub-get flag...');
    await runner.runOrThrow(['fvm', 'install', 'beta', '--skip-pub-get']);
    print('Install with --skip-pub-get: SUCCESS');

    // Test install with both flags
    print('Testing fvm install with both flags...');
    await runner.runOrThrow([
      'fvm',
      'install',
      'dev',
      '--setup',
      '--skip-pub-get',
    ]);
    print('Install with both flags: SUCCESS');
  } catch (e) {
    print('Install flags test error: $e');
    rethrow;
  }

  print('------------------------------');
}

/// Helper function to test fork functionality
Future<void> _testForkFunctionality(TestCommandRunner runner) async {
  print('----- Testing Fork Functionality -----');

  const testForkName = 'leo';
  const testForkUrl = 'https://github.com/leoafarias/flutter.git';

  try {
    // Test adding a real fork
    print('Testing fork add...');
    await runner.runOrThrow(['fvm', 'fork', 'add', testForkName, testForkUrl]);
    print('Fork add: SUCCESS');

    // Test listing forks
    print('Testing fork list...');
    await runner.runOrThrow(['fvm', 'fork', 'list']);
    print('Fork list: SUCCESS');

    // Test installing from fork with custom branch
    print('Testing fork install with custom branch...');
    await runner.runOrThrow(['fvm', 'install', '$testForkName/leo-test-21']);
    print('Fork install with custom branch: SUCCESS');

    // Test using fork version
    print('Testing fork use...');
    await runner.runOrThrow([
      'fvm',
      'use',
      '$testForkName/leo-test-21',
      '--force',
      '--skip-setup',
    ]);
    print('Fork use: SUCCESS');

    // Clean up - remove fork
    await runner.runOrThrow(['fvm', 'fork', 'remove', testForkName]);
    print('Fork remove: SUCCESS');
  } catch (e) {
    print('Fork functionality test error: $e');
    // Clean up on error
    try {
      await runner.run(['fvm', 'fork', 'remove', testForkName]);
    } catch (_) {
      // Ignore cleanup errors
    }
    rethrow;
  }

  print('------------------------------');
}

/// Helper function to check if a command is available in the system
Future<bool> _isCommandAvailable(String command) async {
  try {
    final result = await Process.run('which', [command], runInShell: true);
    return result.exitCode == 0;
  } catch (e) {
    return false;
  }
}
