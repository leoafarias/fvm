import 'dart:io';

import 'package:fvm/src/models/flutter_version_model.dart';
import 'package:fvm/src/utils/context.dart';
import 'package:io/io.dart';
import 'package:path/path.dart';
import 'package:test/test.dart';

import 'testing_utils.dart';

void main() {
  late TestCommandRunner runner;
  late ServicesProvider services;
  late FVMContext context;

  const channel = 'stable'; // Define channel explicitly
  const release = '2.0.0'; // Define release explicitly

  setUp(() {
    runner = TestFactory.commandRunner();
    context = runner.context;
    services = runner.services;
  });

  group('Channel Workflow:', () {
    test('Install Channel', () async {
      await runner.runOrThrow(['fvm', 'install', channel]);

      final cacheVersion = services.cache.getVersion(
        FlutterVersion.parse(channel),
      );

      final existingChannel = await services.git.getBranch(
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

        final project = services.project.findAncestor();

        final link = Link(project.localVersionSymlinkPath);

        final linkExists = link.existsSync();

        final targetBin = link.targetSync();

        final channelBin = services.cache.getVersionCacheDir(channel);

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
      final existingRelease = await services.git.getTag(
        valid.name,
      );

      final cacheVersion = services.cache.getVersion(valid);

      expect(cacheVersion != null, true, reason: 'Install does not exist');

      expect(existingRelease, valid.name);
    });

    test('Install commit', () async {
      final shortGitHash = 'fb57da5f94';

      await runner.runOrThrow(['fvm', 'install', shortGitHash]);
      final validShort = FlutterVersion.parse(shortGitHash);

      final cacheVersionShort = services.cache.getVersion(validShort);

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

      final project = services.project.findAncestor();
      final link = Link(project.localVersionSymlinkPath);
      final linkExists = link.existsSync();

      final targetPath = link.targetSync();
      final valid = FlutterVersion.parse(release);
      final versionDir = services.cache.getVersionCacheDir(valid.name);

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
        ]),
        ExitCode.success.code,
      );

      expect(
        await runner.runOrThrow(['fvm', 'use', 'production']),
        ExitCode.success.code,
      );
    });
  });
}
