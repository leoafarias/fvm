import 'dart:io';

import 'package:fvm/src/services/logger_service.dart';
import 'package:test/test.dart';

import '../../testing_utils.dart';
import '../workflows/test_logger.dart';

void main() {
  group('RemoveCommand', () {
    test(
      'should remove all versions when user confirms with --all flag',
      () async {
        // Create context with TestLogger that says Yes
        final context = TestFactory.context(
          generators: {
            Logger: (context) => TestLogger(context)
              ..setConfirmResponse('remove all versions', true),
          },
          skipInput: false, // Allow user input for testing
        );

        final customRunner = TestCommandRunner(context);

        // Create some test content in cache directory
        final cacheDir = Directory(context.versionsCachePath);
        final version1Dir = Directory('${cacheDir.path}/3.10.0');
        final version2Dir = Directory('${cacheDir.path}/3.11.0');
        version1Dir.createSync(recursive: true);
        version2Dir.createSync(recursive: true);
        expect(cacheDir.existsSync(), isTrue);

        await runnerZoned(customRunner, ['fvm', 'remove', '--all']);

        expect(cacheDir.existsSync(), isFalse);

        // Verify the confirmation prompt was shown
        final logger = customRunner.context.get<Logger>();
        expect(
          logger.outputs.any(
            (msg) =>
                msg.contains('Are you sure you want to remove all versions'),
          ),
          isTrue,
        );
        expect(
          logger.outputs.any((msg) => msg.contains('User response: Yes')),
          isTrue,
        );
      },
    );

    test(
      'should not remove versions when user declines with --all flag',
      () async {
        // Create context with TestLogger that says No
        final context = TestFactory.context(
          generators: {
            Logger: (context) => TestLogger(context)
              ..setConfirmResponse('remove all versions', false),
          },
          skipInput: false, // Allow user input for testing
        );

        final customRunner = TestCommandRunner(context);

        // Create some test content in cache directory
        final cacheDir = Directory(context.versionsCachePath);
        final version1Dir = Directory('${cacheDir.path}/3.10.0');
        final version2Dir = Directory('${cacheDir.path}/3.11.0');
        version1Dir.createSync(recursive: true);
        version2Dir.createSync(recursive: true);
        expect(cacheDir.existsSync(), isTrue);

        await runnerZoned(customRunner, ['fvm', 'remove', '--all']);

        expect(cacheDir.existsSync(), isTrue);
        expect(version1Dir.existsSync(), isTrue);
        expect(version2Dir.existsSync(), isTrue);

        // Verify the confirmation prompt was shown
        final logger = customRunner.context.get<Logger>();
        expect(
          logger.outputs.any(
            (msg) =>
                msg.contains('Are you sure you want to remove all versions'),
          ),
          isTrue,
        );
        expect(
          logger.outputs.any((msg) => msg.contains('User response: No')),
          isTrue,
        );
        // Should not see success message
        expect(
          logger.outputs.any((msg) => msg.contains('has been deleted')),
          isFalse,
        );
      },
    );

    test('should handle non-existent version gracefully', () async {
      final context = TestFactory.context();
      final customRunner = TestCommandRunner(context);

      await runnerZoned(customRunner, ['fvm', 'remove', '3.99.0']);

      // Verify appropriate message was shown
      final logger = customRunner.context.get<Logger>();
      expect(
        logger.outputs.any((msg) => msg.contains('3.99.0 is not installed')),
        isTrue,
      );
    });

    test(
      'should use correct default value (false) for destructive operation',
      () async {
        // This test verifies that the default value is false (safe for destructive operations)
        final context = TestFactory.context(
          skipInput: true, // This will use default value (false)
        );

        final customRunner = TestCommandRunner(context);

        // Create some test content in cache directory
        final cacheDir = Directory(context.versionsCachePath);
        final version1Dir = Directory('${cacheDir.path}/3.10.0');
        version1Dir.createSync(recursive: true);
        expect(cacheDir.existsSync(), isTrue);

        await runnerZoned(customRunner, ['fvm', 'remove', '--all']);

        expect(cacheDir.existsSync(), isTrue); // Should not be deleted

        // Verify the confirmation was skipped with default value
        final logger = customRunner.context.get<Logger>();
        expect(
          logger.outputs.any(
            (msg) => msg.contains('Skipping input confirmation'),
          ),
          isTrue,
        );
        expect(
          logger.outputs.any(
            (msg) => msg.contains('Using default value of false'),
          ),
          isTrue,
        );
      },
    );
  });
}
