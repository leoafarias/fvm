import 'package:fvm/src/utils/git_utils.dart';
import 'package:test/test.dart';

void main() {
  group('Is git commit', () {
    test('Long valid git hash', () {
      const String testHash = '476ad8a917e64e345f05e4147e573e2a42b379f9';
      expect(isPossibleGitCommit(testHash), isTrue);
    });

    test('Short valid git hash', () {
      const String testHash = 'fa345b1';
      expect(isPossibleGitCommit(testHash), isTrue);
    });

    test('Too Short invalid git hash', () {
      const String testHash = 'fa3';
      expect(isPossibleGitCommit(testHash), isFalse);
    });

    test('Invalid character in git hash', () {
      const String testHash = '476ad8g917e64e345f05e4147e573e2a42b379f9';
      expect(isPossibleGitCommit(testHash), isFalse);
    });
  });
}
