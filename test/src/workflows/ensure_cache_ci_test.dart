import 'dart:io';

import 'package:fvm/fvm.dart';
import 'package:fvm/src/services/flutter_service.dart';
import 'package:fvm/src/workflows/ensure_cache.workflow.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

import '../../testing_utils.dart';

void main() {
  late TestCommandRunner runner;
  late TempDirectoryTracker tempDirs;

  setUp(() {
    tempDirs = TempDirectoryTracker();
  });

  tearDown(() {
    tempDirs.cleanUp();
  });

  group('EnsureCache CI/CD Behavior', () {
    test('version mismatch in CI mode auto-selects safe default', () async {
      // Create context that simulates CI environment
      final context = TestFactory.context(
        environmentOverrides: {'CI': 'true'}, // Triggers isCI = true
      );
      runner = TestFactory.commandRunner(context: context);

      // Setup version with mismatch
      final version = FlutterVersion.parse('3.10.0');
      final cacheService = context.get<CacheService>();
      final ensureCache = EnsureCacheWorkflow(context);

      // First install the version
      await runner.run(['fvm', 'install', '3.10.0', '--no-setup']);

      // Create version mismatch by modifying SDK version file
      final cacheVersion = cacheService.getVersion(version);
      if (cacheVersion != null) {
        forceUpdateFlutterSdkVersionFile(cacheVersion, '3.10.5');
      }

      // This should NOT crash in CI mode, should auto-select "remove and reinstall"
      // Currently this will crash with exit code because no default selection is provided
      final result = await ensureCache(version);

      expect(result, isNotNull);
      expect(result.name, equals('3.10.0'));
    });

    test('--fvm-skip-input flag handles version mismatch gracefully', () async {
      final context = TestFactory.context(
        skipInput: true, // Manual skipInput flag
      );
      runner = TestCommandRunner(context);

      final version = FlutterVersion.parse('3.10.0');
      final cacheService = context.get<CacheService>();
      final ensureCache = EnsureCacheWorkflow(context);

      // Setup version with mismatch
      await runner.run(['fvm', 'install', '3.10.0', '--no-setup']);
      final cacheVersion = cacheService.getVersion(version);
      if (cacheVersion != null) {
        forceUpdateFlutterSdkVersionFile(cacheVersion, '3.10.5');
      }

      // Should not crash with --fvm-skip-input flag
      final result = await ensureCache(version);

      expect(result, isNotNull);
      expect(result.name, equals('3.10.0'));
    });

    test('GitHub Actions environment handles version mismatch', () async {
      final context = TestFactory.context(
        environmentOverrides: {'GITHUB_ACTIONS': 'true', 'CI': 'true'},
      );
      runner = TestFactory.commandRunner(context: context);

      final version = FlutterVersion.parse('3.10.0');
      final cacheService = context.get<CacheService>();
      final ensureCache = EnsureCacheWorkflow(context);

      // Setup version with mismatch
      await runner.run(['fvm', 'install', '3.10.0', '--no-setup']);
      final cacheVersion = cacheService.getVersion(version);
      if (cacheVersion != null) {
        forceUpdateFlutterSdkVersionFile(cacheVersion, '3.10.5');
      }

      // Should handle gracefully in GitHub Actions
      final result = await ensureCache(version);

      expect(result, isNotNull);
    });

    test(
      'CI environment variables properly detected from multiple sources',
      () {
        // Test ALL supported CI environment variables from constants.dart
        final ciVariables = [
          'CI',
          'TRAVIS',
          'CIRCLECI',
          'GITHUB_ACTIONS',
          'GITLAB_CI',
          'JENKINS_URL',
          'BAMBOO_BUILD_NUMBER',
          'TEAMCITY_VERSION',
          'TF_BUILD',
        ];

        for (final ciVar in ciVariables) {
          final context = TestFactory.context(
            environmentOverrides: {ciVar: 'true'},
          );

          expect(
            context.isCI,
            isTrue,
            reason: 'Failed CI detection for $ciVar',
          );
          expect(
            context.skipInput,
            isTrue,
            reason: 'Failed skipInput for $ciVar',
          );
        }

        // Test that having multiple CI variables also works
        final multiCiContext = TestFactory.context(
          environmentOverrides: {'CI': 'true', 'GITHUB_ACTIONS': 'true'},
        );

        expect(multiCiContext.isCI, isTrue);
        expect(multiCiContext.skipInput, isTrue);
      },
    );

    test('verify CI detection works correctly', () {
      // Test CI environment detection
      final ciContext = TestFactory.context(
        environmentOverrides: {'CI': 'true'},
      );

      expect(ciContext.isCI, isTrue);
      expect(ciContext.skipInput, isTrue);
    });
  });

  group('EnsureCache useArchive propagation', () {
    test('useArchive is preserved through corrupted cache reinstall', () async {
      final context = TestFactory.context(
        debugLabel: 'archive-propagation-test',
      );
      runner = TestCommandRunner(context);
      final flutterService =
          context.get<FlutterService>() as MockFlutterService;

      // First install using --archive
      await runner.run(['fvm', 'install', 'stable', '--archive', '--no-setup']);

      // Corrupt the cache by removing the flutter executable
      final cacheService = context.get<CacheService>();
      final version = FlutterVersion.parse('stable');
      final cacheVersion = cacheService.getVersion(version);
      expect(cacheVersion, isNotNull);

      final execName = Platform.isWindows ? 'flutter.bat' : 'flutter';
      final flutterBin =
          File(path.join(cacheVersion!.directory, 'bin', execName));
      if (flutterBin.existsSync()) {
        flutterBin.deleteSync();
      }

      // Reset markers before triggering reinstall
      flutterService
        ..lastUseArchive = null
        ..lastInstallVersion = null;

      final ensureCache = EnsureCacheWorkflow(context);
      final result = await ensureCache(version, useArchive: true);

      expect(result, isNotNull);
      expect(flutterService.lastUseArchive, isTrue);
      expect(flutterService.lastInstallVersion?.name, 'stable');
    });

    test('useArchive flag is forwarded in workflow call signature', () async {
      final context = TestFactory.context();
      final ensureCache = EnsureCacheWorkflow(context);

      // This test verifies that the workflow accepts useArchive parameter
      // The actual propagation through _handleNonExecutable and
      // _handleVersionMismatch is tested via integration
      final version = FlutterVersion.parse('stable');

      // Call with useArchive=true - should not throw
      final result = await ensureCache(
        version,
        shouldInstall: true,
        useArchive: true,
      );

      expect(result, isNotNull);

      // Verify the mock captured useArchive
      final flutterService =
          context.get<FlutterService>() as MockFlutterService;
      expect(flutterService.lastUseArchive, isTrue);
    });
  });
}
