import 'package:fvm/fvm.dart';
import 'package:fvm/src/services/logger_service.dart';
import 'package:test/test.dart';

void main() {
  late Logger logger;

  setUp(() {
    final context = FvmContext.create(
      logLevel: Level.info,
      isTest: true,
      skipInput: true,
    );
    logger = Logger(context);
  });
  group('Logger output tests', () {
    test('info adds message to outputs', () {
      logger.info("Test info message");
      expect(logger.outputs.contains("Test info message"), isTrue);
    });

    test('success logs with success icon', () {
      logger.success("Operation successful");
      final output = logger.outputs.join(' ');
      expect(output.contains('✓'), isTrue);
      expect(output.contains("Operation successful"), isTrue);
    });

    test('fail logs with failure icon', () {
      logger.fail("Operation failed");
      final output = logger.outputs.join(' ');
      expect(output.contains('✗'), isTrue);
      expect(output.contains("Operation failed"), isTrue);
    });

    test('warn adds message to outputs', () {
      logger.warn("Warning message");
      expect(logger.outputs.contains("Warning message"), isTrue);
    });

    test('err adds message to outputs', () {
      logger.err("Error message");
      expect(logger.outputs.contains("Error message"), isTrue);
    });

    test('detail adds message to outputs', () {
      logger.debug("Detail message");
      expect(logger.outputs.contains("Detail message"), isTrue);
    });

    test('write adds message to outputs', () {
      logger.write("Write message");
      expect(logger.outputs.contains("Write message"), isTrue);
    });

    test('confirm with skipInput true logs messages and returns default', () {
      final context = FvmContext.create(
        logLevel: Level.info,
        isTest: false, // isTest is false so that the skipInput branch is used
        skipInput: true,
      );
      final logger = Logger(context);

      final result = logger.confirm("Confirm prompt", defaultValue: false);
      expect(result, isFalse);
      // Verify that the confirmation prompt and warnings were added to outputs.
      expect(
          logger.outputs.any((msg) => msg.contains("Confirm prompt")), isTrue);
      expect(
          logger.outputs
              .any((msg) => msg.contains("Skipping input confirmation")),
          isTrue);
      expect(
          logger.outputs
              .any((msg) => msg.contains("Using default value of false")),
          isTrue);
    });

    test('select with skipInput true returns default selection when provided',
        () {
      final context = FvmContext.create(
        logLevel: Level.info,
        isTest: false,
        skipInput: true,
      );
      final logger = Logger(context);
      // When skipInput is true and a defaultSelection is provided, the method returns the corresponding option.
      final result = logger.select("Select an option",
          options: ['one', 'two'], defaultSelection: 1);
      expect(result, equals('two'));
    });
  });

  group('Logger progress tests', () {
    test('progress logs message when verbose', () {
      final context = FvmContext.create(
        logLevel: Level.verbose,
        isTest: true,
        skipInput: true,
      );
      final logger = Logger(context);
      // When verbose, progress cancels and logs the message.
      logger.progress("Processing...");
      expect(
          logger.outputs.any((msg) => msg.contains("Processing...")), isTrue);
    });
  });

  group('Interactive methods testing note', () {
    test('cacheVersionSelector interactive behavior', () {
      // Testing methods that rely on interact (and thus stdin) is challenging in unit tests.
      // One common approach is to refactor your Logger to inject a dependency for interactive input.
      // For example, you could pass in functions that simulate user responses.
      //
      // Alternatively, for unit tests you can set skipInput: true (and/or provide default selections)
      // so that the interactive branches (which call exit or block on input) are bypassed.
      //
      // Here, note that testing cacheVersionSelector without refactoring is not recommended,
      // because if skipInput is true and no defaultSelection is provided to select(),
      // the method calls exit() causing the test process to terminate.
      expect(
        () => logger.cacheVersionSelector([]),
        throwsA(isA<AppException>()),
      );
    });
  });
}
