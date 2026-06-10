import 'package:fvm/fvm.dart';
import 'package:fvm/src/services/flutter_service.dart';
import 'package:fvm/src/workflows/ensure_cache.workflow.dart';
import 'package:test/test.dart';

import '../../testing_utils.dart';

void main() {
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
        final context = TestFactory.fastContext(
          environmentOverrides: {'CI': 'true'},
        );
        final flutterService =
            context.get<FlutterService>() as FakeFlutterService;

        final version = FlutterVersion.parse('3.10.0');
        final cacheService = context.get<CacheService>();
        final ensureCache = EnsureCacheWorkflow(context);

        FakeFlutterSdkFixture.install(
          context,
          version,
          state: FakeFlutterSdkState.versionMismatch,
          mismatchCachedVersion: '3.10.5',
        );

        final mismatchedVersion = cacheService.getVersion(version);
        expect(mismatchedVersion, isNotNull);
        expect(
          await cacheService.verifyCacheIntegrity(mismatchedVersion!),
          equals(CacheIntegrity.versionMismatch),
        );

        final installCountBefore = flutterService.installedVersions.length;
        final result = await ensureCache(version);

        expect(result, isNotNull);
        expect(result.name, equals('3.10.0'));
        expect(
          flutterService.installedVersions.length,
          greaterThan(installCountBefore),
        );
        expect(flutterService.installedVersions.last.name, equals('3.10.0'));
      },
    );

    test(
      '--fvm-skip-input flag handles version mismatch gracefully',
      () async {
        final context = TestFactory.fastContext(
          skipInput: true,
        );
        final flutterService =
            context.get<FlutterService>() as FakeFlutterService;

        final version = FlutterVersion.parse('3.10.0');
        final cacheService = context.get<CacheService>();
        final ensureCache = EnsureCacheWorkflow(context);

        FakeFlutterSdkFixture.install(
          context,
          version,
          state: FakeFlutterSdkState.versionMismatch,
          mismatchCachedVersion: '3.10.5',
        );

        final mismatchedVersion = cacheService.getVersion(version);
        expect(
          await cacheService.verifyCacheIntegrity(mismatchedVersion!),
          equals(CacheIntegrity.versionMismatch),
        );

        final installCountBefore = flutterService.installedVersions.length;
        final result = await ensureCache(version);

        expect(result, isNotNull);
        expect(result.name, equals('3.10.0'));
        expect(
          flutterService.installedVersions.length,
          greaterThan(installCountBefore),
        );
      },
    );

    test(
      'GitHub Actions environment handles version mismatch',
      () async {
        final context = TestFactory.fastContext(
          environmentOverrides: {'GITHUB_ACTIONS': 'true', 'CI': 'true'},
        );
        final flutterService =
            context.get<FlutterService>() as FakeFlutterService;

        final version = FlutterVersion.parse('3.10.0');
        final cacheService = context.get<CacheService>();
        final ensureCache = EnsureCacheWorkflow(context);

        FakeFlutterSdkFixture.install(
          context,
          version,
          state: FakeFlutterSdkState.versionMismatch,
          mismatchCachedVersion: '3.10.5',
        );

        final mismatchedVersion = cacheService.getVersion(version);
        expect(
          await cacheService.verifyCacheIntegrity(mismatchedVersion!),
          equals(CacheIntegrity.versionMismatch),
        );

        final installCountBefore = flutterService.installedVersions.length;
        final result = await ensureCache(version);

        expect(result, isNotNull);
        expect(
          flutterService.installedVersions.length,
          greaterThan(installCountBefore),
        );
      },
    );

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
