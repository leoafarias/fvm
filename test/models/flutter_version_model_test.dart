import 'package:fvm/src/models/flutter_version_model.dart';
import 'package:test/test.dart';

import '../testing_utils.dart';

void main() {
  group('Validate version behave correclty', () {
    const longCommit = TestVersions.invalidCommit;
    const shortCommit = TestVersions.validCommit;

    test('Valid Version behaves correctly', () async {
      final master = FlutterVersion.parse('master');
      final beta = FlutterVersion.parse('beta');
      final channelWithVersion = FlutterVersion.parse('2.2.2@beta');
      final version = FlutterVersion.parse('2.2.0');
      final gitCommit = FlutterVersion.parse(longCommit);
      final shortGitCommit = FlutterVersion.parse(shortCommit);

      // Check if its channel
      expect(master.isChannel, true);
      expect(beta.isChannel, true);
      expect(channelWithVersion.isChannel, false);
      expect(version.isChannel, false);
      expect(gitCommit.isChannel, false);
      expect(shortGitCommit.isChannel, false);

      // Check for correct vertsion
      expect(master.name, 'master');
      expect(beta.name, 'beta');
      expect(channelWithVersion.name, '2.2.2@beta');
      expect(channelWithVersion.version, '2.2.2');
      expect(channelWithVersion.releaseChannel, FlutterChannel.beta);
      expect(version.name, '2.2.0');
      expect(gitCommit.name, longCommit);
      expect(shortGitCommit.name, shortCommit);

      // Check if forces channel
      expect(master.releaseChannel, null);
      expect(beta.releaseChannel, null);
      expect(channelWithVersion.releaseChannel, FlutterChannel.beta);
      expect(version.releaseChannel, null);
      expect(gitCommit.releaseChannel, null);
      expect(shortGitCommit.releaseChannel, null);

      // Check if its master
      expect(master.isMain, true);
      expect(beta.isMain, false);
      expect(channelWithVersion.isMain, false);
      expect(version.isMain, false);
      expect(gitCommit.isMain, false);
      expect(shortGitCommit.isMain, false);

      // Check if its release
      expect(master.isRelease, false);
      expect(beta.isRelease, false);
      expect(channelWithVersion.isRelease, true);
      expect(version.isRelease, true);
      expect(gitCommit.isRelease, false);
      expect(shortGitCommit.isRelease, false);

      // Check if its commit
      expect(master.isUnknownRef, false);
      expect(beta.isUnknownRef, false);
      expect(channelWithVersion.isUnknownRef, false);
      expect(version.isUnknownRef, false);
      expect(gitCommit.isUnknownRef, true);
      expect(shortGitCommit.isUnknownRef, true);

      // Checks version
      expect(master.name, 'master');
      expect(beta.name, 'beta');
      expect(channelWithVersion.version, '2.2.2');
      expect(version.name, '2.2.0');
      expect(gitCommit.name, longCommit);
      expect(shortGitCommit.name, shortCommit);
    });
  });
  group('FlutterVersion model', () {
    test('compareTo', () async {
      const unsortedList = [
        'dev',
        '1.20.0',
        '1.22.0-1.0.pre',
        '1.3.1',
        'stable',
        'beta',
        '1.21.0-9.1.pre',
        'master',
        '2.0.0',
      ];
      const sortedList = [
        'master',
        'stable',
        'beta',
        'dev',
        '2.0.0',
        '1.22.0-1.0.pre',
        '1.21.0-9.1.pre',
        '1.20.0',
        '1.3.1',
      ];

      final versionUnsorted = unsortedList.map(FlutterVersion.parse).toList();
      versionUnsorted.sort((a, b) => a.compareTo(b));

      final afterUnsorted = versionUnsorted.reversed
          .map((e) => e.name)
          .toList();

      expect(afterUnsorted, sortedList);
    });
  });

  group('FlutterVersion', () {
    test('fromMap constructor', () {
      final map = {
        'name': 'test',
        'releaseChannel': 'stable',
        'type': 'release',
      };
      final version = FlutterVersion.fromMap(map);
      expect(version.name, 'test');
      expect(version.releaseChannel, FlutterChannel.stable);
      expect(version.type, VersionType.release);
    });

    test('fromJson constructor', () {
      final json = '{"name":"test","releaseChannel":"stable","type":"release"}';
      final version = FlutterVersion.fromJson(json);
      expect(version.name, 'test');
      expect(version.releaseChannel, FlutterChannel.stable);
      expect(version.type, VersionType.release);
    });

    test('commit constructor', () {
      final version = FlutterVersion.gitReference('abc123');
      expect(version.name, 'abc123');
      expect(version.releaseChannel, isNull);
      expect(version.type, VersionType.unknownRef);
    });

    test('channel constructor', () {
      final version = FlutterVersion.channel('stable');
      expect(version.name, 'stable');
      expect(version.releaseChannel, isNull);
      expect(version.type, VersionType.channel);
    });

    test('custom constructor', () {
      final version = FlutterVersion.custom('custom_123');
      expect(version.name, 'custom_123');
      expect(version.releaseChannel, isNull);
      expect(version.type, VersionType.custom);
    });

    test('release constructor', () {
      final version = FlutterVersion.release(
        '1.0.0',
        releaseChannel: FlutterChannel.stable,
      );
      expect(version.name, '1.0.0');
      expect(version.releaseChannel, FlutterChannel.stable);
      expect(version.type, VersionType.release);
    });

    test('parse method - release version', () {
      final version = FlutterVersion.parse('1.0.0');
      expect(version.name, '1.0.0');
      expect(version.releaseChannel, isNull);
      expect(version.type, VersionType.release);
    });

    test('parse method - release version with channel', () {
      final version = FlutterVersion.parse('1.0.0@stable');
      expect(version.name, '1.0.0@stable');
      expect(version.releaseChannel, FlutterChannel.stable);
      expect(version.type, VersionType.release);
    });

    test('parse method - custom version', () {
      final version = FlutterVersion.parse('custom_123');
      expect(version.name, 'custom_123');
      expect(version.releaseChannel, isNull);
      expect(version.type, VersionType.custom);
    });

    test('parse method - commit version', () {
      final version = FlutterVersion.parse(TestVersions.validCommit);
      expect(version.name, TestVersions.validCommit);
      expect(version.releaseChannel, isNull);
      expect(version.type, VersionType.unknownRef);
    });

    test('parse method - channel version', () {
      final version = FlutterVersion.parse('stable');
      expect(version.name, 'stable');
      expect(version.releaseChannel, isNull);
      expect(version.type, VersionType.channel);
    });

    test('parse method - invalid version format', () {
      expect(
        () => FlutterVersion.parse('1.0.0@invalid'),
        throwsFormatException,
      );
    });

    test('version getter', () {
      final version = FlutterVersion.release('1.0.0@stable');
      expect(version.version, '1.0.0');
    });

    test('isMaster getter', () {
      final version1 = FlutterVersion.channel('master');
      expect(version1.isMain, isTrue);

      final version2 = FlutterVersion.channel('stable');
      expect(version2.isMain, isFalse);
    });

    test('isChannel getter', () {
      final version = FlutterVersion.channel('stable');
      expect(version.isChannel, isTrue);
    });

    test('isRelease getter', () {
      final version = FlutterVersion.release('1.0.0');
      expect(version.isRelease, isTrue);
    });

    test('isCommit getter', () {
      final version = FlutterVersion.gitReference('abc123');
      expect(version.isUnknownRef, isTrue);
    });

    test('isCustom getter', () {
      final version = FlutterVersion.custom('custom_123');
      expect(version.isCustom, isTrue);
    });

    test('printFriendlyName getter - channel version', () {
      final version = FlutterVersion.channel('stable');
      expect(version.printFriendlyName, 'Channel: Stable');
    });

    test('printFriendlyName getter - commit version', () {
      final version = FlutterVersion.gitReference('abc123');
      expect(version.printFriendlyName, 'Commit : abc123');
    });

    test('printFriendlyName getter - release version', () {
      final version = FlutterVersion.release('1.0.0');
      expect(version.printFriendlyName, 'SDK Version : 1.0.0');
    });

    test('compareTo method', () {
      final version1 = FlutterVersion.release('1.0.0');
      final version2 = FlutterVersion.release('2.0.0');
      expect(version1.compareTo(version2), lessThan(0));
      expect(version2.compareTo(version1), greaterThan(0));
      expect(version1.compareTo(version1), equals(0));
    });

    group('Fork functionality', () {
      test('parse method - fork with channel version', () {
        final version = FlutterVersion.parse('myfork/stable');
        expect(version.fork, 'myfork');
        expect(version.fromFork, isTrue);
        expect(version.type, VersionType.channel);
      });

      test('parse method - fork with release version', () {
        final version = FlutterVersion.parse('myfork/2.10.0');
        expect(version.fork, 'myfork');
        expect(version.fromFork, isTrue);
        expect(version.type, VersionType.release);
        expect(version.version, '2.10.0');
      });

      test('parse method - fork with commit version', () {
        final version = FlutterVersion.parse(
          'myfork/${TestVersions.validCommit}',
        );
        expect(version.fork, 'myfork');
        expect(version.fromFork, isTrue);
        expect(version.type, VersionType.unknownRef);
      });

      test('parse method - fork with release version and channel', () {
        final version = FlutterVersion.parse('myfork/2.10.0@beta');
        expect(version.fork, 'myfork');
        expect(version.fromFork, isTrue);
        expect(version.type, VersionType.release);
        expect(version.releaseChannel, FlutterChannel.beta);
        expect(version.version, '2.10.0');
      });

      test('copyWith preserves fork information', () {
        final version = FlutterVersion.parse('myfork/2.10.0');
        final copied = version.copyWith(name: '2.11.0');

        expect(copied.name, '2.11.0');
        expect(copied.fork, 'myfork');
        expect(copied.fromFork, isTrue);
      });
    });
  });
}
