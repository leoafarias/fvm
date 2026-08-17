import 'package:fvm/src/utils/git_clone_progress_tracker.dart';
import 'package:test/test.dart';

void main() {
  group('GitCloneProgressTracker', () {
    late GitCloneProgressTracker tracker;

    setUp(() => tracker = GitCloneProgressTracker());

    test('parses every supported phase and trims the source line', () {
      const lines = [
        '  Enumerating objects: 0%  ',
        'remote: Counting objects:  25% (1/4)',
        'Compressing objects: 50%',
        'Receiving objects:  75% (3/4)',
        'Resolving deltas: 100% (4/4), done.',
      ];

      final updates = lines.map(tracker.processLine).toList();

      expect(updates, [
        (phase: 'Enumerating objects:', percent: 0, line: lines[0].trim()),
        (phase: 'Counting objects:', percent: 25, line: lines[1].trim()),
        (phase: 'Compressing objects:', percent: 50, line: lines[2].trim()),
        (phase: 'Receiving objects:', percent: 75, line: lines[3].trim()),
        (phase: 'Resolving deltas:', percent: 100, line: lines[4].trim()),
      ]);
    });

    test('accepts git spacing variants including zero and one hundred', () {
      expect(
        tracker.processLine('Receiving objects:   0% (1/1824)'),
        isNotNull,
      );
      expect(
        tracker.processLine('Receiving objects: 100% (1824/1824)'),
        isNotNull,
      );
    });

    test('ignores malformed and unrelated input', () {
      expect(tracker.processLine('Cloning into flutter...'), isNull);
      expect(tracker.processLine('Receiving objects: nope%'), isNull);
      expect(tracker.processLine('Receiving objects: 50.5%'), isNull);
      expect(tracker.processLine('Receiving objects:'), isNull);
    });

    test('suppresses duplicates only within the same phase', () {
      expect(tracker.processLine('Counting objects: 25%'), isNotNull);
      expect(tracker.processLine('Counting objects: 25%'), isNull);
      expect(tracker.processLine('Compressing objects: 25%'), isNotNull);
    });

    test('reports decreasing percentages when Git emits them', () {
      expect(tracker.processLine('Receiving objects: 75%')?.percent, 75);
      expect(tracker.processLine('Receiving objects: 50%')?.percent, 50);
    });
  });
}
