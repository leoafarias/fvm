import 'package:fvm/src/utils/compare_semver.dart';
import 'package:test/test.dart';

void main() {
  group('Semver compare test', () {
    // Test case for major version differences
    test('Major versions comparison', () {
      expect(compareSemver("2.0.0", "1.0.0"), 1);
      expect(compareSemver("1.0.0", "2.0.0"), -1);
      expect(compareSemver("1.0.0", "1.0.0"), 0);
    });

    // Test case for minor version differences
    test('Minor versions comparison', () {
      expect(compareSemver("1.2.0", "1.1.0"), 1);
      expect(compareSemver("1.1.0", "1.2.0"), -1);
      expect(compareSemver("1.1.0", "1.1.0"), 0);
    });

    // Test case for patch version differences
    test('Patch versions comparison', () {
      expect(compareSemver("1.1.2", "1.1.1"), 1);
      expect(compareSemver("1.1.1", "1.1.2"), -1);
      expect(compareSemver("1.1.1", "1.1.1"), 0);
    });

    // Test case for mixed differences (major/minor/patch)
    test('Mixed versions comparison', () {
      expect(compareSemver("3.3.2", "2.2.1"), 1);
      expect(compareSemver("2.2.1", "3.3.2"), -1);
      expect(compareSemver("2.2.1", "2.2.1"), 0);
    });

    // Test case for prerelease versions
    test('Prerelease versions comparison', () {
      expect(compareSemver("1.0.0-alpha", "1.0.0-alpha.1"), -1);
      expect(compareSemver("1.0.0-alpha.1", "1.0.0-alpha.beta"), -1);
      expect(compareSemver("1.0.0-alpha.beta", "1.0.0-beta"), -1);
      expect(compareSemver("1.0.0-beta", "1.0.0-beta.2"), -1);
      expect(compareSemver("1.0.0-beta.2", "1.0.0-beta.11"), -1);
      expect(compareSemver("1.0.0-beta.11", "1.0.0-rc.1"), -1);
      expect(compareSemver("1.0.0-rc.1", "1.0.0"), -1);
    });

    // Test case for build metadata (should be ignored when comparing)
    test('Metadata versions comparison', () {
      expect(compareSemver("1.0.0+20130313144700", "1.0.0+20130313144700"), 0);
    });

    // Test case for invalid version formats
    test('Invalid versions comparison', () {
      expect(() => compareSemver("1.0.0", "invalid"), throwsFormatException);
      expect(() => compareSemver("invalid", "1.0.0"), throwsFormatException);
      expect(() => compareSemver("invalid", "invalid"), throwsFormatException);
    });
  });
}
