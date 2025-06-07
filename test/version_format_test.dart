import 'package:fvm/src/models/flutter_version_model.dart';
import 'package:test/test.dart';

import 'testing_utils.dart';

void main() {
  group('Flutter Version Format Tests', () {
    group('Channel Versions', () {
      test('Stable channel', () {
        final version = FlutterVersion.parse('stable');
        expect(version.name, 'stable');
        expect(version.isChannel, isTrue);
        expect(version.isRelease, isFalse);
        expect(version.isUnknownRef, isFalse);
        expect(version.isCustom, isFalse);
        expect(version.fromFork, isFalse);
      });

      test('Beta channel', () {
        final version = FlutterVersion.parse('beta');
        expect(version.name, 'beta');
        expect(version.isChannel, isTrue);
        expect(version.isRelease, isFalse);
      });

      test('Dev channel', () {
        final version = FlutterVersion.parse('dev');
        expect(version.name, 'dev');
        expect(version.isChannel, isTrue);
        expect(version.isRelease, isFalse);
      });

      test('Master channel', () {
        final version = FlutterVersion.parse('master');
        expect(version.name, 'master');
        expect(version.isChannel, isTrue);
        expect(version.isMain, isTrue);
        expect(version.isRelease, isFalse);
      });
    });

    group('Semantic Versions', () {
      test('Standard version format', () {
        final version = FlutterVersion.parse('2.10.0');
        expect(version.name, '2.10.0');
        expect(version.isRelease, isTrue);
        expect(version.isChannel, isFalse);
        expect(version.isUnknownRef, isFalse);
        expect(version.fromFork, isFalse);
      });

      test('Version with v prefix', () {
        final version = FlutterVersion.parse('v2.10.0');
        expect(version.name, 'v2.10.0');
        expect(version.version, 'v2.10.0');
        expect(version.isRelease, isTrue);
        expect(version.isChannel, isFalse);
      });

      test('Pre-release version', () {
        final version = FlutterVersion.parse('2.10.0-beta.1');
        expect(version.name, '2.10.0-beta.1');
        expect(version.isRelease, isTrue);
        expect(version.isChannel, isFalse);
      });

      test('Pre-release version with v prefix', () {
        final version = FlutterVersion.parse('v2.10.0-beta.1');
        expect(version.name, 'v2.10.0-beta.1');
        expect(version.isRelease, isTrue);
        expect(version.isChannel, isFalse);
      });
    });

    group('Git References', () {
      test('Short git commit', () {
        final version = FlutterVersion.parse(TestVersions.validCommit);
        expect(version.name, TestVersions.validCommit);
        expect(version.isUnknownRef, isTrue);
        expect(version.isRelease, isFalse);
        expect(version.isChannel, isFalse);
      });

      test('Full git commit', () {
        final longCommit = TestVersions.invalidCommit;
        final version = FlutterVersion.parse(longCommit);
        expect(version.name, longCommit);
        expect(version.isUnknownRef, isTrue);
        expect(version.isRelease, isFalse);
        expect(version.isChannel, isFalse);
      });
    });

    group('Version with Channel', () {
      test('Version with beta channel', () {
        final version = FlutterVersion.parse('2.10.0@beta');
        expect(version.name, '2.10.0@beta');
        expect(version.version, '2.10.0');
        expect(version.releaseChannel, FlutterChannel.beta);
        expect(version.isRelease, isTrue);
        expect(version.isChannel, isFalse);
      });

      test('Version with dev channel', () {
        final version = FlutterVersion.parse('2.10.0@dev');
        expect(version.name, '2.10.0@dev');
        expect(version.version, '2.10.0');
        expect(version.releaseChannel, FlutterChannel.dev);
        expect(version.isRelease, isTrue);
      });

      test('Version with v prefix and channel', () {
        final version = FlutterVersion.parse('v2.10.0@beta');
        expect(version.name, 'v2.10.0@beta');
        expect(version.version, 'v2.10.0');
        expect(version.releaseChannel, FlutterChannel.beta);
        expect(version.isRelease, isTrue);
      });
    });

    group('Custom Versions', () {
      test('Custom version', () {
        final version = FlutterVersion.parse('custom_my_build');
        expect(version.name, 'custom_my_build');
        expect(version.isCustom, isTrue);
        expect(version.isRelease, isFalse);
        expect(version.isChannel, isFalse);
        expect(version.isUnknownRef, isFalse);
      });
    });

    group('Fork Versions', () {
      test('Fork with channel', () {
        final version = FlutterVersion.parse('myfork/stable');
        expect(version.name, 'stable');
        expect(version.fork, 'myfork');
        expect(version.fromFork, isTrue);
        expect(version.isChannel, isTrue);
      });

      test('Fork with version', () {
        final version = FlutterVersion.parse('myfork/2.10.0');
        expect(version.name, '2.10.0');
        expect(version.fork, 'myfork');
        expect(version.fromFork, isTrue);
        expect(version.isRelease, isTrue);
      });

      test('Fork with version and v prefix', () {
        final version = FlutterVersion.parse('myfork/v2.10.0');
        expect(version.name, 'v2.10.0');
        expect(version.fork, 'myfork');
        expect(version.fromFork, isTrue);
        expect(version.isRelease, isTrue);
      });

      test('Fork with commit', () {
        final version = FlutterVersion.parse(
          'myfork/${TestVersions.validCommit}',
        );
        expect(version.name, TestVersions.validCommit);
        expect(version.fork, 'myfork');
        expect(version.fromFork, isTrue);
        expect(version.isUnknownRef, isTrue);
      });

      test('Fork with version and channel', () {
        final version = FlutterVersion.parse('myfork/2.10.0@beta');
        expect(version.name, '2.10.0@beta');
        expect(version.version, '2.10.0');
        expect(version.fork, 'myfork');
        expect(version.fromFork, isTrue);
        expect(version.releaseChannel, FlutterChannel.beta);
        expect(version.isRelease, isTrue);
      });
    });

    group('Error Cases', () {
      test('Invalid channel', () {
        expect(
          () => FlutterVersion.parse('2.10.0@invalid'),
          throwsA(
            isA<FormatException>().having(
              (e) => e.message,
              'message',
              contains('Invalid channel'),
            ),
          ),
        );
      });

      test('Custom version with fork', () {
        expect(
          () => FlutterVersion.parse('myfork/custom_build'),
          throwsA(
            isA<FormatException>().having(
              (e) => e.message,
              'message',
              contains('Custom versions cannot have fork'),
            ),
          ),
        );
      });

      test('Custom version with channel', () {
        expect(
          () => FlutterVersion.parse('custom_build@beta'),
          throwsA(
            isA<FormatException>().having(
              (e) => e.message,
              'message',
              contains('Custom versions cannot have fork or channel'),
            ),
          ),
        );
      });
    });

    group('Edge Cases', () {
      test('Version with complex pre-release', () {
        final version = FlutterVersion.parse('2.10.0-1.2.pre');
        expect(version.name, '2.10.0-1.2.pre');
        expect(version.isRelease, isTrue);
      });

      test('Version with complex pre-release and v prefix', () {
        final version = FlutterVersion.parse('v2.10.0-1.2.pre');
        expect(version.name, 'v2.10.0-1.2.pre');
        expect(version.isRelease, isTrue);
      });

      test('Version with build metadata', () {
        final version = FlutterVersion.parse('2.10.0+1');
        expect(version.name, '2.10.0+1');
        expect(version.isRelease, isTrue);
      });

      test('Version with build metadata and v prefix', () {
        final version = FlutterVersion.parse('v2.10.0+1');
        expect(version.name, 'v2.10.0+1');
        expect(version.isRelease, isTrue);
      });

      test('Version with complex semver', () {
        final version = FlutterVersion.parse('2.10.0-beta.1+sha.12345');
        expect(version.name, '2.10.0-beta.1+sha.12345');
        expect(version.isRelease, isTrue);
      });
    });
  });
}
