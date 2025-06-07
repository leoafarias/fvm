
import 'package:fvm/src/models/config_model.dart';
import 'package:fvm/src/services/logger_service.dart';
import 'package:fvm/src/services/project_service.dart';
import 'package:fvm/src/utils/exceptions.dart';
import 'package:fvm/src/workflows/verify_project.workflow.dart';
import 'package:test/test.dart';

import '../../testing_utils.dart';
import 'test_logger.dart';

void main() {
  group('VerifyProjectWorkflow', () {
    late TestCommandRunner runner;
    late TempDirectoryTracker tempDirs;

    setUp(() {
      runner = TestFactory.commandRunner();
      tempDirs = TempDirectoryTracker();
    });

    tearDown(() {
      tempDirs.cleanUp();
    });

    test('should pass when project has pubspec', () {
      final testDir = tempDirs.create();
      createPubspecYaml(testDir);
      createProjectConfig(
        ProjectConfig(flutter: '3.10.0'),
        testDir,
      );

      final project =
          runner.context.get<ProjectService>().findAncestor(directory: testDir);
      final workflow = VerifyProjectWorkflow(runner.context);

      // Should not throw
      expect(() => workflow(project, force: false), returnsNormally);
    });

    test('should pass with force flag even without pubspec', () {
      final testDir = tempDirs.create();
      // No pubspec created

      final project =
          runner.context.get<ProjectService>().findAncestor(directory: testDir);
      final workflow = VerifyProjectWorkflow(runner.context);

      // Should not throw with force
      expect(() => workflow(project, force: true), returnsNormally);
    });

    group('user confirmation', () {
      test('should continue when user confirms', () {
        final testDir = tempDirs.create();
        // No pubspec - will trigger confirmation

        // Create context with TestLogger that says Yes
        final context = TestFactory.context(
          generators: {
            Logger: (context) => TestLogger(context)
              ..setConfirmResponse('Would you like to continue?', true),
          },
          skipInput: false, // Allow user input for testing
        );

        final customRunner = TestCommandRunner(context);
        final project = customRunner.context
            .get<ProjectService>()
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
        expect(
          logger.outputs
              .any((msg) => msg.contains('Would you like to continue?')),
          isTrue,
        );
        expect(
          logger.outputs.any((msg) => msg.contains('User response: Yes')),
          isTrue,
        );
      });

      test('should throw ForceExit when user declines', () {
        final testDir = tempDirs.create();
        // No pubspec - will trigger confirmation

        // Create context with TestLogger that says No
        final context = TestFactory.context(
          generators: {
            Logger: (context) => TestLogger(context)
              ..setConfirmResponse('Would you like to continue?', false),
          },
          skipInput: false, // Allow user input for testing
        );

        final customRunner = TestCommandRunner(context);
        final project = customRunner.context
            .get<ProjectService>()
            .findAncestor(directory: testDir);
        final workflow = VerifyProjectWorkflow(customRunner.context);

        // Should throw when user declines
        expect(
          () => workflow(project, force: false),
          throwsA(isA<ForceExit>().having((e) => e.message, 'message',
              contains('Project verification failed'))),
        );

        // Verify the prompt was shown
        final logger = customRunner.context.get<Logger>();
        expect(
          logger.outputs.any((msg) => msg.contains('No pubspec.yaml detected')),
          isTrue,
        );
        expect(
          logger.outputs
              .any((msg) => msg.contains('Would you like to continue?')),
          isTrue,
        );
        expect(
          logger.outputs.any((msg) => msg.contains('User response: No')),
          isTrue,
        );
      });

      test(
          'should use correct default value (true) for non-destructive operation',
          () {
        final testDir = tempDirs.create();
        // No pubspec - will trigger confirmation

        // Create context that skips input (will use default value)
        final context = TestFactory.context(
          skipInput:
              true, // This will cause confirm to return defaultValue (true)
        );

        final customRunner = TestCommandRunner(context);
        final project = customRunner.context
            .get<ProjectService>()
            .findAncestor(directory: testDir);
        final workflow = VerifyProjectWorkflow(customRunner.context);

        // Should not throw with default behavior (returns true when skipInput is true)
        expect(() => workflow(project, force: false), returnsNormally);

        // Verify the detection message was shown
        final logger = customRunner.context.get<Logger>();
        expect(
          logger.outputs.any((msg) => msg.contains('No pubspec.yaml detected')),
          isTrue,
        );
        expect(
          logger.outputs
              .any((msg) => msg.contains('Skipping input confirmation')),
          isTrue,
        );
      });
    });
  });
}
