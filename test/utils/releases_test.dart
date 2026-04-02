import 'package:fvm/src/services/releases_service/models/flutter_releases_model.dart';
import 'package:fvm/src/utils/exceptions.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:test/test.dart';

import '../testing_utils.dart';

void main() {
  group('Flutter Releases', () {
    late TestCommandRunner runner;

    setUp(() {
      runner = TestFactory.commandRunner();
    });

    test('Can check releases', () async {
      final exitCode = await runner.run(['fvm', 'releases']);

      expect(exitCode, ExitCode.success.code);
    });
  });

  group('FlutterReleasesResponse.fromMap validation', () {
    // Valid minimal payload for reference
    // Note: Using explicit dynamic types to allow code to add 'active_channel': bool
    Map<String, dynamic> createValidPayload() => {
          'base_url': 'https://storage.googleapis.com/flutter_infra_release',
          'current_release': <String, dynamic>{
            'stable': 'abc123',
            'beta': 'def456',
            'dev': 'ghi789',
          },
          'releases': <Map<String, dynamic>>[
            <String, dynamic>{
              'hash': 'abc123',
              'channel': 'stable',
              'version': '3.24.0',
              'release_date': '2024-01-01T00:00:00.000Z',
              'archive': 'stable/macos/flutter_macos_3.24.0-stable.zip',
              'sha256': 'sha256hash',
            },
            <String, dynamic>{
              'hash': 'def456',
              'channel': 'beta',
              'version': '3.25.0-0.1.pre',
              'release_date': '2024-01-01T00:00:00.000Z',
              'archive': 'beta/macos/flutter_macos_3.25.0-0.1.pre-beta.zip',
              'sha256': 'sha256hash',
            },
            <String, dynamic>{
              'hash': 'ghi789',
              'channel': 'dev',
              'version': '3.26.0-0.0.pre',
              'release_date': '2024-01-01T00:00:00.000Z',
              'archive': 'dev/macos/flutter_macos_3.26.0-0.0.pre-dev.zip',
              'sha256': 'sha256hash',
            },
          ],
        };

    test('parses valid payload successfully', () {
      final payload = createValidPayload();
      final result = FlutterReleasesResponse.fromMap(payload);

      expect(result.baseUrl, isNotEmpty);
      expect(result.versions, hasLength(3));
      expect(result.channels.stable.version, equals('3.24.0'));
    });

    test('throws on missing base_url', () {
      final payload = createValidPayload();
      payload.remove('base_url');

      expect(
        () => FlutterReleasesResponse.fromMap(payload),
        throwsA(
          isA<AppException>().having(
            (e) => e.message,
            'message',
            contains('missing base_url'),
          ),
        ),
      );
    });

    test('throws on empty base_url', () {
      final payload = createValidPayload();
      payload['base_url'] = '';

      expect(
        () => FlutterReleasesResponse.fromMap(payload),
        throwsA(
          isA<AppException>().having(
            (e) => e.message,
            'message',
            contains('missing base_url'),
          ),
        ),
      );
    });

    test('throws on missing current_release', () {
      final payload = createValidPayload();
      payload.remove('current_release');

      expect(
        () => FlutterReleasesResponse.fromMap(payload),
        throwsA(
          isA<AppException>().having(
            (e) => e.message,
            'message',
            contains('missing current_release'),
          ),
        ),
      );
    });

    test('throws on missing releases list', () {
      final payload = createValidPayload();
      payload.remove('releases');

      expect(
        () => FlutterReleasesResponse.fromMap(payload),
        throwsA(
          isA<AppException>().having(
            (e) => e.message,
            'message',
            contains('missing releases list'),
          ),
        ),
      );
    });

    test('throws on non-list releases', () {
      final payload = createValidPayload();
      payload['releases'] = 'not a list';

      expect(
        () => FlutterReleasesResponse.fromMap(payload),
        throwsA(
          isA<AppException>().having(
            (e) => e.message,
            'message',
            contains('missing releases list'),
          ),
        ),
      );
    });

    test('throws on release entries that are not objects', () {
      final payload = createValidPayload();
      payload['releases'] = ['not', 'objects'];

      expect(
        () => FlutterReleasesResponse.fromMap(payload),
        throwsA(
          isA<AppException>().having(
            (e) => e.message,
            'message',
            contains('release entries must be objects'),
          ),
        ),
      );
    });

    test('throws on missing channel hashes', () {
      final payload = createValidPayload();
      (payload['current_release'] as Map).remove('stable');

      expect(
        () => FlutterReleasesResponse.fromMap(payload),
        throwsA(
          isA<AppException>().having(
            (e) => e.message,
            'message',
            contains('missing release channels'),
          ),
        ),
      );
    });

    test('throws when channel release not found in releases', () {
      final payload = createValidPayload();
      // Point stable to a hash that doesn't exist in releases
      (payload['current_release'] as Map)['stable'] = 'nonexistent_hash';

      expect(
        () => FlutterReleasesResponse.fromMap(payload),
        throwsA(
          isA<AppException>().having(
            (e) => e.message,
            'message',
            contains('missing channel releases'),
          ),
        ),
      );
    });
  });
}
