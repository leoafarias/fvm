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
    test(
      'version mismatch in CI mode auto-selects safe default',
      () async {
      final context = TestFactory.context(
        environmentOverrides: {'CI': 'true'},
      );
      runner = TestFactory.commandRunner(context: context);

      final version = FlutterVersion.parse('3.10.0');
      final cacheService = context.get<CacheService>();
      final ensureCache = EnsureCacheWorkflow(context);

      await runner.run(['fvm', 'install', '3.10.0', '--no-setup']);

      final cacheVersion = cacheService.getVersion(version);
      if (cacheVersion != null) {
        forceUpdateFlutterSdkVersionFile(cacheVersion, '3.10.5');
      }

      final result = await ensureCache(version);

      expect(result, isNotNull);
      expect(result.name, equals('3.10.0'));
    }, timeout: Timeout(Duration(minutes: 15)));

    test(
      '--fvm-skip-input flag handles version mismatch gracefully',
      () async {
      final context = TestFactory.context(
        skipInput: true,
      );
      runner = TestCommandRunner(context);

      final version = FlutterVersion.parse('3.10.0');
      final cacheService = context.get<CacheService>();
      final ensureCache = EnsureCacheWorkflow(context);

      await runner.run(['fvm', 'install', '3.10.0', '--no-setup']);
      final cacheVersion = cacheService.getVersion(version);
      if (cacheVersion != null) {
        forceUpdateFlutterSdkVersionFile(cacheVersion, '3.10.5');
      }

      final result = await ensureCache(version);

      expect(result, isNotNull);
      expect(result.name, equals('3.10.0'));
    }, timeout: Timeout(Duration(minutes: 15)));

    test(
      'GitHub Actions environment handles version mismatch',
      () async {
      final context = TestFactory.context(
        environmentOverrides: {'GITHUB_ACTIONS': 'true', 'CI': 'true'},
      );
      runner = TestFactory.commandRunner(context: context);

      final version = FlutterVersion.parse('3.10.0');
      final cacheService = context.get<CacheService>();
      final ensureCache = EnsureCacheWorkflow(context);

      await runner.run(['fvm', 'install', '3.10.0', '--no-setup']);
      final cacheVersion = cacheService.getVersion(version);
      if (cacheVersion != null) {
        forceUpdateFlutterSdkVersionFile(cacheVersion, '3.10.5');
      }

      final result = await ensureCache(version);

      expect(result, isNotNull);
    }, timeout: Timeout(Duration(minutes: 15)));

    test(
      'CI environment variables properly detected from multiple sources',
      () {
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

        final multiCiContext = TestFactory.context(
          environmentOverrides: {'CI': 'true', 'GITHUB_ACTIONS': 'true'},
        );

        expect(multiCiContext.isCI, isTrue);
        expect(multiCiContext.skipInput, isTrue);
      },
    );

  });
}
