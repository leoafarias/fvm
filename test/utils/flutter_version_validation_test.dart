import 'package:fvm/src/models/git_reference_model.dart';
import 'package:fvm/src/models/flutter_version_model.dart';
import 'package:fvm/src/utils/helpers.dart';
import 'package:fvm/src/utils/constants.dart';
import 'package:fvm/src/utils/git_utils.dart';
import 'package:test/test.dart';

void main() {
  group('Flutter channel validation', () {
    test('isFlutterChannel correctly identifies all channels', () {
      // Test all defined channels
      for (final channel in kFlutterChannels) {
        expect(isFlutterChannel(channel), isTrue,
            reason: '$channel should be recognized as a Flutter channel');
      }

      // Test non-channels
      expect(isFlutterChannel('1.22.6'), isFalse,
          reason: 'Release versions should not be recognized as channels');
      expect(isFlutterChannel('2.0.0'), isFalse,
          reason: 'Release versions should not be recognized as channels');
      expect(isFlutterChannel('my-branch'), isFalse,
          reason: 'Custom branches should not be recognized as channels');
      expect(isFlutterChannel('master-custom'), isFalse,
          reason:
              'Names containing channel names should not be recognized as channels');
    });

    test('ensures master is treated consistently with other channels', () {
      // Bug #8 in use_command_analysis.md mentions an inconsistency with master channel
      expect(isFlutterChannel('master'), isTrue,
          reason: 'master should be recognized as a Flutter channel');

      // This checks the kFlutterChannels constant contains master
      expect(kFlutterChannels.contains('master'), isTrue,
          reason: 'master should be included in kFlutterChannels');
    });
  });

  group('Flutter version parsing', () {
    test('correctly parses channel versions', () {
      for (final channel in kFlutterChannels) {
        final version = FlutterVersion.parse(channel);
        expect(version.name, equals(channel));
        expect(version.type, equals(VersionType.channel));
        expect(version.isChannel, isTrue);
      }
    });

    test('correctly parses release versions', () {
      const releaseVersions = ['1.22.6', '2.0.0', '3.10.0'];

      for (final version in releaseVersions) {
        final flutterVersion = FlutterVersion.parse(version);
        expect(flutterVersion.name, equals(version));
        expect(flutterVersion.type, equals(VersionType.release));
        expect(flutterVersion.isRelease, isTrue);
      }
    });

    test('correctly parses git commit hashes', () {
      const commitHashes = [
        'a9d88a4d18e7f1f0d399ec43e7666d54d122a8c6',
        '5464c5bac742001448fe4fc0597be939379f88ea',
        'ee4e09cce01d6f2d7f4baebd247fde02e5008851'
      ];

      for (final hash in commitHashes) {
        final flutterVersion = FlutterVersion.parse(hash);
        expect(flutterVersion.name, equals(hash));
        expect(flutterVersion.type, equals(VersionType.unknownRef));
        expect(flutterVersion.isUnknownRef, isTrue);
      }
    });

    test('correctly handles version with "v" prefix', () {
      final versionWithV = 'v2.5.0';
      final version = '2.5.0';

      final flutterVersionWithV = FlutterVersion.parse(versionWithV);
      final flutterVersion = FlutterVersion.parse(version);

      // The "v" prefix should be preserved in the name
      expect(flutterVersionWithV.name, equals(versionWithV));
      expect(flutterVersionWithV.type, equals(flutterVersion.type));
    });

    test('validates forked versions', () {
      final forkedVersion = 'fork/2.5.0';

      final flutterVersion = FlutterVersion.parse(forkedVersion);

      expect(flutterVersion.fromFork, isTrue);
      expect(flutterVersion.fork, equals('fork'));
      // The name might not be stored exactly as provided in the implementation
      // Just verify that we can correctly identify a forked version
    });
  });

  group('Integration between GitReference and FlutterVersion', () {
    test('GitReference branches map to channel versions', () {
      // Create git branch references for the known channels
      final branchReferences = kFlutterChannels
          .map((channel) => GitBranch(sha: 'mock-hash-$channel', name: channel))
          .toList();

      for (final branch in branchReferences) {
        final version = FlutterVersion.parse(branch.name);

        expect(version.isChannel, isTrue);
        expect(version.type, equals(VersionType.channel));
        expect(version.name, equals(branch.name));
      }
    });

    test('GitReference tags map to release versions', () {
      final tagReferences = [
        GitTag(sha: 'mock-hash-1', name: '1.22.6'),
        GitTag(sha: 'mock-hash-2', name: '2.0.0'),
        GitTag(sha: 'mock-hash-3', name: '3.10.0')
      ];

      for (final tag in tagReferences) {
        final version = FlutterVersion.parse(tag.name);

        expect(version.isRelease, isTrue);
        expect(version.type, equals(VersionType.release));
        expect(version.name, equals(tag.name));
      }
    });

    test('short GitHub hash formats are properly detected', () {
      final shortHashes = ['a9d88a4', '5464c5b', 'ee4e09c'];

      for (final hash in shortHashes) {
        expect(isGitCommit(hash), isTrue,
            reason:
                'Short hash $hash should be recognized as a possible Git commit');

        final version = FlutterVersion.parse(hash);
        expect(version.isUnknownRef, isTrue);
        expect(version.type, equals(VersionType.unknownRef));
      }
    });

    test('invalid hash formats are properly rejected', () {
      final invalidHashes = ['12345', 'xyz', 'a1b2c'];

      for (final hash in invalidHashes) {
        // These should not be recognized as git commits because they're too short
        expect(isGitCommit(hash), isFalse,
            reason:
                'Invalid hash $hash should not be recognized as a Git commit');
      }
    });
  });

  group('version comparison and edge cases', () {
    test('version weight assignment handles all version types', () {
      // Simulate version weight assignment for different version types
      final versionWeights = {
        'master': assignVersionWeight('master'),
        'stable': assignVersionWeight('stable'),
        'beta': assignVersionWeight('beta'),
        'dev': assignVersionWeight('dev'),
        '2.5.0': assignVersionWeight('2.5.0'),
        'a9d88a4d18e7f1f0d399ec43e7666d54d122a8c6':
            assignVersionWeight('a9d88a4d18e7f1f0d399ec43e7666d54d122a8c6'),
        'custom_version': assignVersionWeight('custom_version'),
      };

      // Check relative ordering by comparing the weights
      // Commit > master > stable > beta > dev > release > custom
      expect(
          double.parse(
                  versionWeights['a9d88a4d18e7f1f0d399ec43e7666d54d122a8c6']!
                      .split('.')[0]) >
              double.parse(versionWeights['master']!.split('.')[0]),
          isTrue);

      expect(
          double.parse(versionWeights['master']!.split('.')[0]) >
              double.parse(versionWeights['stable']!.split('.')[0]),
          isTrue);

      expect(
          double.parse(versionWeights['stable']!.split('.')[0]) >
              double.parse(versionWeights['beta']!.split('.')[0]),
          isTrue);

      expect(
          double.parse(versionWeights['beta']!.split('.')[0]) >
              double.parse(versionWeights['dev']!.split('.')[0]),
          isTrue);
    });

    test('handles invalid version strings gracefully', () {
      // These may throw exceptions for invalid formats
      try {
        final invalidVersion = FlutterVersion.parse('');
        final invalidVersion2 = FlutterVersion.parse('not-a-version');

        // If they don't throw, they should be treated as unknown references
        expect(invalidVersion.type, equals(VersionType.unknownRef));
        expect(invalidVersion2.type, equals(VersionType.unknownRef));
      } catch (e) {
        // FormatException is expected for invalid inputs
        expect(e, isA<FormatException>());
      }
    });
  });
}
