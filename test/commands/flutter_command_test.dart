import 'dart:io';

import 'package:fvm/src/models/flutter_version_model.dart';
// Import your controller and testing utils
import 'package:fvm/src/utils/context.dart';
import 'package:fvm/src/utils/helpers.dart';
import 'package:io/io.dart';
import 'package:test/test.dart';

import '../testing_utils.dart';

void main() {
  // Define variables we'll use across tests
  late FvmController controller;
  late TestCommandRunner testRunner;
  const channel = 'stable'; // Set your desired channel

  // Setup that runs before the entire test suite
  setUpAll(() async {
    // Initialize the controller with test context
    controller = FvmController(FVMContext.create(isTest: true));
    testRunner = TestCommandRunner(controller);
  });

  // Tests for Flutter commands
  group('Flutter command:', () {
    // Test 1: On cache version
    test('On cache version', () async {
      // Run the command to use a specific channel
      await testRunner.run(['fvm', 'use', channel]);

      // Get project and cache version
      final project = controller.project.findAncestor();
      final cacheVersion = controller.cache.getVersion(
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
      final dartVersionResult = await controller.flutter
          .runDart(['--version'], version: cacheVersion);

      final flutterVersionResult = await controller.flutter
          .runFlutter(['--version'], version: cacheVersion);

      // Extract and verify version information
      final flutterVersion =
          extractFlutterVersionOutput(flutterVersionResult.stdout);
      final dartVersion = extractDartVersionOutput(dartVersionResult.stdout);

      expect(dartVersion, cacheVersion!.dartSdkVersion);
      expect(flutterVersion.channel, channel);
      expect(flutterVersion.dartBuildVersion, cacheVersion.dartSdkVersion);
      expect(flutterVersion.flutterVersion, cacheVersion.flutterSdkVersion);
    });

    // Test 2: On global version
    test('On global version', () async {
      final versionNumber = "2.2.0";

      // Install specific version
      await testRunner.run(['fvm', 'install', versionNumber, '--setup']);
      final cacheVersion = controller.cache.getVersion(
        FlutterVersion.parse(versionNumber),
      );

      // Update environment variables
      final updatedEnvironments = updateEnvironmentVariables(
        [cacheVersion!.binPath, cacheVersion.dartBinPath],
        Platform.environment,
        controller.logger,
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
      final release = await controller.releases.getReleaseFromVersion(
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
      final cacheVersion = controller.cache.getVersion(
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

      // Run commands with exec
      final flutterVersionResult = await controller.flutter.exec(
        'flutter',
        ['--version'],
        cacheVersion,
      );

      final dartVersionResult = await controller.flutter.exec(
        'dart',
        ['--version'],
        cacheVersion,
      );

      // Extract and verify version information
      final flutterVersion =
          extractFlutterVersionOutput(flutterVersionResult.stdout);
      final dartVersion = extractDartVersionOutput(dartVersionResult.stdout);

      final release = await controller.releases.getReleaseFromVersion(
        versionNumber,
      );

      expect(dartVersion, cacheVersion!.dartSdkVersion);
      expect(flutterVersion.channel, release!.channel.name);
      expect(flutterVersion.dartBuildVersion, cacheVersion.dartSdkVersion);
      expect(flutterVersion.flutterVersion, cacheVersion.flutterSdkVersion);
    });
  });
}
