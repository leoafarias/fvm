import 'dart:io';

import 'package:fvm/fvm.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

import '../testing_utils.dart';

void main() {
  late CacheService cacheService;
  late FvmContext context;
  late Directory tempDir;

  setUp(() {
    // Create test context using TestFactory
    context = TestFactory.context(
      debugLabel: 'get-all-versions-test',
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

  group('getAllVersions', () {
    test('detects versions in both root and fork directories', () async {
      // Setup test directories
      // 1. Standard version: stable
      final stableVersion = FlutterVersion.parse('stable');
      final stableDir = cacheService.getVersionCacheDir(stableVersion);
      stableDir.createSync(recursive: true);
      File(path.join(stableDir.path, 'version'))
        ..createSync()
        ..writeAsStringSync('stable');

      // 2. Fork directory with a version inside
      final forkedVersion = FlutterVersion.parse('testfork/master');
      final forkedVersionDir = cacheService.getVersionCacheDir(forkedVersion);
      forkedVersionDir.createSync(recursive: true);
      File(path.join(forkedVersionDir.path, 'version'))
        ..createSync()
        ..writeAsStringSync('master');

      print('Directory structure:');
      print('- ${tempDir.path}/');
      print('  - stable/');
      print('    - version (content: "stable")');
      print('  - testfork/');
      print('    - master/');
      print('      - version (content: "master")');

      // When: Getting all versions
      final versions = await cacheService.getAllVersions();

      // Debug output
      print('Found ${versions.length} versions:');
      for (final version in versions) {
        print(
            '- ${version.name} (fromFork: ${version.fromFork}, fork: ${version.fork}, '
            'version: ${version.version}, directory: ${version.directory})');
      }

      // Verification
      expect(versions.length, equals(2),
          reason: 'Should find both the regular and forked versions');

      // Find regular version
      final foundStableVersion = versions.firstWhere(
        (v) => v.version == 'stable',
        orElse: () => throw TestFailure('Standard version "stable" not found'),
      );
      expect(foundStableVersion.fromFork, isFalse);
      expect(foundStableVersion.directory, equals(stableDir.path));

      // Find forked version
      final foundMasterVersion = versions.firstWhere(
        (v) => v.version == 'master' && v.fromFork,
        orElse: () => throw TestFailure('Forked version "master" not found'),
      );
      expect(foundMasterVersion.fromFork, isTrue);
      expect(foundMasterVersion.fork, equals('testfork'));
      expect(foundMasterVersion.directory, equals(forkedVersionDir.path));
    });
  });
}
