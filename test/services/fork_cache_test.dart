import 'dart:io';

import 'package:fvm/fvm.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

import '../testing_utils.dart';

void main() {
  late CacheService cacheService;
  late FvmContext context;
  late Directory tempDir;

  void markAsSdk(Directory versionDir) {
    Directory(path.join(versionDir.path, '.git')).createSync(recursive: true);
    File(
      path.join(
        versionDir.path,
        'bin',
        Platform.isWindows ? 'flutter.bat' : 'flutter',
      ),
    ).createSync(recursive: true);
  }

  setUp(() {
    context = TestFactory.context(
      debugLabel: 'fork-cache-test',
      privilegedAccess: true,
    );

    tempDir = Directory(context.versionsCachePath);
    cacheService = CacheService(context);
  });

  tearDown(() {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('Fork-specific caching', () {
    test(
      'getVersionCacheDir returns fork-specific paths for forked versions',
      () {
        final forkVersion = FlutterVersion.parse('testfork/master');
        final expectedPath = path.join(tempDir.path, 'testfork', 'master');

        final result = cacheService.getVersionCacheDir(forkVersion);
        expect(result.path, equals(expectedPath));
      },
    );

    test('getVersionCacheDir returns standard paths for regular versions', () {
      final regularVersion = FlutterVersion.parse('stable');
      final expectedPath = path.join(tempDir.path, 'stable');

      final result = cacheService.getVersionCacheDir(regularVersion);
      expect(result.path, equals(expectedPath));
    });

    test('remove cleans up empty fork directories', () async {
      final forkVersion = FlutterVersion.parse('testfork/master');

      final versionDir = cacheService.getVersionCacheDir(forkVersion);
      versionDir.createSync(recursive: true);
      File(path.join(versionDir.path, 'bin', 'flutter'))
          .createSync(recursive: true);

      final forkDir = versionDir.parent;
      expect(forkDir.existsSync(), isTrue);
      expect(versionDir.existsSync(), isTrue);

      await cacheService.remove(forkVersion);

      expect(versionDir.existsSync(), isFalse);
      expect(forkDir.existsSync(), isFalse);
    });

    test('remove preserves fork directory if other versions exist', () async {
      final forkVersion1 = FlutterVersion.parse('testfork/master');
      final forkVersion2 = FlutterVersion.parse('testfork/stable');

      final versionDir1 = cacheService.getVersionCacheDir(forkVersion1);
      versionDir1.createSync(recursive: true);
      File(path.join(versionDir1.path, 'bin', 'flutter'))
          .createSync(recursive: true);

      final versionDir2 = cacheService.getVersionCacheDir(forkVersion2);
      versionDir2.createSync(recursive: true);
      File(path.join(versionDir2.path, 'bin', 'flutter'))
          .createSync(recursive: true);

      final forkDir = versionDir1.parent;

      await cacheService.remove(forkVersion1);

      expect(versionDir1.existsSync(), isFalse);
      expect(forkDir.existsSync(), isTrue);
      expect(versionDir2.existsSync(), isTrue);
    });

    test('getAllVersions finds versions in both root and fork directories',
        () async {
      final regularVersion = FlutterVersion.parse('stable');
      final forkVersion = FlutterVersion.parse('testfork/master');

      final regularDir = cacheService.getVersionCacheDir(regularVersion);
      regularDir.createSync(recursive: true);
      markAsSdk(regularDir);

      final forkDir = cacheService.getVersionCacheDir(forkVersion);
      forkDir.createSync(recursive: true);
      markAsSdk(forkDir);

      final versions = await cacheService.getAllVersions();

      expect(
        versions.length,
        equals(2),
        reason: 'Expected to find 2 versions, but found ${versions.length}',
      );

      expect(
        versions.any((v) => v.version == 'stable' && !v.fromFork),
        isTrue,
        reason: 'Standard version "stable" should be found',
      );

      expect(
        versions.any(
          (v) => v.version == 'master' && v.fromFork && v.fork == 'testfork',
        ),
        isTrue,
        reason: 'Forked version "testfork/master" should be found',
      );
    });
  });
}
