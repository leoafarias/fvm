@Timeout(Duration(minutes: 5))
import 'package:fvm/fvm.dart';

import 'package:fvm/src/runner.dart';

import 'package:fvm/src/flutter_tools/flutter_helpers.dart';

import 'package:fvm/src/flutter_tools/git_tools.dart';

import 'package:fvm/src/local_versions/local_version.repo.dart';
import 'package:test/test.dart';
import 'package:path/path.dart' as path;
import 'package:fvm/constants.dart';

import 'test_helpers.dart';

final testPath = '$kFvmHome/test_path';

void main() {
  setUpAll(fvmSetUpAll);
  tearDownAll(fvmTearDownAll);
  group('Channel Workflow', () {
    test('Install Channel', () async {
      try {
        await fvmRunner(['install', channel, '--verbose', '--skip-setup']);
        final existingChannel = await gitGetVersion(channel);
        final correct =
            await LocalVersionRepo().ensureInstalledCorrectly(channel);

        final installExists = await LocalVersionRepo().isInstalled(channel);

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
        // Run foce to test within fvm
        //TODO: Create flutter project for test
        await fvmRunner(['use', channel, '--force', '--verbose']);
        final project = await FlutterProjectRepo().findOne();
        final linkExists = project.sdkSymlink.existsSync();

        final targetBin = project.sdkSymlink.targetSync();

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

    test('Remove Channel Command', () async {
      try {
        await fvmRunner(['remove', channel, '--verbose']);
      } on Exception catch (e) {
        fail('Exception thrown, $e');
      }

      expect(true, true);
    });
  });
  group('Release Workflow', () {
    test('Install Release', () async {
      try {
        await fvmRunner(['install', release, '--verbose', '--skip-setup']);
        final version = await inferFlutterVersion(release);
        final existingRelease = await gitGetVersion(version);

        final correct =
            await LocalVersionRepo().ensureInstalledCorrectly(version);

        final installExists = await LocalVersionRepo().isInstalled(version);

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
        // TODO: Use force to run within fvm need to create example project
        await fvmRunner(['use', release, '--force', '--verbose']);
        final project = await FlutterProjectRepo().findOne();
        final linkExists = project.sdkSymlink.existsSync();

        final targetBin = project.sdkSymlink.targetSync();
        final version = await inferFlutterVersion(release);
        final releaseBin = path.join(kVersionsDir.path, version);

        expect(targetBin == releaseBin, true);
        expect(linkExists, true);
      } on Exception catch (e) {
        fail('Exception thrown, $e');
      }
    });

    test('List Releases', () async {
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

  group('FVM Version Command', () {
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
