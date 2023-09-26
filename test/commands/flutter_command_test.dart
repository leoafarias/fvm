@Timeout(Duration(minutes: 5))
import 'dart:io';

import 'package:fvm/src/models/flutter_version_model.dart';
import 'package:fvm/src/services/cache_service.dart';
import 'package:fvm/src/services/project_service.dart';
import 'package:fvm/src/services/releases_service/releases_client.dart';
import 'package:fvm/src/utils/commands.dart';
import 'package:fvm/src/utils/helpers.dart';
import 'package:io/io.dart';
import 'package:test/test.dart';

import '../testing_utils.dart';

void main() {
  groupWithContext('Flutter command:', () {
    final runner = TestCommandRunner();
    testWithContext(
      'On cache version',
      () async {
        await runner.run('fvm use $channel');

        final project = ProjectService.fromContext.findAncestor();
        final cacheVersion = CacheService.fromContext.getVersion(
          FlutterVersion.parse(channel),
        );

        expect(project.pinnedVersion?.name, channel);

        expect(
          cacheVersion?.notSetup,
          false,
          reason: 'Version should be setup',
        );
        expect(
          cacheVersion?.isChannel,
          true,
          reason: 'Version should be channel',
        );

        expect(
          cacheVersion?.flutterSdkVersion,
          isNotNull,
          reason: 'Version should  have flutter sdk version',
        );
        expect(
          cacheVersion?.dartSdkVersion,
          isNotNull,
          reason: 'Version should  have dart sdk version',
        );

        final dartVersionExitCode = await runner.run('fvm dart --version');
        final flutterVersionExitCode =
            await runner.run('fvm flutter --version');

        expect(dartVersionExitCode, ExitCode.success.code);
        expect(flutterVersionExitCode, ExitCode.success.code);

        final dartVersionResult =
            await runDart(['--version'], version: cacheVersion!);
        final flutterVersionResult =
            await runFlutter(['--version'], version: cacheVersion);

        final flutterVersion =
            extractFlutterVersionOutput(flutterVersionResult.stdout);
        final dartVersion = extractDartVersionOutput(dartVersionResult.stdout);

        expect(dartVersion, cacheVersion.dartSdkVersion);

        expect(flutterVersion.channel, channel);
        expect(flutterVersion.dartBuildVersion, cacheVersion.dartSdkVersion);
        expect(flutterVersion.flutterVersion, cacheVersion.flutterSdkVersion);
      },
    );

    testWithContext('On global version', () async {
      final versionNumber = "2.2.0";

      await runner.run('fvm install $versionNumber --setup');
      final cacheVersion = CacheService.fromContext
          .getVersion(FlutterVersion.parse(versionNumber));

      final updatedEnvironments = updateEnvironmentVariables(
        [cacheVersion!.binPath, cacheVersion.dartBinPath],
        Platform.environment,
      );

      final dartVersionResult = await Process.run(
        'dart',
        ['--version'],
        runInShell: true,
        environment: updatedEnvironments,
      );

      final flutterVersionResult = await Process.run(
        'flutter',
        ['--version'],
        runInShell: true,
        environment: updatedEnvironments,
      );

      final release = await FlutterReleases.getReleaseFromVersion(
        versionNumber,
      );

      final dartVersionOut = dartVersionResult.stdout.toString().isEmpty
          ? dartVersionResult.stderr
          : dartVersionResult.stdout;

      final flutterVersion =
          extractFlutterVersionOutput(flutterVersionResult.stdout);
      final dartVersion = extractDartVersionOutput(dartVersionOut);

      expect(dartVersion, cacheVersion.dartSdkVersion);

      expect(flutterVersion.channel, release!.channel.name);
      expect(flutterVersion.dartBuildVersion, cacheVersion.dartSdkVersion);
      expect(flutterVersion.flutterVersion, cacheVersion.flutterSdkVersion);
    });

    testWithContext('Exec command', () async {
      final versionNumber = "3.10.5";

      await runner.run('fvm install $versionNumber --setup');
      final cacheVersion = CacheService.fromContext
          .getVersion(FlutterVersion.parse(versionNumber));

      expect(cacheVersion, isNotNull);

      final exitCode = await runner.run('fvm exec flutter --version');

      expect(exitCode, ExitCode.success.code);

      final usageExitCode = await runner.run('fvm exec');

      expect(usageExitCode, ExitCode.usage.code);

      final flutterVersionResult = await execCmd(
        'flutter',
        ['--version'],
        cacheVersion,
      );
      final dartVersionResult = await execCmd(
        'dart',
        ['--version'],
        cacheVersion,
      );

      final flutterVersion =
          extractFlutterVersionOutput(flutterVersionResult.stdout);
      final dartVersion = extractDartVersionOutput(dartVersionResult.stdout);

      final release = await FlutterReleases.getReleaseFromVersion(
        versionNumber,
      );

      expect(dartVersion, cacheVersion!.dartSdkVersion);
      expect(
        flutterVersion.channel,
        release!.channel.name,
      );
      expect(flutterVersion.dartBuildVersion, cacheVersion.dartSdkVersion);
      expect(flutterVersion.flutterVersion, cacheVersion.flutterSdkVersion);
    });
  });
}
