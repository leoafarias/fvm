import 'package:fvm/fvm.dart';
import 'package:fvm/src/workflows/ensure_cache.workflow.dart';
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
}
