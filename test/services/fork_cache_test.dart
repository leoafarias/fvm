import 'dart:io';

import 'package:fvm/fvm.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

import '../testing_utils.dart';

void main() {
  late CacheService cacheService;
  late FvmContext context;
  late Directory tempDir;

  void _markAsSdk(Directory versionDir) {
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
    // Create test context using TestFactory
    context = TestFactory.context(
      debugLabel: 'fork-cache-test',
      privilegedAccess: true,
    );

    // Use the cache directory that TestFactory provides
    tempDir = Directory(context.versionsCachePath);

    // Create the cache service with test context
    cacheService = CacheService(context);
  });

  tearDown(() {
    // Clean up is handled by TestFactory, but we can ensure it's clean
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('Fork-specific caching', () {
    test(
      'getVersionCacheDir returns fork-specific paths for forked versions',
      () {
        // Given: A forked version
        final forkVersion = FlutterVersion.parse('testfork/master');
        final expectedPath = path.join(tempDir.path, 'testfork', 'master');

        // When: Getting the cache directory
        final result = cacheService.getVersionCacheDir(forkVersion);

        // Then: Path should include the fork name
        expect(result.path, equals(expectedPath));
      },
    );

    test('getVersionCacheDir returns standard paths for regular versions', () {
      // Given: A regular version
      final regularVersion = FlutterVersion.parse('stable');
      final expectedPath = path.join(tempDir.path, 'stable');

      // When: Getting the cache directory
      final result = cacheService.getVersionCacheDir(regularVersion);

      // Then: Path should be in the root of versions cache
      expect(result.path, equals(expectedPath));
    });

    test('remove cleans up empty fork directories', () {
      // Given: A fork directory with a version
      final forkName = 'testfork';
      final versionName = 'master';
      final forkVersion = FlutterVersion.parse('$forkName/$versionName');

      // Create the version directory using cache service
      final versionDir = cacheService.getVersionCacheDir(forkVersion);
      versionDir.createSync(recursive: true);

      // Create bin/flutter to make it look like a valid Flutter SDK
      final binDir = Directory(path.join(versionDir.path, 'bin'));
      binDir.createSync(recursive: true);
      File(path.join(binDir.path, 'flutter')).createSync();

      final forkDir = versionDir.parent;

      expect(forkDir.existsSync(), isTrue);
      expect(versionDir.existsSync(), isTrue);

      // When: Removing the version
      cacheService.remove(forkVersion);

      // Then: Both the version and fork directory should be removed
      expect(versionDir.existsSync(), isFalse);
      expect(forkDir.existsSync(), isFalse);
    });

    test('remove preserves fork directory if other versions exist', () {
      // Given: A fork directory with multiple versions
      final forkName = 'testfork';
      final versionName1 = 'master';
      final versionName2 = 'stable';
      final forkVersion1 = FlutterVersion.parse('$forkName/$versionName1');
      final forkVersion2 = FlutterVersion.parse('$forkName/$versionName2');

      // Create the version directories using cache service
      final versionDir1 = cacheService.getVersionCacheDir(forkVersion1);
      versionDir1.createSync(recursive: true);
      // Create bin/flutter to make it look like a valid Flutter SDK
      final binDir1 = Directory(path.join(versionDir1.path, 'bin'));
      binDir1.createSync(recursive: true);
      File(path.join(binDir1.path, 'flutter')).createSync();

      final versionDir2 = cacheService.getVersionCacheDir(forkVersion2);
      versionDir2.createSync(recursive: true);
      // Create bin/flutter to make it look like a valid Flutter SDK
      final binDir2 = Directory(path.join(versionDir2.path, 'bin'));
      binDir2.createSync(recursive: true);
      File(path.join(binDir2.path, 'flutter')).createSync();

      final forkDir = versionDir1.parent;

      // When: Removing one version
      cacheService.remove(forkVersion1);

      // Then: The version should be removed but the fork directory preserved
      expect(versionDir1.existsSync(), isFalse);
      expect(forkDir.existsSync(), isTrue);
      expect(versionDir2.existsSync(), isTrue);
    });

    test('getAllVersions finds versions in both root and fork directories',
        () async {
      // Given: Both regular and forked versions
      final regularVersion = FlutterVersion.parse('stable');
      final forkVersion = FlutterVersion.parse('testfork/master');

      // Create version directories
      final regularDir = cacheService.getVersionCacheDir(regularVersion);
      regularDir.createSync(recursive: true);
      _markAsSdk(regularDir);

      final forkDir = cacheService.getVersionCacheDir(forkVersion);
      forkDir.createSync(recursive: true);
      _markAsSdk(forkDir);

      // When: Getting all versions
      final versions = await cacheService.getAllVersions();

      // Then: Both versions should be found
      expect(
        versions.length,
        equals(2),
        reason: 'Expected to find 2 versions, but found ${versions.length}',
      );

      // Check for a standard version
      expect(
        versions.any((v) => v.version == 'stable' && !v.fromFork),
        isTrue,
        reason: 'Standard version "stable" should be found',
      );

      // Check for a forked version
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
