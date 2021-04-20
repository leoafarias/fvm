@Timeout(Duration(minutes: 5))
import 'package:fvm/src/models/valid_version_model.dart';
import 'package:fvm/src/runner.dart';
import 'package:fvm/src/services/cache_service.dart';
import 'package:fvm/src/services/context.dart';
import 'package:fvm/src/services/flutter_tools.dart';
import 'package:fvm/src/services/git_tools.dart';
import 'package:fvm/src/services/project_service.dart';
import 'package:fvm/src/utils/helpers.dart';
import 'package:fvm/src/workflows/ensure_cache.workflow.dart';
import 'package:io/io.dart';
import 'package:path/path.dart';
import 'package:test/test.dart';

import 'test_utils.dart';

const key = 'commands_test';
void main() {
  group('Channel Workflow:', () {
    tearDownAll(() {
      final testDir = getFvmTestDir(key);
      if (testDir.existsSync()) {
        testDir.deleteSync(recursive: true);
      }
    });

    testWithContext('Install Channel', key, () async {
      // await testContextWrapper(contextKey, () async {
      await FvmCommandRunner().run([
        'install',
        channel,
        '--verbose',
        '--skip-setup',
      ]);

      final existingChannel = await GitTools.getBranchOrTag(channel);

      final cacheVersion =
          await CacheService.isVersionCached(ValidVersion(channel));

      expect(cacheVersion != null, true, reason: 'Install does not exist');

      expect(existingChannel, channel);
      // });
    });

    testWithContext('List Channel', key, () async {
      try {
        await FvmCommandRunner().run(['list']);
      } on Exception catch (e) {
        fail('Exception thrown, $e');
      }

      expect(true, true);
    });

    testWithContext('Use Channel', key, () async {
      try {
        // Run foce to test within fvm

        await FvmCommandRunner().run(['use', channel, '--force', '--verbose']);
        final project = await ProjectService.findAncestor();
        if (project == null) {
          fail('Not running on a flutter project');
        }
        final linkExists = project.config.sdkSymlink.existsSync();

        final targetBin = project.config.sdkSymlink.targetSync();

        final channelBin = versionCacheDir(channel);

        expect(targetBin == channelBin.path, true);
        expect(linkExists, true);
      } on Exception catch (e) {
        fail('Exception thrown, $e');
      }
    });

    testWithContext('Use Flutter SDK globally', key, () async {
      try {
        await FvmCommandRunner().run(['global', channel]);
        final linkExists = ctx.globalCacheLink.existsSync();

        final targetVersion = basename(await ctx.globalCacheLink.target());

        expect(targetVersion == channel, true);
        expect(linkExists, true);
      } on Exception catch (e) {
        fail('Exception thrown, $e');
      }
    });

    testWithContext(key, 'Remove Channel Command', () async {
      try {
        await FvmCommandRunner()
            .run(['remove', channel, '--verbose', '--force']);
      } on Exception catch (e) {
        fail('Exception thrown, $e');
      }
    });
  });
  group('Release Workflow', () {
    testWithContext('Install Release', key, () async {
      try {
        await FvmCommandRunner()
            .run(['install', release, '--verbose', '--skip-setup']);
        final valid = await FlutterTools.inferValidVersion(release);
        final existingRelease = await GitTools.getBranchOrTag(valid.name);

        final cacheVersion = await CacheService.isVersionCached(valid);

        expect(cacheVersion != null, true, reason: 'Install does not exist');

        expect(existingRelease, valid.name);
      } on Exception catch (e) {
        fail('Exception thrown, $e');
      }

      // expect(true, true);
    });

    testWithContext('Use Release', key, () async {
      try {
        await FvmCommandRunner().run(
          ['use', release, '--force', '--verbose'],
        );
        final project = await ProjectService.findAncestor();
        final linkExists = project.config.sdkSymlink.existsSync();

        final targetPath = project.config.sdkSymlink.targetSync();
        final valid = await FlutterTools.inferValidVersion(release);
        final versionDir = versionCacheDir(valid.name);

        expect(targetPath == versionDir.path, true);
        expect(linkExists, true);
      } on Exception catch (e) {
        fail('Exception thrown, $e');
      }
    });

    testWithContext('List Command', key, () async {
      try {
        await FvmCommandRunner().run(['list', '--verbose']);
      } on Exception catch (e) {
        fail('Exception thrown, $e');
      }

      expect(true, true);
    });

    testWithContext('Remove Release', key, () async {
      await FvmCommandRunner().run(
        ['remove', release, '--verbose'],
      );
    });
  });

  group('Commands', () {
    testWithContext(key, 'Get Version', () async {
      expect(
        await FvmCommandRunner().run(['--version']),
        ExitCode.success.code,
      );
    });

    testWithContext('Doctor Command', key, () async {
      expect(
        await FvmCommandRunner().run(['doctor']),
        ExitCode.success.code,
      );
    });

    testWithContext('Env Command', key, () async {
      await ensureCacheWorkflow(
        ValidVersion(channel),
        skipConfirmation: true,
      );

      expect(
        await FvmCommandRunner()
            .run(['use', channel, '--env', 'production', '--force']),
        ExitCode.success.code,
      );

      expect(
        await FvmCommandRunner().run(['env', 'production']),
        ExitCode.success.code,
      );
    });
  });
}
