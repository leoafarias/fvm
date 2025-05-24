import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:test/test.dart';

import '../testing_utils.dart';

void main() {
  late TestCommandRunner runner;
  late Directory tempDirectory;

  setUp(() {
    tempDirectory = createTempDir('use_command_pin_test');

    // Create a basic Flutter project structure
    createPubspecYaml(tempDirectory, name: 'test_project');

    // Create a test FVM context with the default mock services
    final testContext = TestFactory.context(
      debugLabel: 'use_command_pin_test',
      workingDirectoryOverride: tempDirectory.path,
    );

    runner = TestCommandRunner(testContext);
  });

  tearDown(() {
    if (tempDirectory.existsSync()) {
      tempDirectory.deleteSync(recursive: true);
    }
  });

  group('Use command pin option', () {
    test('allows pinning stable channel', () async {
      // Run the use command with pin option on stable channel
      final result = runner.run([
        'fvm',
        'use',
        'stable',
        '--pin',
        '--force',
        '--skip-setup',
      ]);

      // This should not throw an exception
      await expectLater(result, completes);
    });

    test('allows pinning beta channel', () async {
      // Run the use command with pin option on beta channel
      final result = runner.run([
        'fvm',
        'use',
        'beta',
        '--pin',
        '--force',
        '--skip-setup',
      ]);

      // This should not throw an exception
      await expectLater(result, completes);
    });

    test('allows pinning dev channel', () async {
      // Run the use command with pin option on dev channel
      final result = runner.run([
        'fvm',
        'use',
        'dev',
        '--pin',
        '--force',
        '--skip-setup',
      ]);

      // This should not throw an exception
      await expectLater(result, completes);
    });

    test('rejects pinning master channel', () async {
      // Run the use command with pin option on master channel
      // This should fail as master is not a stable channel for pinning
      final result = runner.runOrThrow([
        'fvm',
        'use',
        'master',
        '--pin',
        '--force',
        '--skip-setup',
      ]);

      // This should throw a UsageException
      await expectLater(result, throwsA(isA<UsageException>()));
    });

    test('rejects pinning main channel', () async {
      // Run the use command with pin option on main channel
      // This should fail as main is not a stable channel for pinning
      final result = runner.runOrThrow([
        'fvm',
        'use',
        'main',
        '--pin',
        '--force',
        '--skip-setup',
      ]);

      // This should throw a UsageException
      await expectLater(result, throwsA(isA<UsageException>()));
    });

    test('rejects pinning a non-channel version', () async {
      // Run the use command with pin option on a version
      final result = runner.runOrThrow([
        'fvm',
        'use',
        '3.10.0',
        '--pin',
        '--force',
        '--skip-setup',
      ]);

      // This should throw a UsageException
      await expectLater(result, throwsA(isA<UsageException>()));
    });
  });
}
