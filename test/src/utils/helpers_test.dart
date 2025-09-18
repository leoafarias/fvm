import 'package:fvm/src/utils/helpers.dart';
import 'package:test/test.dart';

void main() {
  group('isValidGitUrl', () {
    test('should accept HTTPS URLs', () {
      expect(isValidGitUrl('https://github.com/flutter/flutter.git'), isTrue);
      expect(isValidGitUrl('https://gitlab.com/user/repo.git'), isTrue);
      expect(isValidGitUrl('https://bitbucket.org/user/repo.git'), isTrue);
    });

    test('should accept HTTP URLs', () {
      expect(isValidGitUrl('http://github.com/flutter/flutter.git'), isTrue);
      expect(isValidGitUrl('http://gitlab.com/user/repo.git'), isTrue);
    });

    test('should accept SSH URLs with ssh:// prefix', () {
      expect(isValidGitUrl('ssh://git@github.com:22/flutter/flutter.git'), isTrue);
      expect(isValidGitUrl('ssh://git@gitlab.com/user/repo.git'), isTrue);
      expect(isValidGitUrl('ssh://git@bitbucket.org/user/repo.git'), isTrue);
    });

    test('should accept SSH URLs without ssh:// prefix', () {
      expect(isValidGitUrl('git@github.com:flutter/flutter.git'), isTrue);
      expect(isValidGitUrl('git@gitlab.com:user/repo.git'), isTrue);
      expect(isValidGitUrl('git@bitbucket.org:user/repo.git'), isTrue);
      expect(isValidGitUrl('user@example.com:path/to/repo.git'), isTrue);
    });

    test('should accept URLs with subdirectories', () {
      expect(isValidGitUrl('https://github.com/company/team/project.git'), isTrue);
      expect(isValidGitUrl('git@github.com:company/team/project.git'), isTrue);
    });

    test('should accept URLs with special characters in paths', () {
      expect(isValidGitUrl('https://github.com/user/my-repo.git'), isTrue);
      expect(isValidGitUrl('git@github.com:user/my_repo.git'), isTrue);
      expect(isValidGitUrl('https://gitlab.com/user/repo.with.dots.git'), isTrue);
    });

    test('should reject URLs without .git suffix', () {
      expect(isValidGitUrl('https://github.com/flutter/flutter'), isFalse);
      expect(isValidGitUrl('git@github.com:flutter/flutter'), isFalse);
      expect(isValidGitUrl('ssh://git@github.com/flutter/flutter'), isFalse);
    });

    test('should reject malformed URLs', () {
      expect(isValidGitUrl('not-a-url'), isFalse);
      expect(isValidGitUrl(''), isFalse);
      expect(isValidGitUrl('github.com/flutter/flutter.git'), isFalse);
      expect(isValidGitUrl('://github.com/flutter/flutter.git'), isFalse);
    });

    test('should reject malformed SSH URLs', () {
      expect(isValidGitUrl('@github.com:flutter/flutter.git'), isFalse);
      expect(isValidGitUrl('git@:flutter/flutter.git'), isFalse);
      expect(isValidGitUrl('git@github.com'), isFalse);
    });

    test('should handle edge cases gracefully', () {
      expect(isValidGitUrl('ftp://github.com/flutter/flutter.git'), isTrue); // FTP should work too
      expect(isValidGitUrl('file:///path/to/repo.git'), isTrue); // Local file URLs
    });

    test('should reject null and handle exceptions', () {
      // These should not throw but return false
      expect(isValidGitUrl('git@[invalid'), isFalse);
      expect(isValidGitUrl('https://[invalid'), isFalse);
    });
  });
}