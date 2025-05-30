import 'dart:io';

import 'package:fvm/src/models/flutter_version_model.dart';
import 'package:fvm/src/services/cache_service.dart';
import 'package:fvm/src/services/flutter_service.dart';
import 'package:fvm/src/services/project_service.dart';
import 'package:fvm/src/services/releases_service/releases_client.dart';
import 'package:fvm/src/utils/helpers.dart';
import 'package:io/io.dart';
import 'package:test/test.dart';

import '../testing_utils.dart';

void main() {
  // Define variables we'll use across tests
  late TestCommandRunner testRunner;
  const channel = 'stable'; // Set your desired channel

  // Setup that runs before the entire test suite
  setUpAll(() async {
    // Initialize the context for testing

    testRunner = TestFactory.commandRunner();
  });

  // Tests for Flutter commands
  group('Flutter command:', () {
    // Test 1: On cache version
    test('On cache version', () async {
      // Run the command to use a specific channel
      await testRunner.run(['fvm', 'use', channel]);

      // Get project and cache version
      final project = testRunner.context.get<ProjectService>().findAncestor();
      final cacheVersion = testRunner.context.get<CacheService>().getVersion(
            FlutterVersion.parse(channel),
          );

      // Assertions on project version
      expect(project.pinnedVersion?.name, channel);

      // Assertions on cache version
      expect(cacheVersion?.isNotSetup, false,
          reason: 'Version should be setup');
      expect(cacheVersion?.isChannel, true,
          reason: 'Version should be channel');
      expect(cacheVersion?.flutterSdkVersion, isNotNull,
          reason: 'Version should have flutter sdk version');
      expect(cacheVersion?.dartSdkVersion, isNotNull,
          reason: 'Version should have dart sdk version');

      // Run FVM commands and check exit codes
      final dartVersionExitCode =
          await testRunner.run(['fvm', 'dart', '--version']);
      final flutterVersionExitCode =
          await testRunner.run(['fvm', 'flutter', '--version']);

      expect(dartVersionExitCode, ExitCode.success.code);
      expect(flutterVersionExitCode, ExitCode.success.code);

      // Run commands with the specific version and check outputs
      final dartVersionResult =
          await testRunner.context.get<FlutterService>().run(
                'dart',
                ['--version'],
                cacheVersion!,
              );

      final flutterVersionResult =
          await testRunner.context.get<FlutterService>().run(
                'flutter',
                ['--version'],
                cacheVersion,
              );

      // Extract and verify version information
      final flutterVersion =
          extractFlutterVersionOutput(flutterVersionResult.stdout);
      final dartVersion = extractDartVersionOutput(dartVersionResult.stdout);

      expect(dartVersion, cacheVersion.dartSdkVersion);
      expect(flutterVersion.channel, channel);
      expect(flutterVersion.dartBuildVersion, cacheVersion.dartSdkVersion);
      expect(flutterVersion.flutterVersion, cacheVersion.flutterSdkVersion);
    });

    // Test 2: On global version
    test('On global version', () async {
      final versionNumber = "2.2.0";

      // Install specific version
      await testRunner.run(['fvm', 'install', versionNumber, '--setup']);
      final cacheVersion = testRunner.context.get<CacheService>().getVersion(
            FlutterVersion.parse(versionNumber),
          );

      // Update environment variables
      final updatedEnvironments = updateEnvironmentVariables(
        [cacheVersion!.binPath, cacheVersion.dartBinPath],
        Platform.environment,
      );

      // Run commands directly with updated environment
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

      // Get release information
      final release = await testRunner.context
          .get<FlutterReleaseClient>()
          .getReleaseByVersion(
            versionNumber,
          );

      // Extract version information
      final dartVersionOut = dartVersionResult.stdout.toString().isEmpty
          ? dartVersionResult.stderr
          : dartVersionResult.stdout;

      final flutterVersion =
          extractFlutterVersionOutput(flutterVersionResult.stdout);
      final dartVersion = extractDartVersionOutput(dartVersionOut);

      // Verify version information
      expect(dartVersion, cacheVersion.dartSdkVersion);
      expect(flutterVersion.channel, release!.channel.name);
      expect(flutterVersion.dartBuildVersion, cacheVersion.dartSdkVersion);
      expect(flutterVersion.flutterVersion, cacheVersion.flutterSdkVersion);
    });

    // Test 3: Exec command
    test('Exec command', () async {
      final versionNumber = "3.10.5";

      // Install specific version
      await testRunner.run(['fvm', 'install', versionNumber, '--setup']);
      final cacheVersion = testRunner.context.get<CacheService>().getVersion(
            FlutterVersion.parse(versionNumber),
          );

      expect(cacheVersion, isNotNull);

      // Run exec command and check exit code
      final exitCode = await testRunner.runOrThrow([
        'fvm',
        'exec',
        'flutter',
        '--version',
      ]);
      expect(exitCode, ExitCode.success.code);

      // Test usage error
      final usageExitCode = await testRunner.run(['fvm', 'exec']);
      expect(usageExitCode, ExitCode.usage.code);

      // Run commands with the version
      final flutterVersionResult =
          await testRunner.context.get<FlutterService>().run(
                'flutter',
                ['--version'],
                cacheVersion!,
              );

      final dartVersionResult =
          await testRunner.context.get<FlutterService>().run(
                'dart',
                ['--version'],
                cacheVersion,
              );

      // Extract and verify version information
      final flutterVersion =
          extractFlutterVersionOutput(flutterVersionResult.stdout);
      final dartVersion = extractDartVersionOutput(dartVersionResult.stdout);

      final release = await testRunner.context
          .get<FlutterReleaseClient>()
          .getReleaseByVersion(versionNumber);

      expect(dartVersion, cacheVersion.dartSdkVersion);
      expect(flutterVersion.channel, release!.channel.name);
      expect(flutterVersion.dartBuildVersion, cacheVersion.dartSdkVersion);
      expect(flutterVersion.flutterVersion, cacheVersion.flutterSdkVersion);
    });
  });
}
