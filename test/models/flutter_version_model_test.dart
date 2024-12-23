import 'package:fvm/src/models/flutter_version_model.dart';
import 'package:test/test.dart';

void main() {
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
        '2.0.0'
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
        '1.3.1'
      ];

      final versionUnsorted = unsortedList.map(FlutterVersion.parse).toList();
      versionUnsorted.sort((a, b) => a.compareTo(b));

      final afterUnsorted =
          versionUnsorted.reversed.map((e) => e.name).toList();

      expect(afterUnsorted, sortedList);
    });
  });

  group('FlutterVersion', () {
    test('fromMap constructor', () {
      final map = {
        'name': 'test',
        'releaseFromChannel': 'stable',
        'type': 'release',
      };
      final version = FlutterVersion.fromMap(map);
      expect(version.name, 'test');
      expect(version.releaseFromChannel, 'stable');
      expect(version.type, VersionType.release);
    });

    test('fromJson constructor', () {
      final json =
          '{"name":"test","releaseFromChannel":"stable","type":"release"}';
      final version = FlutterVersion.fromJson(json);
      expect(version.name, 'test');
      expect(version.releaseFromChannel, 'stable');
      expect(version.type, VersionType.release);
    });

    test('commit constructor', () {
      final version = FlutterVersion.commit('abc123');
      expect(version.name, 'abc123');
      expect(version.releaseFromChannel, isNull);
      expect(version.type, VersionType.commit);
    });

    test('channel constructor', () {
      final version = FlutterVersion.channel('stable');
      expect(version.name, 'stable');
      expect(version.releaseFromChannel, isNull);
      expect(version.type, VersionType.channel);
    });

    test('custom constructor', () {
      final version = FlutterVersion.custom('custom_123');
      expect(version.name, 'custom_123');
      expect(version.releaseFromChannel, isNull);
      expect(version.type, VersionType.custom);
    });

    test('custom constructor', () {
      final version = FlutterVersion.custom('custom_3.7.0@huawei');
      expect(version.name, 'custom_3.7.0@huawei');
      expect(version.releaseFromChannel, isNull);
      expect(version.type, VersionType.custom);
    });

    test('release constructor', () {
      final version =
          FlutterVersion.release('1.0.0', releaseFromChannel: 'stable');
      expect(version.name, '1.0.0');
      expect(version.releaseFromChannel, 'stable');
      expect(version.type, VersionType.release);
    });

    test('parse method - release version', () {
      final version = FlutterVersion.parse('1.0.0');
      expect(version.name, '1.0.0');
      expect(version.releaseFromChannel, isNull);
      expect(version.type, VersionType.release);
    });

    test('parse method - release version with channel', () {
      final version = FlutterVersion.parse('1.0.0@stable');
      expect(version.name, '1.0.0@stable');
      expect(version.releaseFromChannel, 'stable');
      expect(version.type, VersionType.release);
    });

    test('parse method - custom version', () {
      final version = FlutterVersion.parse('custom_123');
      expect(version.name, 'custom_123');
      expect(version.releaseFromChannel, isNull);
      expect(version.type, VersionType.custom);
    });

    test('parse method - custom version', () {
      final version = FlutterVersion.parse('custom_3.6.0@huawei');
      expect(version.name, 'custom_3.6.0@huawei');
      expect(version.releaseFromChannel, isNull);
      expect(version.type, VersionType.custom);
    });

    test('parse method - commit version', () {
      final version = FlutterVersion.parse('f4c74a6ec3');
      expect(version.name, 'f4c74a6ec3');
      expect(version.releaseFromChannel, isNull);
      expect(version.type, VersionType.commit);
    });

    test('parse method - channel version', () {
      final version = FlutterVersion.parse('stable');
      expect(version.name, 'stable');
      expect(version.releaseFromChannel, isNull);
      expect(version.type, VersionType.channel);
    });

    test('parse method - invalid version format', () {
      expect(
          () => FlutterVersion.parse('1.0.0@invalid'), throwsFormatException);
    });

    test('version getter', () {
      final version = FlutterVersion.release('1.0.0@stable');
      expect(version.version, '1.0.0');
    });

    test('isMaster getter', () {
      final version1 = FlutterVersion.channel('master');
      expect(version1.isMaster, isTrue);

      final version2 = FlutterVersion.channel('stable');
      expect(version2.isMaster, isFalse);
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
      final version = FlutterVersion.commit('abc123');
      expect(version.isCommit, isTrue);
    });

    test('isCustom getter', () {
      final version = FlutterVersion.custom('custom_123');
      expect(version.isCustom, isTrue);
    });


    test('isCustom getter', () {
      final version = FlutterVersion.custom('custom_3.22.0@huawei');
      expect(version.isCustom, isTrue);
    });

    test('printFriendlyName getter - channel version', () {
      final version = FlutterVersion.channel('stable');
      expect(version.printFriendlyName, 'Channel: Stable');
    });

    test('printFriendlyName getter - commit version', () {
      final version = FlutterVersion.commit('abc123');
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
  });
}
