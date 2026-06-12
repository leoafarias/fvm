import 'package:fvm/fvm.dart';
import 'package:fvm/src/services/flutter_service.dart';
import 'package:fvm/src/services/logger_service.dart';
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

    test('non-TTY mode handles version mismatch gracefully', () async {
      final context = TestFactory.fastContext(
        stdinHasTerminal: false,
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
      final logger = context.get<Logger>();

      expect(result, isNotNull);
      expect(result.name, equals('3.10.0'));
      expect(
        flutterService.installedVersions.length,
        greaterThan(installCountBefore),
      );
      expect(flutterService.installedVersions.last.name, equals('3.10.0'));
      expect(
        logger.outputs.any(
          (message) => message.contains(
            'CI/non-interactive mode: auto-selecting remove and reinstall',
          ),
        ),
        isTrue,
      );
    });

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

    test('non-TTY stdin is treated as skipped input', () {
      final context = FvmContext.raw(
        debugLabel: null,
        workingDirectory: '.',
        config: const AppConfig(),
        appConfigPath: '',
        generators: <Type, Generator>{},
        environment: const {},
        skipInput: false,
        stdinHasTerminal: false,
      );

      expect(context.isCI, isFalse);
      expect(context.stdinHasTerminal, isFalse);
      expect(context.skipInput, isTrue);
    });

    test('context serialization separates requested and effective skipInput',
        () {
      final context = FvmContext.raw(
        debugLabel: null,
        workingDirectory: '.',
        config: const AppConfig(),
        appConfigPath: '',
        generators: <Type, Generator>{},
        environment: const {},
        skipInput: false,
        stdinHasTerminal: false,
      );

      final map = context.toMap();

      expect(map['skipInputRequested'], isFalse);
      expect(map['skipInput'], isTrue);

      final restored = FvmContextMapper.fromMap({...map, 'generators': {}});
      expect(restored.stdinHasTerminal, isFalse);
      expect(restored.skipInput, isTrue);

      final restoredWithTerminal = restored.copyWith(stdinHasTerminal: true);
      expect(restoredWithTerminal.skipInput, isFalse);
    });
  });
}
