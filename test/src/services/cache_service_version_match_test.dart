import 'package:fvm/src/services/cache_service.dart';
import 'package:test/test.dart';

import '../../testing_utils.dart';

void main() {
  group('versionsMatch', () {
    late CacheService cacheService;

    setUp(() {
      cacheService = CacheService(TestFactory.context());
    });
    test('returns true for matching versions', () {
      expect(cacheService.versionsMatch('1.2.3', '1.2.3'), isTrue);
    });

    test('handles leading v prefix differences', () {
      expect(cacheService.versionsMatch('v1.2.3', '1.2.3'), isTrue);
      expect(cacheService.versionsMatch('V3.4.5', '3.4.5'), isTrue);
    });

    test('tolerates stripped pre-release from cached SDK', () {
      expect(cacheService.versionsMatch('1.17.0-dev.3.1', '1.17.0'), isTrue);
    });

    test('requires exact match when both sides include pre-release', () {
      expect(
        cacheService.versionsMatch('1.17.0-dev.3.1', '1.17.0-dev.3.1'),
        isTrue,
      );
      expect(
        cacheService.versionsMatch('1.17.0-dev.3.1', '1.17.0-dev.4.0'),
        isFalse,
      );
      expect(
        cacheService.versionsMatch('3.19.0-1.0.pre.1', '3.19.0-1.0.pre.2'),
        isFalse,
      );
    });

    test('rejects when cached retains pre-release suffix', () {
      expect(cacheService.versionsMatch('1.17.0', '1.17.0-dev.3.1'), isFalse);
    });

    test('rejects differing build metadata', () {
      expect(
        cacheService.versionsMatch('1.12.13+hotfix.9', '1.12.13+hotfix.9'),
        isTrue,
      );
      expect(
        cacheService.versionsMatch('1.12.13+hotfix.9', '1.12.13+hotfix.8'),
        isFalse,
      );
    });

    test('falls back to normalized string equality for non-semver refs', () {
      expect(cacheService.versionsMatch('abc123', 'abc123'), isTrue);
      expect(cacheService.versionsMatch('abc123', 'def456'), isFalse);
    });

    test('preserves case sensitivity beyond leading prefix', () {
      expect(cacheService.versionsMatch('FeatureFix', 'featurefix'), isFalse);
    });

    test('flags real version mismatches', () {
      expect(cacheService.versionsMatch('3.16.0', '3.19.0'), isFalse);
    });
  });
}
