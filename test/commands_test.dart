@Timeout(Duration(minutes: 5))
import 'package:fvm/src/models/valid_version_model.dart';
import 'package:fvm/src/services/cache_service.dart';
import 'package:fvm/src/services/context.dart';
import 'package:fvm/src/services/project_service.dart';
import 'package:fvm/src/utils/helpers.dart';
import 'package:io/io.dart';
import 'package:path/path.dart';
import 'package:test/test.dart';

import 'testing_utils.dart';

final runner = TestFvmCommandRunner();

void main() {
  groupWithContext('Channel Workflow:', () {
    final runner = TestFvmCommandRunner();

    testWithContext('Install Channel', () async {
      // await testContextWrapper(contextKey, () async {
      await runner.run('fvm install $channel');

      final existingChannel = await getBranch(channel);

      final cacheVersion =
          await CacheService.getVersionCache(ValidVersion(channel));

      expect(cacheVersion != null, true, reason: 'Install does not exist');

      expect(existingChannel, channel);
    });

    testWithContext('List Channel', () async {
      final exitCode = await runner.run('fvm list');

      expect(exitCode, ExitCode.success.code);
    });

    testWithContext('Use Channel', () async {
      try {
        // Run foce to test within fvm
        await runner.run('fvm use $channel --force');

        final project = await ProjectService.findAncestor();

        final linkExists = project.cacheVersionSymlink.existsSync();

        final targetBin = project.cacheVersionSymlink.targetSync();

        final channelBin = versionCacheDir(channel);

        expect(targetBin == channelBin.path, true);
        expect(linkExists, true);
      } on Exception catch (e) {
        fail('Exception thrown, $e');
      }
    });

    testWithContext('Use Flutter SDK globally', () async {
      try {
        await runner.run('fvm global $channel');
        final linkExists = ctx.globalCacheLink.existsSync();

        final targetVersion = basename(await ctx.globalCacheLink.target());

        expect(targetVersion == channel, true);
        expect(linkExists, true);
      } on Exception catch (e) {
        fail('Exception thrown, $e');
      }
    });

    testWithContext('Remove Channel Command', () async {
      try {
        await runner.run('fvm remove $channel');
      } on Exception catch (e) {
        fail('Exception thrown, $e');
      }
    });
  });

  groupWithContext('Release Workflow', () {
    testWithContext('Install Release', () async {
      await runner.run('fvm install $release');
      final valid = ValidVersion(release);
      final existingRelease = await getTag(valid.name);

      final cacheVersion = await CacheService.getVersionCache(valid);

      expect(cacheVersion != null, true, reason: 'Install does not exist');

      expect(existingRelease, valid.name);

      // expect(true, true);
    });

    testWithContext('Use Release', () async {
      try {
        await runner.run('fvm use $release --force');

        final project = await ProjectService.findAncestor();
        final linkExists = project.cacheVersionSymlink.existsSync();

        final targetPath = project.cacheVersionSymlink.targetSync();
        final valid = ValidVersion(release);
        final versionDir = versionCacheDir(valid.name);

        expect(targetPath == versionDir.path, true);
        expect(linkExists, true);
      } on Exception catch (e) {
        fail('Exception thrown, $e');
      }
    });

    testWithContext('List Command', () async {
      try {
        await runner.run('fvm list');
      } on Exception catch (e) {
        fail('Exception thrown, $e');
      }

      expect(true, true);
    });

    testWithContext('Remove Release', () async {
      await runner.run('fvm remove $release');
    });
  });

  groupWithContext('Commands', () {
    test('Get Version', () async {
      expect(
        await runner.run('fvm --version'),
        ExitCode.success.code,
      );

      expect(
        await runner.run('fvm -v'),
        ExitCode.success.code,
      );
    });

    testWithContext('Doctor Command', () async {
      expect(
        await runner.run('fvm doctor'),
        ExitCode.success.code,
      );
    });

    testWithContext('Flavor Command', () async {
      await runner.run('fvm install $channel');

      expect(
        await runner.run(
          'fvm use $channel --flavor production --force',
        ),
        ExitCode.success.code,
      );

      expect(
        await runner.run('fvm flavor production'),
        ExitCode.success.code,
      );
    });
  });
}
