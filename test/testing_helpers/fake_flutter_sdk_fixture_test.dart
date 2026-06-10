import 'package:fvm/fvm.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../testing_utils.dart';

void main() {
  late FvmContext context;
  late CacheService cacheService;

  setUp(() {
    context = TestFactory.fastContext(debugLabel: 'fixture-helper-test');
    cacheService = context.get<CacheService>();
  });

  group('FakeFlutterSdkFixture', () {
    test('installedNotSetup is not setup but integrity is valid', () async {
      final version = FlutterVersion.parse('3.10.0');

      FakeFlutterSdkFixture.install(
        context,
        version,
        state: FakeFlutterSdkState.installedNotSetup,
      );

      final cacheVersion = cacheService.getVersion(version);
      expect(cacheVersion, isNotNull);
      expect(cacheVersion!.isSetup, isFalse);
      expect(cacheVersion.flutterSdkVersion, equals('3.10.0'));

      expect(
        await cacheService.verifyCacheIntegrity(cacheVersion),
        equals(CacheIntegrity.valid),
      );
    });

    test('installedSetup includes Dart metadata', () async {
      final version = FlutterVersion.parse('3.10.0');

      FakeFlutterSdkFixture.install(
        context,
        version,
        state: FakeFlutterSdkState.installedSetup,
      );

      final cacheVersion = cacheService.getVersion(version);
      expect(cacheVersion, isNotNull);
      expect(cacheVersion!.isSetup, isTrue);
      expect(cacheVersion.flutterSdkVersion, equals('3.10.0'));
      expect(cacheVersion.dartSdkVersion, isNotEmpty);

      expect(
        await cacheService.verifyCacheIntegrity(cacheVersion),
        equals(CacheIntegrity.valid),
      );
    });

    test('versionMismatch prefers JSON metadata', () async {
      final version = FlutterVersion.parse('3.10.0');

      FakeFlutterSdkFixture.install(
        context,
        version,
        state: FakeFlutterSdkState.versionMismatch,
        mismatchCachedVersion: '3.10.5',
      );

      final cacheVersion = cacheService.getVersion(version);
      expect(cacheVersion, isNotNull);
      expect(cacheVersion!.flutterSdkVersion, equals('3.10.5'));

      expect(
        await cacheService.verifyCacheIntegrity(cacheVersion),
        equals(CacheIntegrity.versionMismatch),
      );
    });

    test('invalid executable reports invalid integrity', () async {
      final version = FlutterVersion.parse('3.10.0');

      FakeFlutterSdkFixture.install(
        context,
        version,
        state: FakeFlutterSdkState.invalidExecutable,
      );

      final cacheVersion = cacheService.getVersion(version);
      expect(cacheVersion, isNotNull);

      expect(
        await cacheService.verifyCacheIntegrity(cacheVersion!),
        equals(CacheIntegrity.invalid),
      );
    });

    test('fork versions use versions/<fork>/<version> cache path', () {
      final version = FlutterVersion.parse('leo/leo-test-21');

      FakeFlutterSdkFixture.install(
        context,
        version,
        state: FakeFlutterSdkState.installedNotSetup,
      );

      final cacheVersion = cacheService.getVersion(version);
      expect(cacheVersion, isNotNull);
      expect(
        cacheService.getVersionCacheDir(version).path,
        equals(cacheVersion!.directory),
      );
      expect(cacheVersion.directory, endsWith(p.join('leo', 'leo-test-21')));
    });

    test('channel versions skip mismatch checks', () async {
      final version = FlutterVersion.parse('stable');

      FakeFlutterSdkFixture.install(
        context,
        version,
        state: FakeFlutterSdkState.versionMismatch,
        mismatchCachedVersion: '9.9.9',
      );

      final cacheVersion = cacheService.getVersion(version);
      expect(cacheVersion, isNotNull);

      expect(
        await cacheService.verifyCacheIntegrity(cacheVersion!),
        equals(CacheIntegrity.valid),
      );
    });

    test('unknown git refs skip mismatch checks', () async {
      final version = FlutterVersion.parse('f4c74a6ec3');

      FakeFlutterSdkFixture.install(
        context,
        version,
        state: FakeFlutterSdkState.versionMismatch,
        mismatchCachedVersion: '9.9.9',
      );

      final cacheVersion = cacheService.getVersion(version);
      expect(cacheVersion, isNotNull);

      expect(
        await cacheService.verifyCacheIntegrity(cacheVersion!),
        equals(CacheIntegrity.valid),
      );
    });
  });
}
