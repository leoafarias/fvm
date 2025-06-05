import 'dart:io';

import 'package:fvm/src/models/flutter_version_model.dart';
import 'package:fvm/src/services/cache_service.dart';
import 'package:fvm/src/services/git_service.dart';
import 'package:fvm/src/services/project_service.dart';
import 'package:fvm/src/utils/context.dart';
import 'package:io/io.dart';
import 'package:path/path.dart';
import 'package:test/test.dart';

import 'testing_utils.dart';

void main() {
  late TestCommandRunner runner;
  late FvmContext context;

  const channel = 'stable';
  const release = '2.0.0';

  setUp(() {
    runner = TestFactory.commandRunner();
    context = runner.context;
  });

  group('Channel Workflow:', () {
    test('Install Channel', () async {
      await runner.runOrThrow(['fvm', 'install', channel]);

      final cacheVersion = context.get<CacheService>().getVersion(
            FlutterVersion.parse(channel),
          );

      final existingChannel = await context.get<GitService>().getBranch(
            channel,
          );
      expect(cacheVersion != null, true, reason: 'Install does not exist');

      expect(existingChannel, channel);
    });

    test('List Channel', () async {
      final exitCode = await runner.runOrThrow(['fvm', 'list']);

      expect(exitCode, ExitCode.success.code);
    });

    test('Use Channel', () async {
      try {
        // Run force to test within fvm
        await runner
            .runOrThrow(['fvm', 'use', channel, '--force', '--skip-setup']);

        final project = context.get<ProjectService>().findAncestor();

        final link = Link(project.localVersionSymlinkPath);

        final linkExists = link.existsSync();

        final targetBin = link.targetSync();

        final channelBin = context
            .get<CacheService>()
            .getVersionCacheDir(FlutterVersion.parse(channel));

        expect(targetBin == channelBin.path, true);
        expect(linkExists, true);
      } on Exception catch (e) {
        fail('Exception thrown, $e');
      }
    });

    test('Use Flutter SDK globally', () async {
      try {
        await runner.runOrThrow(['fvm', 'global', channel]);
        final globalLink = Link(context.globalCacheLink);
        final linkExists = globalLink.existsSync();

        final targetVersion = basename(await globalLink.target());

        expect(targetVersion == channel, true);
        expect(linkExists, true);
      } on Exception catch (e) {
        fail('Exception thrown, $e');
      }
    });

    test('Remove Channel Command', () async {
      try {
        await runner.runOrThrow(['fvm', 'remove', channel]);
      } on Exception catch (e) {
        fail('Exception thrown, $e');
      }
    });

    test('Install Release', () async {
      await runner.runOrThrow(['fvm', 'install', release]);
      final valid = FlutterVersion.parse(release);
      final existingRelease = await context.get<GitService>().getTag(
            valid.name,
          );

      final cacheVersion = context.get<CacheService>().getVersion(valid);

      expect(cacheVersion != null, true, reason: 'Install does not exist');

      expect(existingRelease, valid.name);
    });

    test('Install commit', () async {
      final shortGitHash = 'fb57da5f94';

      await runner.runOrThrow(['fvm', 'install', shortGitHash]);
      final validShort = FlutterVersion.parse(shortGitHash);

      final cacheVersionShort =
          context.get<CacheService>().getVersion(validShort);

      expect(
        cacheVersionShort != null,
        true,
        reason: 'Install short does not exist',
      );
    });

    test('Use Release', () async {
      final exitCode = await runner.runOrThrow([
        'fvm',
        'use',
        release,
        '--force',
        '--skip-setup',
      ]);

      final project = context.get<ProjectService>().findAncestor();
      final link = Link(project.localVersionSymlinkPath);
      final linkExists = link.existsSync();

      final targetPath = link.targetSync();
      final valid = FlutterVersion.parse(release);
      final versionDir = context.get<CacheService>().getVersionCacheDir(valid);

      expect(targetPath == versionDir.path, true);
      expect(linkExists, true);
      expect(exitCode, ExitCode.success.code);
    });

    test('List Command', () async {
      expect(await runner.runOrThrow(['fvm', 'list']), ExitCode.success.code);
    });

    test('Remove Release', () async {
      expect(
        await runner.runOrThrow(['fvm', 'remove', release]),
        ExitCode.success.code,
      );
    });
  });

  group('Commands', () {
    test('Get Version', () async {
      expect(
        await runner.runOrThrow(['fvm', '--version']),
        ExitCode.success.code,
      );

      expect(
        await runner.runOrThrow(['fvm', '-v']),
        ExitCode.success.code,
      );
    });

    test('Doctor Command', () async {
      expect(
        await runner.runOrThrow(['fvm', 'doctor']),
        ExitCode.success.code,
      );
    });

    test('Flavor Command', () async {
      await runner.runOrThrow(['fvm', 'install', channel]);

      expect(
        await runner.runOrThrow([
          'fvm',
          'use',
          channel,
          '--flavor',
          'production',
          '--skip-setup',
          '--force',
        ]),
        ExitCode.success.code,
      );

      expect(
        await runner.runOrThrow(['fvm', 'use', 'production', '--skip-setup', '--force']),
        ExitCode.success.code,
      );
    });
  });
}
