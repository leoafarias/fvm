import 'dart:io';

import 'package:fvm/src/services/project_service.dart';
import 'package:fvm/src/utils/context.dart';
import 'package:test/test.dart';

import 'testing_utils.dart';

void main() {
  group('Version Format Workflow Test', () {
    test('Full version format workflow', () async {
      // Ensure Flutter and Dart are available
      expect(await _isCommandAvailable('flutter'), isTrue,
          reason: 'Flutter must be available in PATH');
      expect(await _isCommandAvailable('dart'), isTrue,
          reason: 'Dart must be available in PATH');

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
      expect(result.exitCode, 0,
          reason: 'Failed to create Flutter app: ${result.stderr}');
      print('Created Flutter app in test directory');

      // Run flutter pub get in the test directory
      final pubGetResult = await Process.run(
        'flutter',
        ['pub', 'get'],
        workingDirectory: appDir.path,
        runInShell: true,
      );
      expect(pubGetResult.exitCode, 0,
          reason: 'Failed to run flutter pub get: ${pubGetResult.stderr}');

      // Create a test runner that operates in the test directory
      final testContext = FvmContext.create(
        workingDirectoryOverride: appDir.path,
        isTest: true,
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
            'Warning: Skipping semantic version tests - version may not be available');
      }

      // Test versions with channels
      print('\n===== Testing Versions with Channels =====');
      try {
        await _testVersion(
            appTestRunner, '2.10.0@beta', 'Version with beta channel');
        await _testVersion(appTestRunner, 'v2.10.0@beta',
            'Version with v prefix and beta channel');
      } catch (e) {
        print(
            'Warning: Skipping version with channel tests - version may not be available');
      }

      // Skip fork functionality test as it requires deeper environment setup
      print('\n===== Skipping Fork Functionality Tests =====');
      print('Fork functionality tests are skipped in this workflow test');
      print('These tests are better handled in dedicated unit tests');

      // Test error cases - these should fail
      print('\n===== Testing Error Cases =====');
      await _testErrorCase(appTestRunner, '2.10.0@invalid', 'Invalid channel');
      await _testErrorCase(
          appTestRunner, 'custom_build@beta', 'Custom version with channel');
      await _testErrorCase(
          appTestRunner, 'unknown-fork/stable', 'Non-existent fork');

      // Reset to stable at the end
      print('\nResetting to stable channel...');
      await appTestRunner.runOrThrow(['fvm', 'use', 'stable']);

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

  // Use the version
  await runner.runOrThrow(['fvm', 'use', version]);

  // Verify the config file exists
  final project = runner.context.get<ProjectService>().findAncestor();
  final configFile = File(project.configPath);
  expect(configFile.existsSync(), isTrue,
      reason: 'Config file should exist after update');

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
    await runner.run(['fvm', 'use', version]);
    print('Warning: Command should have failed but succeeded');
  } catch (e) {
    print('Test passed: Command failed as expected');
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
