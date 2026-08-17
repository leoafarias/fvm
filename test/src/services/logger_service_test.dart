import 'dart:io';

import 'package:fvm/fvm.dart';
import 'package:fvm/src/services/logger_service.dart';
import 'package:io/io.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

import '../../testing_utils.dart';

class _SelectCaptureLogger extends Logger {
  _SelectCaptureLogger(super.context);

  List<String>? capturedOptions;
  int selectionIndex = 0;

  @override
  String select(
    String? message, {
    required List<String> options,
    int? defaultSelection,
  }) {
    capturedOptions = options;
    final index = selectionIndex < options.length ? selectionIndex : 0;
    return options[index];
  }
}

class _MockStdout extends Mock implements Stdout {}

final class _RecordingSink implements LogSink {
  final events = <LogEvent>[];
  final progress = <String>[];

  @override
  void add(LogEvent event) => events.add(event);

  @override
  LogProgress startProgress(String message) {
    progress.add('start:$message');

    return _RecordingProgress(progress);
  }
}

final class _RecordingProgress implements LogProgress {
  _RecordingProgress(this.events);

  final List<String> events;

  @override
  void cancel([String? message]) => events.add('cancel:${message ?? ''}');

  @override
  void complete([String? message]) => events.add('complete:${message ?? ''}');

  @override
  void fail([String? message]) => events.add('fail:${message ?? ''}');
}

void main() {
  late Logger logger;

  setUp(() {
    logger = Logger(TestFactory.context());
  });
  group('Logger output tests', () {
    test('info adds message to outputs', () {
      logger.info("Test info message");
      expect(logger.outputs.contains("Test info message"), isTrue);
    });

    test('infoToStderr writes plain informational output only to stderr', () {
      final stdout = _MockStdout();
      final stderr = _MockStdout();
      final context = TestFactory.context();
      when(() => stdout.supportsAnsiEscapes).thenReturn(false);
      when(() => stderr.supportsAnsiEscapes).thenReturn(false);

      IOOverrides.runZoned(
        () {
          final logger = Logger(context);

          logger.infoToStderr('Update available!');

          verify(() => stderr.writeln('Update available!')).called(1);
          verifyNever(() => stdout.writeln(any<dynamic>()));
          expect(logger.outputs, contains('Update available!'));
        },
        stdout: () => stdout,
        stderr: () => stderr,
      );
    });

    test('warnToStderr writes warning output only to stderr', () {
      final stdout = _MockStdout();
      final stderr = _MockStdout();
      final context = TestFactory.context();
      when(() => stdout.supportsAnsiEscapes).thenReturn(false);
      when(() => stderr.supportsAnsiEscapes).thenReturn(false);

      IOOverrides.runZoned(
        () {
          final logger = Logger(context);

          logger.warnToStderr('Deprecated environment variables detected:');

          verify(
            () => stderr.writeln('Deprecated environment variables detected:'),
          ).called(1);
          verifyNever(() => stdout.writeln(any<dynamic>()));
          expect(
            logger.outputs,
            contains('Deprecated environment variables detected:'),
          );
        },
        stdout: () => stdout,
        stderr: () => stderr,
      );
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
      final context = TestFactory.context(skipInput: true);
      final logger = Logger(context);

      final result = logger.confirm("Confirm prompt", defaultValue: false);
      expect(result, isFalse);
      // Verify that the confirmation prompt and warnings were added to outputs.
      expect(
        logger.outputs.any((msg) => msg.contains("Confirm prompt")),
        isTrue,
      );
      expect(
        logger.outputs.any(
          (msg) => msg.contains("Skipping input confirmation"),
        ),
        isTrue,
      );
      expect(
        logger.outputs.any(
          (msg) => msg.contains("Using default value of false"),
        ),
        isTrue,
      );
    });

    test('confirm with CI context logs messages and returns default', () {
      final context = TestFactory.context(
        environmentOverrides: const {'CI': 'true'},
      );
      final logger = Logger(context);

      final result = logger.confirm("Confirm prompt", defaultValue: true);

      expect(context.isCI, isTrue);
      expect(context.skipInput, isTrue);
      expect(result, isTrue);
      expect(
        logger.outputs.any(
          (msg) => msg.contains("Skipping input confirmation"),
        ),
        isTrue,
      );
      expect(
        logger.outputs.any(
          (msg) => msg.contains("Using default value of true"),
        ),
        isTrue,
      );
    });

    test(
      'select with skipInput true returns default selection when provided',
      () {
        final context = TestFactory.context(skipInput: true);
        final logger = Logger(context);
        // When skipInput is true and a defaultSelection is provided, the method returns the corresponding option.
        final result = logger.select(
          "Select an option",
          options: ['one', 'two'],
          defaultSelection: 1,
        );
        expect(result, equals('two'));
      },
    );

    test(
      'select with skipInput throws a usage ForceExit without a default',
      () {
        final context = TestFactory.context(skipInput: true);
        final logger = Logger(context);

        expect(
          () => logger.select('Select an option', options: ['one', 'two']),
          throwsA(
            isA<ForceExit>()
                .having(
                  (error) => error.exitCode,
                  'exitCode',
                  ExitCode.usage.code,
                )
                .having((error) => error.message, 'message', isEmpty),
          ),
        );
      },
    );

    test(
      'select with non-TTY stdin returns default selection when provided',
      () {
        final context = TestFactory.context(stdinHasTerminal: false);
        final logger = Logger(context);

        final result = logger.select(
          "Select an option",
          options: ['one', 'two'],
          defaultSelection: 1,
        );

        expect(context.stdinHasTerminal, isFalse);
        expect(context.skipInput, isTrue);
        expect(result, equals('two'));
      },
    );
  });

  group('Logger progress tests', () {
    test('progress logs message when verbose', () {
      final context = TestFactory.context(skipInput: true);
      final logger = Logger(context);
      // When verbose, progress cancels and logs the message.
      logger.progress("Processing...");
      expect(
        logger.outputs.any((msg) => msg.contains("Processing...")),
        isTrue,
      );
    });

    test(
      'zone sink captures nested output without writing to Mason IO',
      () async {
        final stdout = _MockStdout();
        final stderr = _MockStdout();
        final sink = _RecordingSink();
        when(() => stdout.supportsAnsiEscapes).thenReturn(false);
        when(() => stderr.supportsAnsiEscapes).thenReturn(false);

        await IOOverrides.runZoned(
          () async {
            final zonedLogger = Logger(TestFactory.context());

            await zonedLogger.runWithSink(sink, () async {
              zonedLogger.info('info');
              await Future<void>(() => zonedLogger.warn('warning'));
              zonedLogger.err('error');
              zonedLogger.progress('working').complete('done');
            });

            verifyNever(() => stdout.writeln(any<dynamic>()));
            verifyNever(() => stderr.writeln(any<dynamic>()));
            expect(sink.events, [
              (level: LogEventLevel.info, message: 'info'),
              (level: LogEventLevel.warning, message: 'warning'),
              (level: LogEventLevel.error, message: 'error'),
            ]);
            expect(sink.progress, ['start:working', 'complete:done']);

            zonedLogger.info('outside');
            verify(() => stdout.writeln('outside')).called(1);
            expect(sink.events, hasLength(3));
          },
          stdout: () => stdout,
          stderr: () => stderr,
        );
      },
    );
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

  group('cacheVersionSelector', () {
    test('includes fork aliases in options', () {
      final context = TestFactory.context();
      final logger = _SelectCaptureLogger(context);
      final forkDir = path.join(context.versionsCachePath, 'myfork', 'stable');
      final stableDir = path.join(context.versionsCachePath, 'stable');
      final versions = [
        CacheFlutterVersion.fromVersion(
          FlutterVersion.parse('myfork/stable'),
          directory: forkDir,
        ),
        CacheFlutterVersion.fromVersion(
          FlutterVersion.parse('stable'),
          directory: stableDir,
        ),
      ];

      final selected = logger.cacheVersionSelector(versions);

      expect(
        logger.capturedOptions,
        equals(versions.map((version) => version.nameWithAlias).toList()),
      );
      expect(selected, equals(versions.first.nameWithAlias));
    });

    test('returns selected option from select()', () {
      final context = TestFactory.context();
      final logger = _SelectCaptureLogger(context)..selectionIndex = 1;
      final versions = [
        CacheFlutterVersion.fromVersion(
          FlutterVersion.parse('stable'),
          directory: path.join(context.versionsCachePath, 'stable'),
        ),
        CacheFlutterVersion.fromVersion(
          FlutterVersion.parse('beta'),
          directory: path.join(context.versionsCachePath, 'beta'),
        ),
      ];

      final selected = logger.cacheVersionSelector(versions);

      expect(selected, equals(versions[1].nameWithAlias));
    });
  });
}
