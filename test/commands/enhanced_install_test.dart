import 'dart:io';

import 'package:fvm/fvm.dart';
import 'package:io/io.dart';
import 'package:test/test.dart';

import '../testing_utils.dart';

void main() {
  group('Enhanced Install Command Tests:', () {
    late TestCommandRunner runner;

    setUp(() {
      runner = TestFactory.commandRunner();
    });

    group('Install command flags:', () {
      test('Install with --setup flag', () async {
        const version = 'stable';

        final exitCode =
            await runner.runOrThrow(['fvm', 'install', version, '--setup']);

        expect(exitCode, ExitCode.success.code);

        // Verify installation
        final cacheVersion = runner.context.get<CacheService>().getVersion(
              FlutterVersion.parse(version),
            );
        expect(cacheVersion != null, true, reason: 'Install with setup failed');
      });

      test('Install with --skip-pub-get flag', () async {
        const version = 'stable';

        final exitCode = await runner
            .runOrThrow(['fvm', 'install', version, '--skip-pub-get']);

        expect(exitCode, ExitCode.success.code);

        // Verify installation
        final cacheVersion = runner.context.get<CacheService>().getVersion(
              FlutterVersion.parse(version),
            );
        expect(cacheVersion != null, true,
            reason: 'Install with skip-pub-get failed');
      });

      test('Install with both --setup and --skip-pub-get flags', () async {
        const version = 'beta';

        final exitCode = await runner.runOrThrow(
            ['fvm', 'install', version, '--setup', '--skip-pub-get']);

        expect(exitCode, ExitCode.success.code);

        // Verify installation
        final cacheVersion = runner.context.get<CacheService>().getVersion(
              FlutterVersion.parse(version),
            );
        expect(cacheVersion != null, true,
            reason: 'Install with multiple flags failed');
      });
    });

    group('Install from project configuration:', () {
      test('Install without version uses project config', () async {
        // Create a temporary directory for this test
        final tempDir =
            Directory.systemTemp.createTempSync('fvm_install_test_');
        final originalDir = Directory.current;

        try {
          // Change to the temp directory
          Directory.current = tempDir;

          // Create a .fvmrc file with a version
          const projectVersion = 'stable';
          final configFile = File('.fvmrc');
          configFile.writeAsStringSync('{"flutter": "$projectVersion"}');

          // Create a fresh runner in this directory
          final testContext = FvmContext.create(
            workingDirectoryOverride: tempDir.path,
            isTest: true,
          );
          final localRunner = TestCommandRunner(testContext);

          // Install without specifying version
          final exitCode = await localRunner.runOrThrow(['fvm', 'install']);
          expect(exitCode, ExitCode.success.code);

          // Verify the project version was installed
          final cacheVersion =
              localRunner.context.get<CacheService>().getVersion(
                    FlutterVersion.parse(projectVersion),
                  );
          expect(cacheVersion != null, true,
              reason: 'Project config install failed');
        } finally {
          // Restore original directory and clean up
          Directory.current = originalDir;
          if (tempDir.existsSync()) {
            tempDir.deleteSync(recursive: true);
          }
        }
      });

      test('Install without version and no config shows helpful error',
          () async {
        // Ensure no config file exists
        final configFile = File('.fvmrc');
        if (configFile.existsSync()) {
          configFile.deleteSync();
        }

        // Should fail with helpful message
        expect(
          () => runner.runOrThrow(['fvm', 'install']),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('Install version formats:', () {
      test('Install version with v prefix', () async {
        const version =
            'v1.12.0'; // Use a version that actually exists with v prefix

        final exitCode = await runner.runOrThrow(['fvm', 'install', version]);
        expect(exitCode, ExitCode.success.code);

        // Verify installation (should strip v prefix)
        final cacheVersion = runner.context.get<CacheService>().getVersion(
              FlutterVersion.parse(version),
            );
        expect(cacheVersion != null, true,
            reason: 'Install with v prefix failed');
      });

      test('Install version with channel suffix', () async {
        const version = '3.19.0@beta';

        final exitCode = await runner.runOrThrow(['fvm', 'install', version]);
        expect(exitCode, ExitCode.success.code);

        // Verify installation
        final cacheVersion = runner.context.get<CacheService>().getVersion(
              FlutterVersion.parse(version),
            );
        expect(cacheVersion != null, true,
            reason: 'Install with channel suffix failed');
      });

      test('Install git commit hash', () async {
        const commitHash = 'f4c74a6ec3';

        final exitCode =
            await runner.runOrThrow(['fvm', 'install', commitHash]);
        expect(exitCode, ExitCode.success.code);

        // Verify installation
        final cacheVersion = runner.context.get<CacheService>().getVersion(
              FlutterVersion.parse(commitHash),
            );
        expect(cacheVersion != null, true,
            reason: 'Install commit hash failed');
      });
    });

    group('Install error handling:', () {
      test('Install invalid version format fails gracefully', () async {
        expect(
          () => runner.runOrThrow(['fvm', 'install', 'invalid.version.format']),
          throwsA(isA<Exception>()),
        );
      });

      test('Install with invalid channel fails gracefully', () async {
        expect(
          () => runner.runOrThrow(['fvm', 'install', '3.19.0@invalidchannel']),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('Install command help and usage:', () {
      test('Install help shows correct usage', () async {
        // Help commands should return success, not throw exceptions
        final exitCode = await runner.runOrThrow(['fvm', 'install', '--help']);
        expect(exitCode, ExitCode.success.code);
      });

      test('Install with invalid flags shows usage', () async {
        expect(
          () => runner.runOrThrow(['fvm', 'install', '--invalid-flag']),
          throwsA(isA<Exception>()),
        );
      });
    });
  });
}
