@Timeout(Duration(minutes: 5))
import 'package:fvm/fvm.dart';
import 'package:fvm/src/flutter_tools/flutter_tools.dart';

import 'package:fvm/src/runner.dart';

import 'package:fvm/src/flutter_tools/git_tools.dart';

import 'package:fvm/src/services/cache_service.dart';
import 'package:fvm/src/services/flutter_app_service.dart';
import 'package:test/test.dart';
import 'package:path/path.dart' as path;
import 'package:fvm/constants.dart';

import 'test_helpers.dart';

final testPath = '$kFvmHome/test_path';

final fvmRunner = FvmCommandRunner();
void main() {
  setUpAll(fvmSetUpAll);
  tearDownAll(fvmTearDownAll);
  group('Channel Workflow:', () {
    test('Install Channel', () async {
      try {
        await fvmRunner.run(['install', channel, '--verbose', '--skip-setup']);
        final existingChannel = await gitGetVersion(channel);

        final cacheVersion = await CacheService.isVersionCached(channel);

        expect(cacheVersion != null, true, reason: 'Install does not exist');

        expect(existingChannel, channel);
      } on Exception catch (e) {
        fail('Exception thrown, $e');
      }
    });

    test('List Channel', () async {
      try {
        await fvmRunner.run(['list']);
      } on Exception catch (e) {
        fail('Exception thrown, $e');
      }

      expect(true, true);
    });

    test('Use Channel', () async {
      try {
        // Run foce to test within fvm

        //TODO: Create flutter project for test
        await fvmRunner.run(['use', channel, '--force', '--verbose']);
        final project = await FlutterAppService.findAncestor();
        if (project == null) {
          fail('Not running on a flutter project');
        }
        final linkExists = project.config.sdkSymlink.existsSync();

        final targetBin = project.config.sdkSymlink.targetSync();

        final channelBin = path.join(kVersionsDir.path, channel);

        expect(targetBin == channelBin, true);
        expect(linkExists, true);
      } on Exception catch (e) {
        fail('Exception thrown, $e');
      }
    });

    test('Use Flutter SDK globally', () async {
      try {
        await fvmRunner.run(['use', channel, '--global']);
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
        await fvmRunner.run(['remove', channel, '--verbose']);
      } on Exception catch (e) {
        fail('Exception thrown, $e');
      }

      expect(true, true);
    });
  });
  group('Release Workflow', () {
    test('Install Release', () async {
      try {
        await fvmRunner.run(['install', release, '--verbose', '--skip-setup']);
        final version = await FlutterTools.inferVersion(release);
        final existingRelease = await gitGetVersion(version);

        final cacheVersion = await CacheService.isVersionCached(version);

        expect(cacheVersion != null, true, reason: 'Install does not exist');

        expect(existingRelease, version);
      } on Exception catch (e) {
        fail('Exception thrown, $e');
      }

      expect(true, true);
    });

    test('Use Release', () async {
      try {
        // TODO: Use force to run within fvm need to create example project
        await fvmRunner.run(['use', release, '--force', '--verbose']);
        final project = await FlutterAppService.findAncestor();
        final linkExists = project.config.sdkSymlink.existsSync();

        final targetBin = project.config.sdkSymlink.targetSync();
        final version = await FlutterTools.inferVersion(release);
        final releaseBin = path.join(kVersionsDir.path, version);

        expect(targetBin == releaseBin, true);
        expect(linkExists, true);
      } on Exception catch (e) {
        fail('Exception thrown, $e');
      }
    });

    test('List Releases', () async {
      try {
        await fvmRunner.run(['list', '--verbose']);
      } on Exception catch (e) {
        fail('Exception thrown, $e');
      }

      expect(true, true);
    });

    test('Remove Release', () async {
      try {
        await fvmRunner.run(['remove', release, '--verbose']);
      } on Exception catch (e) {
        fail('Exception thrown, $e');
      }

      expect(true, true);
    });
  });

  group('FVM Version Command', () {
    test('Check Version', () async {
      try {
        await fvmRunner.run(['--version']);
      } on Exception catch (e) {
        fail('Exception thrown, $e');
      }
      expect(true, true);
    });
  });
}
