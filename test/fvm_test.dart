@Timeout(Duration(minutes: 5))
import 'package:fvm/commands/install.dart';
import 'package:fvm/commands/runner.dart';
import 'package:fvm/exceptions.dart';
import 'package:fvm/fvm.dart';
import 'package:fvm/utils/helpers.dart';
import 'package:test/test.dart';
import 'package:path/path.dart' as path;
import 'package:fvm/constants.dart';
import 'package:fvm/utils/flutter_tools.dart';
import 'test_helpers.dart';

final testPath = '$fvmHome/test_path';

const channel = 'master';
const release = '1.8.0';

void main() {
  setUpAll(fvmSetUpAll);
  tearDownAll(fvmTearDownAll);
  group('Channel Flow', () {
    test('Install without version', () async {
      final args = ['install'];
      try {
        final runner = buildRunner();
        runner.addCommand(InstallCommand());
        await runner.run(args);
      } on Exception catch (e) {
        expect(e is ExceptionMissingChannelVersion, true);
      }
    });
    test('Install Channel', () async {
      try {
        await fvmRunner(['install', channel, '--verbose', '--skip-setup']);
        final existingChannel = await flutterSdkVersion(channel);
        final correct = isInstalledCorrectly(channel);
        final installedVersions = flutterListInstalledSdks();

        final installExists = installedVersions.contains(channel);

        expect(installExists, true, reason: 'Install does not exist');
        expect(correct, true, reason: 'Not Installed Correctly');
        expect(existingChannel, channel);
      } on Exception catch (e) {
        fail('Exception thrown, $e');
      }
    });

    test('List Channel', () async {
      try {
        await fvmRunner(['list']);
      } on Exception catch (e) {
        fail('Exception thrown, $e');
      }

      expect(true, true);
    });

    test('Use Channel', () async {
      try {
        await fvmRunner(['use', channel, '--verbose']);
        final linkExists = kProjectFvmSdkSymlink.existsSync();

        final targetBin = kProjectFvmSdkSymlink.targetSync();

        final channelBin = path.join(kVersionsDir.path, channel);

        expect(targetBin == channelBin, true);
        expect(linkExists, true);
      } on Exception catch (e) {
        fail('Exception thrown, $e');
      }
    });

    test('Use Flutter SDK globally', () async {
      try {
        await fvmRunner(['use', channel, '--global']);
        final linkExists = kDefaultFlutterLink.existsSync();

        final targetDir = kDefaultFlutterLink.targetSync();

        final channelDir = path.join(kVersionsDir.path, channel);

        expect(targetDir == channelDir, true);
        expect(linkExists, true);
      } on Exception catch (e) {
        fail('Exception thrown, $e');
      }
    });

    test('Remove Channel', () async {
      try {
        await fvmRunner(['remove', channel, '--verbose']);
      } on Exception catch (e) {
        fail('Exception thrown, $e');
      }

      expect(true, true);
    });
  });
  group('Release Flow', () {
    test('Install Release', () async {
      try {
        await fvmRunner(['install', release, '--verbose', '--skip-setup']);
        final version = await inferFlutterVersion(release);
        final existingRelease = await flutterSdkVersion(version);

        final correct = isInstalledCorrectly(version);
        final installedVersions = flutterListInstalledSdks();

        final installExists = installedVersions.contains(version);

        expect(installExists, true, reason: 'Install does not exist');
        expect(correct, true, reason: 'Not Installed Correctly');
        expect(existingRelease, version);
      } on Exception catch (e) {
        fail('Exception thrown, $e');
      }

      expect(true, true);
    });

    test('Use Release', () async {
      try {
        await fvmRunner(['use', release, '--verbose']);
        final linkExists = kProjectFvmSdkSymlink.existsSync();

        final targetBin = kProjectFvmSdkSymlink.targetSync();
        final version = await inferFlutterVersion(release);
        final releaseBin = path.join(kVersionsDir.path, version);

        expect(targetBin == releaseBin, true);
        expect(linkExists, true);
      } on Exception catch (e) {
        fail('Exception thrown, $e');
      }
    });

    test('List Release', () async {
      try {
        await fvmRunner(['list', '--verbose']);
      } on Exception catch (e) {
        fail('Exception thrown, $e');
      }

      expect(true, true);
    });

    test('Remove Release', () async {
      try {
        await fvmRunner(['remove', release, '--verbose']);
      } on Exception catch (e) {
        fail('Exception thrown, $e');
      }

      expect(true, true);
    });
  });

  group('Config', () {
    test('Set Cache-Path', () async {
      try {
        await fvmRunner(['config', '--cache-path', testPath]);
      } on Exception catch (e) {
        fail('Exception thrown, $e');
      }
      expect(testPath, kVersionsDir.path);
    });

    test('List Config Options', () async {
      try {
        await fvmRunner(['config', '--ls']);
      } on Exception catch (e) {
        fail('Exception thrown, $e');
      }
      expect(true, true);
    });
  });

  group('Utils', () {
    test('Check Version', () async {
      try {
        await fvmRunner(['version']);
      } on Exception catch (e) {
        fail('Exception thrown, $e');
      }
      expect(true, true);
    });
  });
}
