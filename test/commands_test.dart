@Timeout(Duration(minutes: 5))
import 'package:fvm/fvm.dart';
import 'package:fvm/src/models/valid_version_model.dart';
import 'package:fvm/src/services/flutter_tools.dart';

import 'package:fvm/src/runner.dart';

import 'package:fvm/src/services/git_tools.dart';

import 'package:fvm/src/services/cache_service.dart';
import 'package:fvm/src/services/flutter_app_service.dart';
import 'package:fvm/src/workflows/ensure_cache.workflow.dart';
import 'package:test/test.dart';
import 'package:path/path.dart' as path;
import 'package:fvm/constants.dart';

import 'test_helpers.dart';

final testPath = '$kFvmHome/test_path';

final fvmRunner = FvmCommandRunner();
void main() {
  // setUpAll(fvmSetUpAll);
  // tearDownAll(fvmTearDownAll);
  group('Channel Workflow:', () {
    test('Install Channel', () async {
      try {
        await fvmRunner.run(['install', channel, '--verbose', '--skip-setup']);
        final existingChannel = await GitTools.getBranchOrTag(channel);

        final cacheVersion = await CacheService.isVersionCached(
          ValidVersion(channel),
        );

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

        await fvmRunner.run(['use', channel, '--force', '--verbose']);
        final project = await FlutterAppService.findAncestor();
        if (project == null) {
          fail('Not running on a flutter project');
        }
        final linkExists = project.config.sdkSymlink.existsSync();

        final targetBin = project.config.sdkSymlink.targetSync();

        final channelBin = path.join(kFvmCacheDir.path, channel);

        expect(targetBin == channelBin, true);
        expect(linkExists, true);
      } on Exception catch (e) {
        fail('Exception thrown, $e');
      }
    });

    test('Use Flutter SDK globally', () async {
      try {
        await fvmRunner.run(['global', channel]);
        final linkExists = kGlobalFlutterLink.existsSync();

        final targetDir = kGlobalFlutterLink.targetSync();

        final channelDir = path.join(kFvmCacheDir.path, channel);

        final globalConfigured = await CacheService.isGlobalConfigured();

        expect(targetDir == channelDir, true);
        expect(linkExists, true);
        expect(globalConfigured, true);
      } on Exception catch (e) {
        fail('Exception thrown, $e');
      }
    });

    test('Remove Channel Command', () async {
      try {
        await fvmRunner.run(['remove', channel, '--verbose', '--force']);
      } on Exception catch (e) {
        fail('Exception thrown, $e');
      }
    });
  });
  group('Release Workflow', () {
    test('Install Release', () async {
      try {
        await fvmRunner.run(['install', release, '--verbose', '--skip-setup']);
        final valid = await FlutterTools.inferVersion(release);
        final existingRelease = await GitTools.getBranchOrTag(valid.version);

        final cacheVersion = await CacheService.isVersionCached(valid);

        expect(cacheVersion != null, true, reason: 'Install does not exist');

        expect(existingRelease, valid.version);
      } on Exception catch (e) {
        fail('Exception thrown, $e');
      }

      // expect(true, true);
    });

    test('Use Release', () async {
      try {
        await fvmRunner.run(['use', release, '--force', '--verbose']);
        final project = await FlutterAppService.findAncestor();
        final linkExists = project.config.sdkSymlink.existsSync();

        final targetBin = project.config.sdkSymlink.targetSync();
        final valid = await FlutterTools.inferVersion(release);
        final releaseBin = path.join(kFvmCacheDir.path, valid.version);

        expect(targetBin == releaseBin, true);
        expect(linkExists, true);
      } on Exception catch (e) {
        fail('Exception thrown, $e');
      }
    });

    test('List Command', () async {
      try {
        await fvmRunner.run(['list', '--verbose']);
      } on Exception catch (e) {
        fail('Exception thrown, $e');
      }

      expect(true, true);
    });

    test('Which Command', () async {
      try {
        await fvmRunner.run(['which', '--verbose']);
      } on Exception catch (e) {
        fail('Exception thrown, $e');
      }

      expect(true, true);
    });

    test('Env Command', () async {
      try {
        await ensureCacheWorkflow(ValidVersion(channel),
            skipConfirmation: true);
        await fvmRunner.run(['use', channel, '--env', 'production', '--force']);
        await fvmRunner.run(['env', 'production']);
      } on Exception catch (e) {
        fail('Exception thrown, $e');
      }
    });

    test('Remove Release', () async {
      try {
        await fvmRunner.run(['remove', release, '--verbose']);
      } on Exception catch (e) {
        fail('Exception thrown, $e');
      }
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
