@Timeout(Duration(minutes: 5))
import 'package:fvm/fvm.dart';
import 'package:test/test.dart';
import 'package:path/path.dart' as path;
import 'package:fvm/constants.dart';
import 'package:fvm/utils/flutter_tools.dart';

import 'test_helpers.dart';

final testPath = '$fvmHome/test_path';

const channel = 'master';
const release = '1.8.0';

const defaultParams = ['--verbose'];

void main() {
  setUpAll(() async {
    await fvmSetUpAll();
  });
  tearDownAll(() async {
    await fvmTearDownAll();
  });
  group('Channel Flow', () {
    test('Install Channel', () async {
      try {
        await fvmRunner(['install', channel, ...defaultParams]);
        final existingChannel = await flutterSdkVersion(channel);
        final correct = await checkInstalledCorrectly(channel);
        final installedVersions = await flutterListInstalledSdks();

        final installExists = installedVersions.contains(channel);

        expect(installExists, true, reason: 'Install does not exist');
        expect(correct, true, reason: 'Not Installed Correctly');
        expect(existingChannel, channel);
      } on Exception catch (e) {
        fail("Exception thrown, $e");
      }
    });

    test('List Channel', () async {
      try {
        await fvmRunner(['list']);
      } on Exception catch (e) {
        fail("Exception thrown, $e");
      }

      expect(true, true);
    });

    test('Use Channel', () async {
      try {
        await fvmRunner(['use', channel, ...defaultParams]);
        final linkExists = await kLocalFlutterLink.exists();

        final targetBin = await kLocalFlutterLink.target();

        final channelBin = path.join(
          kVersionsDir.path,
          channel,
          'bin',
          'flutter',
        );
        ;

        expect(targetBin == channelBin, true);
        expect(linkExists, true);
      } on Exception catch (e) {
        fail("Exception thrown, $e");
      }
    });

    test('Remove Channel', () async {
      try {
        await fvmRunner(['remove', channel, ...defaultParams]);
      } on Exception catch (e) {
        fail("Exception thrown, $e");
      }

      expect(true, true);
    });
  });
  group('Release Flow', () {
    test('Install Release', () async {
      try {
        await fvmRunner(['install', release, ...defaultParams]);
        final existingRelease = await flutterSdkVersion(release);
        final correct = await checkInstalledCorrectly(release);
        final installedVersions = await flutterListInstalledSdks();

        final installExists = installedVersions.contains(release);

        expect(installExists, true, reason: 'Install does not exist');
        expect(correct, true, reason: 'Not Installed Correctly');
        expect(existingRelease, 'v$release');
      } on Exception catch (e) {
        fail("Exception thrown, $e");
      }

      expect(true, true);
    });

    test('Use Release', () async {
      try {
        await fvmRunner(['use', release, ...defaultParams]);
        final linkExists = await kLocalFlutterLink.exists();

        final targetBin = await kLocalFlutterLink.target();

        final releaseBin =
            path.join(kVersionsDir.path, release, 'bin', 'flutter');

        expect(targetBin == releaseBin, true);
        expect(linkExists, true);
      } on Exception catch (e) {
        fail("Exception thrown, $e");
      }
    });

    test('List Release', () async {
      try {
        await fvmRunner(['list', ...defaultParams]);
      } on Exception catch (e) {
        fail("Exception thrown, $e");
      }

      expect(true, true);
    });

    test('Remove Release', () async {
      try {
        await fvmRunner(['remove', release, ...defaultParams]);
      } on Exception catch (e) {
        fail("Exception thrown, $e");
      }

      expect(true, true);
    });
  });

  group('Config', () {
    test('Set Cache-Path', () async {
      try {
        await fvmRunner(['config', '--cache-path', testPath]);
      } on Exception catch (e) {
        fail("Exception thrown, $e");
      }
      expect(testPath, kVersionsDir.path);
    });

    test('List Config Options', () async {
      try {
        await fvmRunner(['config', '--ls']);
      } on Exception catch (e) {
        fail("Exception thrown, $e");
      }
      expect(true, true);
    });
  });
  group('Flutter Commands', () {
    test('Flutter Exists', () async {
      const flutterArgs = ['build', 'ios', '--debug'];
      try {
        await fvmRunner(['flutter', ...flutterArgs]);
      } on Exception catch (e) {
        fail("Exception thrown, $e");
      }

      expect(true, true);
    });
  });
}
