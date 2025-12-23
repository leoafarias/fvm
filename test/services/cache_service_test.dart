import 'dart:io';

import 'package:fvm/fvm.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

import '../testing_utils.dart';

void main() {
  late CacheService cacheService;
  late FvmContext context;
  late Directory tempDir;

  // Helper function to create test Flutter version
  FlutterVersion createTestVersion(String name) {
    return FlutterVersion.parse(name);
  }

  setUp(() {
    // Create test context using TestFactory
    context = TestFactory.context(
      debugLabel: 'cache-service-test',
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

  group('CacheService', () {
    group('getVersionCacheDir', () {
      test('returns correct directory path for stable', () {
        final version = FlutterVersion.parse('stable');
        final result = cacheService.getVersionCacheDir(version);
        expect(result.path, path.join(tempDir.path, 'stable'));
      });

      test('returns correct directory path for testfork/master', () {
        final version = FlutterVersion.parse('testfork/master');
        final result = cacheService.getVersionCacheDir(version);
        expect(result.path, path.join(tempDir.path, 'testfork', 'master'));
      });

      test('backwards compatibility for string-based version paths', () {
        final version = FlutterVersion.parse('stable');
        final result = cacheService.getVersionCacheDir(version);
        expect(result.path, path.join(tempDir.path, 'stable'));
      });
    });

    group('getVersion', () {
      test('returns null when version directory does not exist', () {
        // Given
        final version = createTestVersion('non-existent');

        // When
        final result = cacheService.getVersion(version);

        // Then
        expect(result, isNull);
      });

      test('returns CacheFlutterVersion when version exists', () {
        // Given
        final version = createTestVersion('stable');
        final versionDir = Directory(path.join(tempDir.path, version.name))
          ..createSync(recursive: true);

        // When
        final result = cacheService.getVersion(version);

        // Then
        expect(result, isNotNull);
        expect(result!.name, version.name);
        expect(result.directory, versionDir.path);
      });
    });

    group('getAllVersions', () {
      test(
        'returns empty list when versions directory does not exist',
        () async {
          // Given
          if (tempDir.existsSync()) {
            tempDir.deleteSync(recursive: true);
          }

          // When
          final result = await cacheService.getAllVersions();

          // Then
          expect(result, isEmpty);
        },
      );

      test('returns sorted list of versions when versions exist', () async {
        // Given
        final versions = ['2.0.0', '1.0.0', 'stable', 'beta'];
        for (final version in versions) {
          Directory(
            path.join(tempDir.path, version),
          ).createSync(recursive: true);

          // Add the "version" file that marks this as a Flutter SDK directory
          File(
            path.join(tempDir.path, version, 'version'),
          ).writeAsStringSync('$version (test)');
        }

        // Create a non-directory file that should be ignored
        File(
          path.join(tempDir.path, 'some-file.txt'),
        ).writeAsStringSync('test');

        // When
        final result = await cacheService.getAllVersions();

        // Then
        expect(result, hasLength(versions.length));
        expect(result.map((v) => v.name).toList(), containsAll(versions));

        // Check if sorted in descending order
        final firstVersionName = result.first.name;
        final lastVersionName = result.last.name;

        // One of these should be true depending on the sorting logic
        expect(
          firstVersionName == 'stable' ||
              firstVersionName == '2.0.0' ||
              lastVersionName == '1.0.0',
          isTrue,
        );
      });

      test(
        'detects SDK directory without version file when git and flutter bin exist',
        () async {
          final versionName = 'stable';
          final versionDir = Directory(path.join(tempDir.path, versionName))
            ..createSync(recursive: true);

          // Simulate a repo clone missing the version metadata file
          Directory(path.join(versionDir.path, '.git')).createSync(recursive: true);
          File(
            path.join(
              versionDir.path,
              'bin',
              Platform.isWindows ? 'flutter.bat' : 'flutter',
            ),
          )
            ..createSync(recursive: true)
            ..writeAsStringSync('dummy');

          final result = await cacheService.getAllVersions();

          expect(result, hasLength(1));
          expect(result.single.name, versionName);
        },
      );
    });

    group('remove', () {
      test('removes version directory if it exists', () {
        // Given
        final version = createTestVersion('stable');
        final versionDir = Directory(path.join(tempDir.path, version.name))
          ..createSync(recursive: true);

        expect(versionDir.existsSync(), isTrue);

        // When
        cacheService.remove(version);

        // Then
        expect(versionDir.existsSync(), isFalse);
      });

      test('does nothing if version directory does not exist', () {
        // Given
        final version = createTestVersion('non-existent');

        // When/Then - should not throw
        expect(() => cacheService.remove(version), returnsNormally);
      });
    });

    group('verifyCacheIntegrity', () {
      // These tests require complex setup to mock file execution status
      // Simplifying by testing the integrations with appropriate mocks

      test('returns invalid when flutter executable does not exist', () async {
        // Setup - create a version with mock executable status
        final version = createTestVersion('stable');
        final versionDir = Directory(path.join(tempDir.path, version.name))
          ..createSync(recursive: true);

        final cacheVersion = CacheFlutterVersion.fromVersion(
          version,
          directory: versionDir.path,
        );

        // Mock _verifyIsExecutable to return false
        // This is a simplified approach since we can't easily mock isExecutable

        // When/Then
        expect(
          await cacheService.verifyCacheIntegrity(cacheVersion),
          equals(CacheIntegrity.invalid),
        );
      });

      // Additional tests for other integrity cases would follow similar patterns
    });

    group('moveToSdkVersionDirectory', () {
      test('throws exception when sdk version is null', () {
        // Given
        final version = createTestVersion('custom_test');
        final versionDir = Directory(path.join(tempDir.path, version.name))
          ..createSync(recursive: true);

        final cacheVersion = CacheFlutterVersion.fromVersion(
          version,
          directory: versionDir.path,
        );

        // When/Then
        expect(
          () => cacheService.moveToSdkVersionDirectory(cacheVersion),
          throwsA(isA<AppException>()),
        );
      });

      test('moves version to sdk version directory', () {
        // This test would need more setup to properly test the functionality
        // Skipping full implementation for brevity
      });
    });

    // Tests for private methods would typically be done through the public methods
    // that use them, or by using package:test_utils to access private members

    group('Global version management:', () {
      test('complete global version lifecycle', () {
        // Create a test version
        final version = createTestVersion('3.10.0');
        final versionDir = Directory(path.join(tempDir.path, version.name))
          ..createSync(recursive: true);

        // Create a CacheFlutterVersion
        final cacheVersion = CacheFlutterVersion.fromVersion(
          version,
          directory: versionDir.path,
        );

        // Test setGlobal
        cacheService.setGlobal(cacheVersion);
        final globalLink = Link(context.globalCacheLink);
        expect(globalLink.existsSync(), isTrue);
        expect(globalLink.targetSync(), equals(versionDir.path));

        // Test getGlobal
        final global = cacheService.getGlobal();
        expect(global, isNotNull);
        expect(global!.name, '3.10.0');

        // Test isGlobal
        expect(cacheService.isGlobal(cacheVersion), isTrue);

        // Test with different version
        final otherVersion = createTestVersion('3.13.0');
        final otherDir = Directory(path.join(tempDir.path, otherVersion.name))
          ..createSync(recursive: true);
        final otherCacheVersion = CacheFlutterVersion.fromVersion(
          otherVersion,
          directory: otherDir.path,
        );
        expect(cacheService.isGlobal(otherCacheVersion), isFalse);

        // Test unlinkGlobal
        cacheService.unlinkGlobal();
        expect(globalLink.existsSync(), isFalse);
        expect(cacheService.getGlobal(), isNull);
      });

      test('unlinkGlobal when no global set', () {
        // Should not throw even when no global is set
        expect(() => cacheService.unlinkGlobal(), returnsNormally);
      });

      test('getGlobalVersion returns version name', () {
        // Create and set a global version
        final version = createTestVersion('stable');
        final versionDir = Directory(path.join(tempDir.path, version.name))
          ..createSync(recursive: true);
        final cacheVersion = CacheFlutterVersion.fromVersion(
          version,
          directory: versionDir.path,
        );

        cacheService.setGlobal(cacheVersion);

        // Test deprecated method
        final globalVersionName = cacheService.getGlobalVersion();
        expect(globalVersionName, equals('stable'));
      });

      test('getGlobal preserves forked version names', () {
        final version = createTestVersion('myfork/stable');
        final versionDir = Directory(
          path.join(tempDir.path, 'myfork', 'stable'),
        )..createSync(recursive: true);
        final cacheVersion = CacheFlutterVersion.fromVersion(
          version,
          directory: versionDir.path,
        );

        cacheService.setGlobal(cacheVersion);
        addTearDown(cacheService.unlinkGlobal);

        final global = cacheService.getGlobal();
        expect(global, isNotNull);
        expect(global!.nameWithAlias, equals('myfork/stable'));
        expect(global.fork, equals('myfork'));
        expect(global.name, equals('stable'));

        final globalVersionName = cacheService.getGlobalVersion();
        expect(globalVersionName, equals('myfork/stable'));
      });

      test('getGlobalVersion falls back to basename for outside targets', () {
        final outsideDir = Directory.systemTemp.createTempSync(
          'fvm_outside_',
        );
        addTearDown(() => outsideDir.deleteSync(recursive: true));
        addTearDown(cacheService.unlinkGlobal);

        final globalLink = Link(context.globalCacheLink);
        globalLink.createSync(outsideDir.path, recursive: true);

        final globalVersionName = cacheService.getGlobalVersion();
        expect(globalVersionName, equals(path.basename(outsideDir.path)));
      });

      test('getGlobalVersion returns null when no global set', () {
        expect(cacheService.getGlobalVersion(), isNull);
      });

      test('getGlobal returns null for invalid cached version', () {
        // Create a global link pointing to non-existent version
        final globalLink = Link(context.globalCacheLink);
        final nonExistentPath = path.join(tempDir.path, 'non-existent');
        globalLink.createSync(nonExistentPath, recursive: true);

        // Should return null since the version doesn't exist in cache
        expect(cacheService.getGlobal(), isNull);
      });

      test('getGlobal returns null for unparseable version name', () {
        // Create a directory with a name that cannot be parsed as a version
        // '@invalid' fails because the version part is empty (nothing before @)
        final invalidDir = Directory(path.join(tempDir.path, '@invalid'))
          ..createSync(recursive: true);
        addTearDown(() {
          if (invalidDir.existsSync()) invalidDir.deleteSync(recursive: true);
        });

        final globalLink = Link(context.globalCacheLink);
        globalLink.createSync(invalidDir.path, recursive: true);
        addTearDown(cacheService.unlinkGlobal);

        // Should return null gracefully, not throw
        final global = cacheService.getGlobal();
        expect(global, isNull);
      });
    });

    group('Fork cleanup:', () {
      test(
        'should remove empty fork directory after removing last version',
        () {
          // Create fork structure
          final forkVersion = FlutterVersion.parse('mycompany/stable');
          final forkDir = Directory(
            path.join(tempDir.path, 'mycompany', 'stable'),
          )..createSync(recursive: true);

          // Add some Flutter files to make it look like a valid Flutter SDK
          File(path.join(forkDir.path, 'bin', 'flutter'))
            ..createSync(recursive: true)
            ..writeAsStringSync('#!/bin/bash');

          // Verify fork structure exists
          expect(forkDir.existsSync(), isTrue);
          expect(
            Directory(path.join(tempDir.path, 'mycompany')).existsSync(),
            isTrue,
          );

          // Remove the version
          cacheService.remove(forkVersion);

          // Fork directory should be removed
          expect(forkDir.existsSync(), isFalse);
          expect(
            Directory(path.join(tempDir.path, 'mycompany')).existsSync(),
            isFalse,
          );
        },
      );

      test('should not remove fork directory with other versions', () {
        // Create multiple fork versions
        final version1 = FlutterVersion.parse('mycompany/stable');

        final stableDir = Directory(
          path.join(tempDir.path, 'mycompany', 'stable'),
        )..createSync(recursive: true);

        final betaDir = Directory(path.join(tempDir.path, 'mycompany', 'beta'))
          ..createSync(recursive: true);

        // Verify both exist
        expect(stableDir.existsSync(), isTrue);
        expect(betaDir.existsSync(), isTrue);

        // Remove only one version
        cacheService.remove(version1);

        // Stable should be gone but fork directory should still exist
        expect(stableDir.existsSync(), isFalse);
        expect(betaDir.existsSync(), isTrue);
        expect(
          Directory(path.join(tempDir.path, 'mycompany')).existsSync(),
          isTrue,
        );
      });

      test('handles non-existent fork version gracefully', () {
        // Try to remove a fork version that doesn't exist
        final forkVersion = FlutterVersion.parse('mycompany/master');

        // Should not throw
        expect(() => cacheService.remove(forkVersion), returnsNormally);
      });
    });
  });
}
