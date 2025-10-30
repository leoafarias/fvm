import 'package:test/test.dart';
import 'package:fvm/src/utils/git_clone_progress_tracker.dart';
import 'package:fvm/src/services/logger_service.dart';
import '../../testing_utils.dart';

class TestLogger extends Logger {
  final List<String> writtenLines = [];

  TestLogger(super.context);

  @override
  void write(Object? object) {
    writtenLines.add(object.toString());
  }

  void clear() {
    writtenLines.clear();
  }
}

void main() {
  group('GitCloneProgressTracker', () {
    late GitCloneProgressTracker tracker;
    late TestLogger logger;

    setUp(() {
      final context = TestFactory.context();
      logger = TestLogger(context);
      tracker = GitCloneProgressTracker(logger);
    });

    group('Phase Recognition', () {
      test('recognizes all git clone phases', () {
        const phases = [
          'Enumerating objects: 25%',
          'Counting objects: 50%',
          'Compressing objects: 75%',
          'Receiving objects: 90%',
          'Resolving deltas: 100%',
        ];

        for (final phase in phases) {
          tracker.processLine(phase);
        }

        expect(logger.writtenLines.length, greaterThan(0));
      });

      test('ignores non-progress lines', () {
        const nonProgressLines = [
          'Cloning into...',
          'remote: Enumerating objects: 1234, done.',
          'fatal: error occurred',
          'warning: something happened',
        ];

        for (final line in nonProgressLines) {
          tracker.processLine(line);
        }

        expect(logger.writtenLines, isEmpty);
      });

      test('handles malformed progress lines gracefully', () {
        const malformedLines = [
          'Enumerating objects: invalid%',
          'Counting objects: %',
          'Receiving objects: 50.5%',
          'Enumerating objects:',
        ];

        for (final line in malformedLines) {
          tracker.processLine(line);
        }

        // Should not crash and may or may not produce output
        expect(
          logger.writtenLines.length,
          lessThanOrEqualTo(malformedLines.length),
        );
      });
    });

    group('Progress Updates', () {
      test('displays progress bar for valid percentage', () {
        tracker.processLine('Enumerating objects: 25%');

        expect(logger.writtenLines, hasLength(1));
        final output = logger.writtenLines.first;
        expect(output, contains('Enumerating objects:'));
        expect(output, contains('25%'));
        expect(output, contains('['));
        expect(output, contains(']'));
      });

      test('only updates when percentage changes', () {
        tracker.processLine('Enumerating objects: 25%');
        tracker.processLine('Enumerating objects: 25%');
        tracker.processLine('Enumerating objects: 25%');

        expect(logger.writtenLines, hasLength(1));
      });

      test('updates when percentage increases', () {
        tracker.processLine('Enumerating objects: 25%');
        tracker.processLine('Enumerating objects: 50%');
        tracker.processLine('Enumerating objects: 75%');

        expect(logger.writtenLines, hasLength(3));
      });

      test(
        'handles percentage decrease (git can send decreasing percentages)',
        () {
          tracker.processLine('Enumerating objects: 75%');
          tracker.processLine('Enumerating objects: 50%');

          expect(logger.writtenLines, hasLength(2));
        },
      );
    });

    group('Phase Transitions', () {
      test('completes previous phase at 100% when switching phases', () {
        tracker.processLine('Enumerating objects: 50%');
        tracker.processLine('Counting objects: 25%');

        expect(logger.writtenLines, hasLength(4));
        expect(
          logger.writtenLines[1],
          contains('100%'),
        ); // Previous phase completed
        expect(logger.writtenLines[2], equals('\n')); // Newline between phases
        expect(logger.writtenLines[3], contains('Counting objects:'));
      });

      test('adds newline when transitioning between phases', () {
        tracker.processLine('Enumerating objects: 50%');
        tracker.processLine('Counting objects: 25%');

        expect(logger.writtenLines, contains('\n'));
      });

      test('handles multiple phase transitions correctly', () {
        tracker.processLine('Enumerating objects: 50%');
        tracker.processLine('Counting objects: 75%');
        tracker.processLine('Compressing objects: 25%');

        expect(logger.writtenLines, hasLength(7));
        // Should have: enum 50%, enum 100%, newline, count 75%, count 100%, newline, compress 25%
      });
    });

    group('Progress Bar Format', () {
      test('formats progress bar correctly', () {
        tracker.processLine('Enumerating objects: 50%');

        final output = logger.writtenLines.first;
        expect(output, startsWith('\r '));
        expect(output, contains('Enumerating objects:'));
        expect(output, contains('['));
        expect(output, contains(']'));
        expect(output, contains('50%'));
        expect(output, endsWith('50%'));
      });

      test('uses consistent label width for all phases', () {
        tracker.processLine('Enumerating objects: 25%');
        logger.clear();
        tracker.processLine('Counting objects: 50%');

        final output1 = logger.writtenLines.last;
        logger.clear();

        tracker.processLine('Resolving deltas: 75%');
        final output2 = logger.writtenLines.last;

        // Extract label portions and verify they have same width
        final labelEnd1 = output1.indexOf('[');
        final labelEnd2 = output2.indexOf('[');
        expect(labelEnd1, equals(labelEnd2));
      });

      test('progress bar has correct number of filled blocks', () {
        tracker.processLine('Enumerating objects: 50%');

        final output = logger.writtenLines.first;
        final startBracket = output.indexOf('[');
        final endBracket = output.indexOf(']');
        final progressSection = output.substring(startBracket + 1, endBracket);

        // At 50%, should have 25 filled blocks out of 50 total
        final filledBlocks = '█'.allMatches(progressSection).length;
        expect(filledBlocks, equals(25));
      });
    });

    group('Edge Cases', () {
      test('handles 0% progress', () {
        tracker.processLine('Enumerating objects: 0%');

        expect(logger.writtenLines, hasLength(1));
        expect(logger.writtenLines.first, contains('0%'));
      });

      test('handles 100% progress', () {
        tracker.processLine('Enumerating objects: 100%');

        expect(logger.writtenLines, hasLength(1));
        expect(logger.writtenLines.first, contains('100%'));
      });

      test('handles progress values over 100%', () {
        tracker.processLine('Enumerating objects: 150%');

        expect(logger.writtenLines, hasLength(1));
        expect(logger.writtenLines.first, contains('150%'));
      });

      test('preserves state across multiple calls', () {
        tracker.processLine('Enumerating objects: 25%');
        tracker.processLine('Enumerating objects: 50%');

        expect(logger.writtenLines, hasLength(2));

        // Process same percentage again - should not update
        tracker.processLine('Enumerating objects: 50%');
        expect(logger.writtenLines, hasLength(2));
      });
    });

    group('Real Git Output Examples', () {
      test('handles actual git clone stderr output', () {
        const realGitLines = [
          'Cloning into \'flutter\'...',
          'remote: Enumerating objects: 1051234, done.',
          'Receiving objects:   1% (10513/1051234), 4.12 MiB | 8.23 MiB/s',
          'Receiving objects:  25% (262809/1051234), 102.45 MiB | 15.67 MiB/s',
          'Receiving objects:  50% (525617/1051234), 203.12 MiB | 18.43 MiB/s',
          'Receiving objects: 100% (1051234/1051234), 406.89 MiB | 19.12 MiB/s, done.',
          'Resolving deltas:  10% (84123/841234)',
          'Resolving deltas:  50% (420617/841234)',
          'Resolving deltas: 100% (841234/841234), done.',
        ];

        for (final line in realGitLines) {
          tracker.processLine(line);
        }

        // Should extract and display progress from the percentage lines
        expect(logger.writtenLines.length, greaterThan(0));
      });

      test('handles real git output format with multiple spaces', () {
        // Real git output captured from actual clone operation
        const realGitOutput = [
          'remote: Counting objects:   0% (1/305)        ',
          'remote: Counting objects:  25% (77/305)        ',
          'remote: Counting objects:  50% (153/305)        ',
          'remote: Counting objects:  75% (229/305)        ',
          'remote: Counting objects: 100% (305/305)        ',
          'remote: Counting objects: 100% (305/305), done.        ',
          'remote: Compressing objects:   0% (1/119)        ',
          'remote: Compressing objects:  50% (60/119)        ',
          'remote: Compressing objects: 100% (119/119)        ',
          'remote: Compressing objects: 100% (119/119), done.        ',
        ];

        for (final line in realGitOutput) {
          tracker.processLine(line);
        }

        // Should process all percentage lines
        final outputs =
            logger.writtenLines.where((line) => line.contains('%')).toList();
        expect(
          outputs.length,
          greaterThanOrEqualTo(8),
        ); // At least 8 progress updates

        // Verify phase transitions include newlines
        expect(logger.writtenLines, contains('\n'));
      });

      test('handles git output with varying spacing patterns', () {
        // Git uses different spacing for different percentage values
        const spacingPatterns = [
          'Receiving objects:   0% (1/1824)', // 3 spaces for single digit
          'Receiving objects:   9% (165/1824)', // 3 spaces for single digit
          'Receiving objects:  10% (183/1824)', // 2 spaces for double digit
          'Receiving objects:  99% (1806/1824)', // 2 spaces for double digit
          'Receiving objects: 100% (1824/1824)', // 1 space for triple digit
        ];

        for (final line in spacingPatterns) {
          tracker.processLine(line);
        }

        // All patterns should be recognized
        expect(
          logger.writtenLines
              .where((line) => line.contains('Receiving objects:'))
              .length,
          equals(5),
        );
      });
    });
  });
}
