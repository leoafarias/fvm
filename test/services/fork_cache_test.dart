import 'dart:io';

import 'package:fvm/fvm.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

class _MockFVMContext extends Mock implements FvmContext {}

void main() {
  late CacheService cacheService;
  late _MockFVMContext context;
  late Directory tempDir;

  setUp(() {
    // Create a temporary directory for tests
    tempDir = Directory.systemTemp.createTempSync('fvm_fork_test_');

    // Set up mock context
    context = _MockFVMContext();
    when(() => context.versionsCachePath).thenReturn(tempDir.path);
    when(() => context.logLevel).thenReturn(Level.info);
    when(() => context.isTest).thenReturn(true);
    when(() => context.isCI).thenReturn(false);
    when(() => context.skipInput).thenReturn(true);
    when(() => context.environment).thenReturn({});

    // Create the cache service with mock context
    cacheService = CacheService(context);
  });

  tearDown(() {
    // Clean up temporary directory
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('Fork-specific caching', () {
    test('getVersionCacheDir returns fork-specific paths for forked versions',
        () {
      // Given: A forked version
      final forkVersion = FlutterVersion.parse('testfork/master');
      final expectedPath = path.join(tempDir.path, 'testfork', 'master');

      // When: Getting the cache directory
      final result = cacheService.getVersionCacheDir(forkVersion);

      // Then: Path should include the fork name
      expect(result.path, equals(expectedPath));
    });

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

      final forkDir = Directory(path.join(tempDir.path, forkName));
      forkDir.createSync();

      final versionDir = Directory(path.join(forkDir.path, versionName));
      versionDir.createSync();

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

      final forkDir = Directory(path.join(tempDir.path, forkName));
      forkDir.createSync();

      final versionDir1 = Directory(path.join(forkDir.path, versionName1));
      versionDir1.createSync();

      final versionDir2 = Directory(path.join(forkDir.path, versionName2));
      versionDir2.createSync();

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

      // Print debug information about the versions
      print(
          'Regular version: $regularVersion, fromFork: ${regularVersion.fromFork}, version: ${regularVersion.version}');
      print(
          'Fork version: $forkVersion, fromFork: ${forkVersion.fromFork}, version: ${forkVersion.version}, fork: ${forkVersion.fork}');

      // Create version directories
      final regularDir = cacheService.getVersionCacheDir(regularVersion);
      regularDir.createSync(recursive: true);

      final forkDir = cacheService.getVersionCacheDir(forkVersion);
      forkDir.createSync(recursive: true);

      // Creating version files is crucial for version detection
      // For regular version
      File(path.join(regularDir.path, 'version'))
        ..createSync()
        ..writeAsStringSync('stable');

      // For forked version - this is the key change
      // Adding version file to forked version directory
      File(path.join(forkDir.path, 'version'))
        ..createSync()
        ..writeAsStringSync('master');

      // The key is to make the fork directory look like a non-version directory
      // by ensuring it doesn't have a "version" file directly in it
      final forkParentDir =
          Directory(path.join(tempDir.path, forkVersion.fork!));
      if (File(path.join(forkParentDir.path, 'version')).existsSync()) {
        File(path.join(forkParentDir.path, 'version')).deleteSync();
      }

      // Print directory structure for debugging
      print('Created directory structure:');
      print('Root dir: ${tempDir.path}');
      print('Regular version dir: ${regularDir.path}');
      print('Fork version dir: ${forkDir.path}');

      // When: Getting all versions
      final versions = await cacheService.getAllVersions();

      // Print found versions
      print('Found ${versions.length} versions:');
      for (final version in versions) {
        print('- Version: ${version.name}, fromFork: ${version.fromFork}, '
            'version: ${version.version}, fork: ${version.fork}, '
            'directory: ${version.directory}');
      }

      // Then: Both versions should be found
      expect(versions.length, equals(2),
          reason: 'Expected to find 2 versions, but found ${versions.length}');

      // Check for a standard version
      expect(
        versions.any((v) => v.version == 'stable' && !v.fromFork),
        isTrue,
        reason: 'Standard version "stable" should be found',
      );

      // Check for a forked version
      expect(
        versions.any(
            (v) => v.version == 'master' && v.fromFork && v.fork == 'testfork'),
        isTrue,
        reason: 'Forked version "testfork/master" should be found',
      );
    });
  });
}
