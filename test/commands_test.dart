@Timeout(Duration(minutes: 5))
import 'dart:io';

import 'package:fvm/src/models/flutter_version_model.dart';
import 'package:fvm/src/services/cache_service.dart';
import 'package:fvm/src/services/project_service.dart';
import 'package:fvm/src/utils/context.dart';
import 'package:io/io.dart';
import 'package:path/path.dart';
import 'package:test/test.dart';

import 'testing_utils.dart';

final runner = TestCommandRunner();

void main() {
  groupWithContext('Channel Workflow:', () {
    final runner = TestCommandRunner();

    testWithContext('Install Channel', () async {
      // await testContextWrapper(contextKey, () async {
      await runner.run('fvm install $channel');

      final cacheVersion =
          CacheService.fromContext.getVersion(FlutterVersion.parse(channel));

      final existingChannel = await getBranch(channel);
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
        await runner.run('fvm use $channel --force --skip-setup');

        final project = ProjectService.fromContext.findAncestor();

        final link = Link(project.localVersionSymlinkPath);

        final linkExists = link.existsSync();

        final targetBin = link.targetSync();

        final channelBin = CacheService.fromContext.getVersionCacheDir(channel);

        expect(targetBin == channelBin.path, true);
        expect(linkExists, true);
      } on Exception catch (e) {
        fail('Exception thrown, $e');
      }
    });

    testWithContext('Use Flutter SDK globally', () async {
      try {
        await runner.run('fvm global $channel');
        final globalLink = Link(ctx.globalCacheLink);
        final linkExists = globalLink.existsSync();

        final targetVersion = basename(await globalLink.target());

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

    testWithContext('Install Release', () async {
      await runner.run('fvm install $release');
      final valid = FlutterVersion.parse(release);
      final existingRelease = await getTag(valid.name);

      final cacheVersion = CacheService.fromContext.getVersion(valid);

      expect(cacheVersion != null, true, reason: 'Install does not exist');

      expect(existingRelease, valid.name);
    });

    testWithContext('Install commit', () async {
      final shortGitHash = 'fb57da5f94';

      await runner.run('fvm install $shortGitHash');
      final validShort = FlutterVersion.parse(shortGitHash);

      final cacheVersionShort = CacheService.fromContext.getVersion(validShort);

      expect(
        cacheVersionShort != null,
        true,
        reason: 'Install short does not exist',
      );
    });

    testWithContext('Use Release', () async {
      final exitCode = await runner.run(
        'fvm use $release --force --skip-setup',
      );

      final project = ProjectService.fromContext.findAncestor();
      final link = Link(project.localVersionSymlinkPath);
      final linkExists = link.existsSync();

      final targetPath = link.targetSync();
      final valid = FlutterVersion.parse(release);
      final versionDir =
          CacheService.fromContext.getVersionCacheDir(valid.name);

      expect(targetPath == versionDir.path, true);
      expect(linkExists, true);
      expect(exitCode, ExitCode.success.code);
    });

    testWithContext('List Command', () async {
      expect(await runner.run('fvm list'), ExitCode.success.code);
    });

    testWithContext('Remove Release', () async {
      expect(await runner.run('fvm remove $release'), ExitCode.success.code);
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
          'fvm use $channel --flavor production --skip-setup',
        ),
        ExitCode.success.code,
      );

      expect(
        await runner.run('fvm use production'),
        ExitCode.success.code,
      );
    });
  });
}
