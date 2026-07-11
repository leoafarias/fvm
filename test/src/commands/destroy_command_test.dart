import 'dart:io';

import 'package:fvm/src/services/logger_service.dart';
import 'package:test/test.dart';

import '../../testing_utils.dart';
import '../workflows/test_logger.dart';

void main() {
  group('DestroyCommand', () {
    test('deletes only cached SDK versions when user confirms', () async {
      // Create context with TestLogger that says Yes
      final context = TestFactory.context(
        generators: {
          Logger: (context) => TestLogger(context)
            ..setConfirmResponse(
                'delete all cached Flutter SDK versions', true),
        },
        skipInput: false, // Allow user input for testing
      );

      final customRunner = TestCommandRunner(context);
      expect(
        customRunner.commands['destroy']?.description,
        'Removes all cached Flutter SDK versions',
      );

      // Create an SDK plus a Git-cache marker outside the versions directory.
      final versionsDir = Directory(context.versionsCachePath);
      final testFile = File('${versionsDir.path}/test_version/flutter');
      final gitCacheMarker = File('${context.gitCachePath}/marker');
      testFile.createSync(recursive: true);
      gitCacheMarker.createSync(recursive: true);
      final globalLink = Link(context.globalCacheLink)
        ..createSync(testFile.parent.path, recursive: true);
      expect(versionsDir.existsSync(), isTrue);

      await runnerZoned(customRunner, ['fvm', 'destroy']);

      expect(versionsDir.existsSync(), isFalse);
      expect(gitCacheMarker.existsSync(), isTrue);
      expect(globalLink.existsSync(), isFalse);

      // Verify the confirmation prompt was shown
      final logger = customRunner.context.get<Logger>();
      expect(
        logger.outputs.any(
          (msg) => msg.contains('delete all cached Flutter SDK versions'),
        ),
        isTrue,
      );
      expect(
        logger.outputs.any((msg) => msg.contains('User response: Yes')),
        isTrue,
      );
    });

    test('should not delete cache directory when user declines', () async {
      // Create context with TestLogger that says No
      final context = TestFactory.context(
        generators: {
          Logger: (context) => TestLogger(context)
            ..setConfirmResponse(
                'delete all cached Flutter SDK versions', false),
        },
        skipInput: false, // Allow user input for testing
      );

      final customRunner = TestCommandRunner(context);

      // Create some test content in cache directory
      final cacheDir = Directory(context.versionsCachePath);
      final testFile = File('${cacheDir.path}/test_version/flutter');
      testFile.createSync(recursive: true);
      expect(cacheDir.existsSync(), isTrue);

      await runnerZoned(customRunner, ['fvm', 'destroy']);

      expect(cacheDir.existsSync(), isTrue);
      expect(testFile.existsSync(), isTrue);

      // Verify the confirmation prompt was shown
      final logger = customRunner.context.get<Logger>();
      expect(
        logger.outputs.any(
          (msg) => msg.contains('delete all cached Flutter SDK versions'),
        ),
        isTrue,
      );
      expect(
        logger.outputs.any((msg) => msg.contains('User response: No')),
        isTrue,
      );
      // Should not see success message
      expect(
        logger.outputs.any((msg) => msg.contains('have been deleted')),
        isFalse,
      );
    });

    test(
      'should delete cache directory with force flag without confirmation',
      () async {
        // Create context with normal logger (no TestLogger needed for force)
        final context = TestFactory.context();

        final customRunner = TestCommandRunner(context);

        // Create some test content in cache directory
        final cacheDir = Directory(context.versionsCachePath);
        final testFile = File('${cacheDir.path}/test_version/flutter');
        testFile.createSync(recursive: true);
        expect(cacheDir.existsSync(), isTrue);

        await runnerZoned(customRunner, ['fvm', 'destroy', '--force']);

        expect(cacheDir.existsSync(), isFalse);

        // Verify success message was shown but no confirmation prompt
        final logger = customRunner.context.get<Logger>();
        expect(
          logger.outputs.any((msg) => msg.contains('have been deleted')),
          isTrue,
        );
        // Should not see confirmation prompt (since force was used)
        expect(
          logger.outputs.any(
            (msg) => msg.contains('delete all cached Flutter SDK versions'),
          ),
          isFalse,
        );
      },
    );

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
        final testFile = File('${cacheDir.path}/test_version/flutter');
        testFile.createSync(recursive: true);
        expect(cacheDir.existsSync(), isTrue);

        await runnerZoned(customRunner, ['fvm', 'destroy']);

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
