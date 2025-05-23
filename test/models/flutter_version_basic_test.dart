import 'package:fvm/src/models/flutter_version_model.dart';
import 'package:fvm/src/utils/helpers.dart';
import 'package:fvm/src/utils/constants.dart';
import 'package:test/test.dart';

void main() {
  group('FlutterVersion basic validation', () {
    test('can parse channel versions correctly', () {
      // Test all channels defined in constants
      for (final channel in kFlutterChannels) {
        final version = FlutterVersion.parse(channel);

        // Validate basic properties
        expect(version.name, equals(channel));
        expect(version.isChannel, isTrue);
        expect(version.isRelease, isFalse);
        expect(version.isCustom, isFalse);
        expect(version.isUnknownRef, isFalse);
        expect(version.fromFork, isFalse);
      }
    });

    test('can parse semver release versions correctly', () {
      final releaseVersions = ['1.22.6', '2.0.0', '3.10.0'];

      for (final version in releaseVersions) {
        final flutterVersion = FlutterVersion.parse(version);

        expect(flutterVersion.name, equals(version));
        expect(flutterVersion.isRelease, isTrue);
        expect(flutterVersion.isChannel, isFalse);
        expect(flutterVersion.isCustom, isFalse);
        expect(flutterVersion.isUnknownRef, isFalse);
        expect(flutterVersion.fromFork, isFalse);
      }
    });

    test('consistent handling of master channel', () {
      // Bug #8 in use_command_analysis.md mentions an inconsistency with master channel
      expect(isFlutterChannel('master'), isTrue,
          reason: 'master should be recognized as a Flutter channel');

      final masterVersion = FlutterVersion.parse('master');
      expect(masterVersion.isChannel, isTrue);

      // Check the channel version type
      expect(masterVersion.type, equals(VersionType.channel));
    });

    test('handles versions with v prefix', () {
      final withV = FlutterVersion.parse('v2.5.0');
      final withoutV = FlutterVersion.parse('2.5.0');

      // Both should be considered release versions
      expect(withV.isRelease, isTrue);
      expect(withoutV.isRelease, isTrue);

      // The name is preserved as provided
      expect(withV.name, equals('v2.5.0'));
      expect(withoutV.name, equals('2.5.0'));

      // The version property might handle prefixes differently
      // Let's just test that both are valid versions
      expect(withV.version, isNotEmpty);
      expect(withoutV.version, isNotEmpty);
    });

    test('handles basic forked versions', () {
      final forkedVersion = FlutterVersion.parse('fork/2.5.0');

      expect(forkedVersion.fromFork, isTrue);
      expect(forkedVersion.fork, equals('fork'));

      // Test that version exists but don't make assumptions about format
      expect(forkedVersion.version, isNotEmpty);

      // It should be identified as a release version
      expect(forkedVersion.isRelease, isTrue);
    });

    test('properly identifies git commit-like strings', () {
      final commitStr = 'a9d88a4d18e7f1f0d399ec43e7666d54d122a8c6';
      final commitVersion = FlutterVersion.parse(commitStr);

      expect(commitVersion.isUnknownRef, isTrue);
      expect(commitVersion.isChannel, isFalse);
      expect(commitVersion.isRelease, isFalse);
      expect(commitVersion.name, equals(commitStr));
    });
  });
}
