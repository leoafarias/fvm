@Timeout(Duration(minutes: 5))
import 'package:fvm/src/models/valid_version_model.dart';
import 'package:fvm/src/runner.dart';
import 'package:fvm/src/services/cache_service.dart';
import 'package:fvm/src/services/git_tools.dart';
import 'package:fvm/src/services/project_service.dart';
import 'package:fvm/src/utils/helpers.dart';
import 'package:fvm/src/workflows/ensure_cache.workflow.dart';
import 'package:io/io.dart';
import 'package:test/test.dart';

import 'testing_utils.dart';

void main() {
  groupWithContext('Channel Workflow:', () {
    test('Install Channel', () async {
      // await testContextWrapper(contextKey, () async {
      await FvmCommandRunner().run([
        'install',
        channel,
        '--verbose',
        '--skip-setup',
      ]);

      final existingChannel = await GitTools.getBranch(channel);

      final cacheVersion =
          await CacheService.getVersionCache(ValidVersion(channel));

      expect(cacheVersion != null, true, reason: 'Install does not exist');

      expect(existingChannel, channel);
    });

    test('List Channel', () async {
      try {
        await FvmCommandRunner().run(['list']);
      } on Exception catch (e) {
        fail('Exception thrown, $e');
      }

      expect(true, true);
    });

    test('Use Channel', () async {
      try {
        // Run foce to test within fvm

        await FvmCommandRunner().run(
          ['use', channel, '--force', '--verbose'],
        );
        final project = await ProjectService.findAncestor();

        final linkExists = project.config.sdkSymlink.existsSync();

        final targetBin = project.config.sdkSymlink.targetSync();

        final channelBin = versionCacheDir(channel);

        expect(targetBin == channelBin.path, true);
        expect(linkExists, true);
      } on Exception catch (e) {
        fail('Exception thrown, $e');
      }
    });

    //TODO: Remove after deprecation period
    // test('Use Flutter SDK globally',  () async {
    //   try {
    //     await FvmCommandRunner().run(['global', channel]);
    //     final linkExists = ctx.globalCacheLink.existsSync();

    //     final targetVersion = basename(await ctx.globalCacheLink.target());

    //     expect(targetVersion == channel, true);
    //     expect(linkExists, true);
    //   } on Exception catch (e) {
    //     fail('Exception thrown, $e');
    //   }
    // });

    test('Remove Channel Command', () async {
      try {
        await FvmCommandRunner()
            .run(['remove', channel, '--verbose', '--force']);
      } on Exception catch (e) {
        fail('Exception thrown, $e');
      }
    });
  });

  groupWithContext('Release Workflow', () {
    test('Install Release', () async {
      try {
        await FvmCommandRunner()
            .run(['install', release, '--verbose', '--skip-setup']);
        final valid = ValidVersion(release);
        final existingRelease = await GitTools.getTag(valid.name);

        final cacheVersion = await CacheService.getVersionCache(valid);

        expect(cacheVersion != null, true, reason: 'Install does not exist');

        expect(existingRelease, valid.name);
      } on Exception catch (e) {
        fail('Exception thrown, $e');
      }

      // expect(true, true);
    });

    test('Use Release', () async {
      try {
        await FvmCommandRunner().run(
          [
            'use',
            release,
            '--force',
            '--verbose',
          ],
        );
        final project = await ProjectService.findAncestor();
        final linkExists = project.config.sdkSymlink.existsSync();

        final targetPath = project.config.sdkSymlink.targetSync();
        final valid = ValidVersion(release);
        final versionDir = versionCacheDir(valid.name);

        expect(targetPath == versionDir.path, true);
        expect(linkExists, true);
      } on Exception catch (e) {
        fail('Exception thrown, $e');
      }
    });

    test('List Command', () async {
      try {
        await FvmCommandRunner().run(['list', '--verbose']);
      } on Exception catch (e) {
        fail('Exception thrown, $e');
      }

      expect(true, true);
    });

    test('Remove Release', () async {
      await FvmCommandRunner().run(
        ['remove', release, '--verbose'],
      );
    });
  });

  groupWithContext('Commands', () {
    test('Get Version', () async {
      expect(
        await FvmCommandRunner().run(['--version']),
        ExitCode.success.code,
      );
    });

    test('Doctor Command', () async {
      expect(
        await FvmCommandRunner().run(['doctor']),
        ExitCode.success.code,
      );
    });

    test('Flavor Command', () async {
      await ensureCacheWorkflow(
        ValidVersion(channel),
        skipConfirmation: true,
      );

      expect(
        await FvmCommandRunner().run([
          'use',
          channel,
          '--flavor',
          'production',
          '--force',
        ]),
        ExitCode.success.code,
      );

      expect(
        await FvmCommandRunner().run(['flavor', 'production']),
        ExitCode.success.code,
      );
    });
  });
}
