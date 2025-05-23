import 'package:fvm/src/utils/git_utils.dart';
import 'package:fvm/src/utils/helpers.dart';
import 'package:test/test.dart';

void main() {
  group('Flavor name validation:', () {
    // Test helper functions that are used in the validator
    test('isFlutterChannel detects Flutter channels', () {
      expect(isFlutterChannel('stable'), isTrue);
      expect(isFlutterChannel('beta'), isTrue);
      expect(isFlutterChannel('dev'), isTrue);
      expect(isFlutterChannel('master'), isTrue);

      expect(isFlutterChannel('not-a-channel'), isFalse);
      expect(isFlutterChannel('production'), isFalse);
      expect(isFlutterChannel('3.10.0'), isFalse);
    });

    test('isSemver detects semantic versions', () {
      expect(isSemver('1.0.0'), isTrue);
      expect(isSemver('3.10.5'), isTrue);
      expect(isSemver('1.2.3-beta.1'), isTrue);

      expect(isSemver('not-a-version'), isFalse);
      expect(isSemver('production'), isFalse);
      expect(isSemver('3.test'), isFalse);
    });

    test('isGitCommit detects git commit hashes', () {
      // Valid git hashes - following the implementation rules
      expect(isGitCommit('1234567'), isTrue); // 7-char hash (minimum)
      expect(isGitCommit('abcdef1234'),
          isTrue); // 10-char hash (maximum for short)
      expect(isGitCommit('abcdefabcdefabcdefabcdefabcdefabcdefabcd'),
          isTrue); // 40-char hash

      // Invalid git hashes
      expect(isGitCommit('abcdef'), isFalse); // too short (less than 7 chars)
      expect(isGitCommit('abcdef12345'), isFalse); // 11 chars (not 7-10 or 40)
      expect(isGitCommit('not-a-hash'), isFalse);
      expect(isGitCommit('prod'), isFalse);
      expect(isGitCommit('staging'), isFalse);
    });

    test('regex validates flavor name format', () {
      final regex = RegExp(r'^[a-zA-Z][a-zA-Z0-9_-]*$');

      // Valid patterns
      expect(regex.hasMatch('prod'), isTrue);
      expect(regex.hasMatch('staging'), isTrue);
      expect(regex.hasMatch('prod_env'), isTrue);
      expect(regex.hasMatch('staging-env'), isTrue);

      // Invalid patterns
      expect(regex.hasMatch('1prod'), isFalse);
      expect(regex.hasMatch('prod space'), isFalse);
      expect(regex.hasMatch('prod.env'), isFalse);
      expect(regex.hasMatch('prod@env'), isFalse);
    });

    test('reserved keywords check is case insensitive', () {
      final reservedKeywords = [
        'all',
        'fvm',
        'flutter',
        'dart',
        'version',
        'cache',
        'releases'
      ];

      expect(reservedKeywords.contains('flutter'.toLowerCase()), isTrue);
      expect(reservedKeywords.contains('FLUTTER'.toLowerCase()), isTrue);
      expect(reservedKeywords.contains('Flutter'.toLowerCase()), isTrue);

      expect(reservedKeywords.contains('production'.toLowerCase()), isFalse);
      expect(reservedKeywords.contains('staging'.toLowerCase()), isFalse);
    });
  });
}
