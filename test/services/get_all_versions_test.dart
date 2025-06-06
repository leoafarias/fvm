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
    tempDir = Directory.systemTemp.createTempSync('fvm_version_test_');

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

  group('getAllVersions', () {
    test('detects versions in both root and fork directories', () async {
      // Setup test directories
      // 1. Standard version: stable
      final stableDir = Directory(path.join(tempDir.path, 'stable'));
      stableDir.createSync();
      File(path.join(stableDir.path, 'version'))
        ..createSync()
        ..writeAsStringSync('stable');

      // 2. Fork directory with a version inside
      final forkDir = Directory(path.join(tempDir.path, 'testfork'));
      forkDir.createSync();

      final forkedVersionDir = Directory(path.join(forkDir.path, 'master'));
      forkedVersionDir.createSync();
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
      final stableVersion = versions.firstWhere(
        (v) => v.version == 'stable',
        orElse: () => throw TestFailure('Standard version "stable" not found'),
      );
      expect(stableVersion.fromFork, isFalse);
      expect(stableVersion.directory, equals(stableDir.path));

      // Find forked version
      final masterVersion = versions.firstWhere(
        (v) => v.version == 'master' && v.fromFork,
        orElse: () => throw TestFailure('Forked version "master" not found'),
      );
      expect(masterVersion.fromFork, isTrue);
      expect(masterVersion.fork, equals('testfork'));
      expect(masterVersion.directory, equals(forkedVersionDir.path));
    });
  });
}
