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
    context = TestFactory.context(
      debugLabel: 'cache-service-test',
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

      test('preserves valid nested git refs and fork cache paths', () {
        expect(
          cacheService
              .getVersionCacheDir(FlutterVersion.gitReference('feature/foo'))
              .path,
          path.join(tempDir.path, 'feature', 'foo'),
        );
        expect(
          cacheService
              .getVersionCacheDir(FlutterVersion.parse('company/stable'))
              .path,
          path.join(tempDir.path, 'company', 'stable'),
        );
      });

      test('rejects unsafe version path components', () {
        final existingEntry = Directory(path.join(tempDir.path, 'stable'))
          ..createSync(recursive: true);
        final marker = File(path.join(existingEntry.path, 'marker'))
          ..writeAsStringSync('preserve');

        for (final version in [
          '',
          '.',
          '..',
          'feature//foo',
          'feature/',
          '../outside',
          r'..\outside',
          r'feature\foo',
          '/tmp/fvm-outside',
          r'C:\fvm-outside',
          'C:/fvm-outside',
          r'\\server\share',
        ]) {
          expect(
            () => cacheService.getVersionCacheDir(
              FlutterVersion.gitReference(version),
            ),
            throwsA(isA<AppException>()),
            reason: 'Expected "$version" to be rejected',
          );
        }

        expect(marker.readAsStringSync(), 'preserve');
      });

      test(
        'rejects a cache path that traverses a symlinked ancestor',
        () {
          final outside = createTempDir('external_cache_ancestor');
          final linkedFork = Link(path.join(tempDir.path, 'company'))
            ..createSync(outside.path, recursive: true);
          addTearDown(() {
            if (linkedFork.existsSync()) linkedFork.deleteSync();
          });

          expect(
            () => cacheService.getVersionCacheDir(
              FlutterVersion.parse('company/stable'),
            ),
            throwsA(isA<AppException>()),
          );
        },
        skip: Platform.isWindows
            ? 'Creating symlinks requires privileges on Windows.'
            : false,
      );
    });

    group('getVersion', () {
      test('returns null when version directory does not exist', () {
        final version = FlutterVersion.parse('non-existent');
        final result = cacheService.getVersion(version);
        expect(result, isNull);
      });

      test('returns CacheFlutterVersion when version exists', () {
        final version = FlutterVersion.parse('stable');
        final versionDir = Directory(path.join(tempDir.path, version.name))
          ..createSync(recursive: true);

        final result = cacheService.getVersion(version);
        expect(result, isNotNull);
        expect(result!.name, version.name);
        expect(result.directory, versionDir.path);
      });
    });

    group('getAllVersions', () {
      test(
        'returns empty list when versions directory does not exist',
        () async {
          if (tempDir.existsSync()) {
            tempDir.deleteSync(recursive: true);
          }

          final result = await cacheService.getAllVersions();
          expect(result, isEmpty);
        },
      );

      test('returns sorted list of versions when versions exist', () async {
        final versions = ['2.0.0', '1.0.0', 'stable', 'beta'];
        for (final version in versions) {
          final versionDir = Directory(path.join(tempDir.path, version))
            ..createSync(recursive: true);

          File(
            path.join(versionDir.path, 'version'),
          ).writeAsStringSync('$version (test)');

          File(
            path.join(versionDir.path, 'bin', 'flutter'),
          ).createSync(recursive: true);
        }

        File(
          path.join(tempDir.path, 'some-file.txt'),
        ).writeAsStringSync('test');

        final result = await cacheService.getAllVersions();
        expect(result, hasLength(versions.length));
        expect(result.map((v) => v.name).toList(), containsAll(versions));

        final firstVersionName = result.first.name;
        final lastVersionName = result.last.name;

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

          Directory(
            path.join(versionDir.path, '.git'),
          ).createSync(recursive: true);
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
      test('rejects unsafe paths without deleting cache entries', () async {
        final existingEntry = Directory(path.join(tempDir.path, 'stable'))
          ..createSync(recursive: true);
        final marker = File(path.join(existingEntry.path, 'marker'))
          ..writeAsStringSync('preserve');

        await expectLater(
          cacheService.remove(FlutterVersion.gitReference('.')),
          throwsA(isA<AppException>()),
        );

        expect(marker.readAsStringSync(), 'preserve');
        expect(existingEntry.existsSync(), isTrue);
      });

      test('removes version directory if it exists', () async {
        final version = FlutterVersion.parse('stable');
        final versionDir = Directory(path.join(tempDir.path, version.name))
          ..createSync(recursive: true);
        expect(versionDir.existsSync(), isTrue);

        await cacheService.remove(version);

        expect(versionDir.existsSync(), isFalse);
      });

      test(
        'does not delete through a symlinked cache ancestor',
        () async {
          final outside = createTempDir('external_cache_remove');
          final outsideVersion = Directory(path.join(outside.path, 'stable'))
            ..createSync(recursive: true);
          final marker = File(path.join(outsideVersion.path, 'marker'))
            ..writeAsStringSync('preserve');
          final linkedFork = Link(path.join(tempDir.path, 'company'))
            ..createSync(outside.path, recursive: true);
          addTearDown(() {
            if (linkedFork.existsSync()) linkedFork.deleteSync();
          });

          await expectLater(
            cacheService.remove(FlutterVersion.parse('company/stable')),
            throwsA(isA<AppException>()),
          );

          expect(marker.readAsStringSync(), 'preserve');
        },
        skip: Platform.isWindows
            ? 'Creating symlinks requires privileges on Windows.'
            : false,
      );

      test(
        'does not delete through a symlinked versions cache root',
        () async {
          final outside = createTempDir('external_versions_root_remove');
          final outsideVersion = Directory(path.join(outside.path, 'stable'))
            ..createSync(recursive: true);
          final marker = File(path.join(outsideVersion.path, 'marker'))
            ..writeAsStringSync('preserve');
          Directory(path.dirname(tempDir.path)).createSync(recursive: true);
          final linkedRoot = Link(tempDir.path)
            ..createSync(outside.path, recursive: true);
          addTearDown(() {
            if (linkedRoot.existsSync()) linkedRoot.deleteSync();
          });

          await expectLater(
            cacheService.remove(FlutterVersion.parse('stable')),
            throwsA(isA<AppException>()),
          );

          expect(marker.readAsStringSync(), 'preserve');
        },
        skip: Platform.isWindows
            ? 'Creating symlinks requires privileges on Windows.'
            : false,
      );

      test('does nothing if version directory does not exist', () {
        final version = FlutterVersion.parse('non-existent');
        expect(cacheService.remove(version), completes);
      });

      test('unlinks a removed global version', () async {
        final version = FlutterVersion.parse('stable');
        final versionDir = Directory(path.join(tempDir.path, version.name))
          ..createSync(recursive: true);
        final cacheVersion = CacheFlutterVersion.fromVersion(
          version,
          directory: versionDir.path,
        );
        cacheService.setGlobal(cacheVersion);
        final globalLink = Link(context.globalCacheLink);

        await cacheService.remove(version);

        expect(versionDir.existsSync(), isFalse);
        expect(globalLink.existsSync(), isFalse);
      });

      test('removeAll preserves a global link outside the versions cache',
          () async {
        final versionDir = Directory(path.join(tempDir.path, 'stable'))
          ..createSync(recursive: true);
        final outsideDir = createTempDir('external_global');
        addTearDown(() => outsideDir.deleteSync(recursive: true));
        final globalLink = Link(context.globalCacheLink)
          ..createSync(outsideDir.path, recursive: true);

        expect(await cacheService.removeAll(), isTrue);

        expect(versionDir.existsSync(), isFalse);
        expect(globalLink.existsSync(), isTrue);
        expect(globalLink.targetSync(), outsideDir.path);
      });
    });

    group('verifyCacheIntegrity', () {
      test('returns invalid when flutter executable does not exist', () async {
        final version = FlutterVersion.parse('stable');
        final versionDir = Directory(path.join(tempDir.path, version.name))
          ..createSync(recursive: true);

        final cacheVersion = CacheFlutterVersion.fromVersion(
          version,
          directory: versionDir.path,
        );

        expect(
          await cacheService.verifyCacheIntegrity(cacheVersion),
          equals(CacheIntegrity.invalid),
        );
      });
    });

    group('moveToSdkVersionDirectory', () {
      test('throws exception when sdk version is null', () {
        final version = FlutterVersion.parse('custom_test');
        final versionDir = Directory(path.join(tempDir.path, version.name))
          ..createSync(recursive: true);

        final cacheVersion = CacheFlutterVersion.fromVersion(
          version,
          directory: versionDir.path,
        );

        expect(
          () => cacheService.moveToSdkVersionDirectory(cacheVersion),
          throwsA(isA<AppException>()),
        );
      });

      test('moves a mismatched SDK into an available cache directory', () {
        final sourceDir = Directory(path.join(tempDir.path, '3.10.0'))
          ..createSync(recursive: true);
        File(path.join(sourceDir.path, 'marker')).writeAsStringSync('moved');
        final cacheVersion = CacheFlutterVersion(
          '3.10.0',
          type: VersionType.release,
          directory: sourceDir.path,
          flutterSdkVersion: '3.10.5',
          dartSdkVersion: null,
          isSetup: false,
        );

        cacheService.moveToSdkVersionDirectory(cacheVersion);

        expect(sourceDir.existsSync(), isFalse);
        expect(
          File(path.join(tempDir.path, '3.10.5', 'marker')).readAsStringSync(),
          'moved',
        );
      });

      test(
        'does not move an SDK through a symlinked cache ancestor',
        () {
          final outside = createTempDir('external_cache_move');
          final sourceDir = Directory(path.join(outside.path, 'stable'))
            ..createSync(recursive: true);
          final marker = File(path.join(sourceDir.path, 'marker'))
            ..writeAsStringSync('preserve');
          File(path.join(sourceDir.path, 'version'))
              .writeAsStringSync('3.10.5');
          final linkedFork = Link(path.join(tempDir.path, 'company'))
            ..createSync(outside.path, recursive: true);
          addTearDown(() {
            if (linkedFork.existsSync()) linkedFork.deleteSync();
          });
          final cacheVersion = CacheFlutterVersion.fromVersion(
            FlutterVersion.parse('company/stable'),
            directory: path.join(tempDir.path, 'company', 'stable'),
          );

          expect(
            () => cacheService.moveToSdkVersionDirectory(cacheVersion),
            throwsA(isA<AppException>()),
          );
          expect(marker.readAsStringSync(), 'preserve');
          expect(
            Directory(path.join(outside.path, '3.10.5')).existsSync(),
            isFalse,
          );
        },
        skip: Platform.isWindows
            ? 'Creating symlinks requires privileges on Windows.'
            : false,
      );

      test(
        'does not move an SDK through a symlinked versions cache root',
        () {
          final outside = createTempDir('external_versions_root_move');
          final sourceDir = Directory(path.join(outside.path, 'stable'))
            ..createSync(recursive: true);
          final marker = File(path.join(sourceDir.path, 'marker'))
            ..writeAsStringSync('preserve');
          File(path.join(sourceDir.path, 'version'))
              .writeAsStringSync('3.10.5');
          Directory(path.dirname(tempDir.path)).createSync(recursive: true);
          final linkedRoot = Link(tempDir.path)
            ..createSync(outside.path, recursive: true);
          addTearDown(() {
            if (linkedRoot.existsSync()) linkedRoot.deleteSync();
          });
          final cacheVersion = CacheFlutterVersion.fromVersion(
            FlutterVersion.parse('stable'),
            directory: path.join(tempDir.path, 'stable'),
          );

          expect(
            () => cacheService.moveToSdkVersionDirectory(cacheVersion),
            throwsA(isA<AppException>()),
          );
          expect(marker.readAsStringSync(), 'preserve');
          expect(
            Directory(path.join(outside.path, '3.10.5')).existsSync(),
            isFalse,
          );
        },
        skip: Platform.isWindows
            ? 'Creating symlinks requires privileges on Windows.'
            : false,
      );

      test('does not replace an existing SDK cache directory', () {
        final sourceDir = Directory(path.join(tempDir.path, '3.10.0'))
          ..createSync(recursive: true);
        final targetDir = Directory(path.join(tempDir.path, '3.10.5'))
          ..createSync(recursive: true);
        File(path.join(sourceDir.path, 'source')).writeAsStringSync('source');
        File(path.join(targetDir.path, 'target')).writeAsStringSync('target');
        final cacheVersion = CacheFlutterVersion(
          '3.10.0',
          type: VersionType.release,
          directory: sourceDir.path,
          flutterSdkVersion: '3.10.5',
          dartSdkVersion: null,
          isSetup: false,
        );

        expect(
          () => cacheService.moveToSdkVersionDirectory(cacheVersion),
          throwsA(isA<AppException>()),
        );
        expect(File(path.join(sourceDir.path, 'source')).readAsStringSync(),
            'source');
        expect(File(path.join(targetDir.path, 'target')).readAsStringSync(),
            'target');
      });

      test('does nothing when the SDK is already in the correct directory', () {
        final versionDir = Directory(path.join(tempDir.path, '3.10.0'))
          ..createSync(recursive: true);
        final marker = File(path.join(versionDir.path, 'marker'))
          ..writeAsStringSync('preserved');
        final cacheVersion = CacheFlutterVersion(
          '3.10.0',
          type: VersionType.release,
          directory: versionDir.path,
          flutterSdkVersion: '3.10.0',
          dartSdkVersion: null,
          isSetup: false,
        );

        expect(
          () => cacheService.moveToSdkVersionDirectory(cacheVersion),
          returnsNormally,
        );
        expect(marker.readAsStringSync(), 'preserved');
      });
    });

    group('Global version management:', () {
      test('rejects the versions root as a global SDK directory', () {
        final rootVersion = CacheFlutterVersion.fromVersion(
          FlutterVersion.parse('stable'),
          directory: tempDir.path,
        );
        addTearDown(cacheService.unlinkGlobal);

        expect(
          () => cacheService.setGlobal(rootVersion),
          throwsA(isA<AppException>()),
        );
        expect(Link(context.globalCacheLink).existsSync(), isFalse);
      });

      test('complete global version lifecycle', () {
        final version = FlutterVersion.parse('3.10.0');
        final versionDir = Directory(path.join(tempDir.path, version.name))
          ..createSync(recursive: true);

        final cacheVersion = CacheFlutterVersion.fromVersion(
          version,
          directory: versionDir.path,
        );

        cacheService.setGlobal(cacheVersion);
        final globalLink = Link(context.globalCacheLink);
        expect(globalLink.existsSync(), isTrue);
        expect(globalLink.targetSync(), equals(versionDir.path));

        final global = cacheService.getGlobal();
        expect(global, isNotNull);
        expect(global!.name, '3.10.0');

        expect(cacheService.isGlobal(cacheVersion), isTrue);

        final otherVersion = FlutterVersion.parse('3.13.0');
        final otherDir = Directory(path.join(tempDir.path, otherVersion.name))
          ..createSync(recursive: true);
        final otherCacheVersion = CacheFlutterVersion.fromVersion(
          otherVersion,
          directory: otherDir.path,
        );
        expect(cacheService.isGlobal(otherCacheVersion), isFalse);

        cacheService.unlinkGlobal();
        expect(globalLink.existsSync(), isFalse);
        expect(cacheService.getGlobal(), isNull);
      });

      test('unlinkGlobal when no global set', () {
        expect(() => cacheService.unlinkGlobal(), returnsNormally);
      });

      test('getGlobalVersion returns version name', () {
        final version = FlutterVersion.parse('stable');
        final versionDir = Directory(path.join(tempDir.path, version.name))
          ..createSync(recursive: true);
        final cacheVersion = CacheFlutterVersion.fromVersion(
          version,
          directory: versionDir.path,
        );

        cacheService.setGlobal(cacheVersion);

        final globalVersionName = cacheService.getGlobalVersion();
        expect(globalVersionName, equals('stable'));
      });

      test('getGlobal preserves forked version names', () {
        final version = FlutterVersion.parse('myfork/stable');
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
        final outsideDir = createTempDir('fvm_outside');
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
        final globalLink = Link(context.globalCacheLink);
        final nonExistentPath = path.join(tempDir.path, 'non-existent');
        globalLink.createSync(nonExistentPath, recursive: true);

        expect(cacheService.getGlobal(), isNull);
      });

      test('getGlobal returns null for unparseable version name', () {
        final invalidDir = Directory(path.join(tempDir.path, '@invalid'))
          ..createSync(recursive: true);
        addTearDown(() {
          if (invalidDir.existsSync()) invalidDir.deleteSync(recursive: true);
        });

        final globalLink = Link(context.globalCacheLink);
        globalLink.createSync(invalidDir.path, recursive: true);
        addTearDown(cacheService.unlinkGlobal);

        final global = cacheService.getGlobal();
        expect(global, isNull);
      });
    });

    group('Fork cleanup:', () {
      test(
        'should remove empty fork directory after removing last version',
        () async {
          final forkVersion = FlutterVersion.parse('mycompany/stable');
          final forkDir = Directory(
            path.join(tempDir.path, 'mycompany', 'stable'),
          )..createSync(recursive: true);

          File(path.join(forkDir.path, 'bin', 'flutter'))
            ..createSync(recursive: true)
            ..writeAsStringSync('#!/bin/bash');

          expect(forkDir.existsSync(), isTrue);
          expect(
            Directory(path.join(tempDir.path, 'mycompany')).existsSync(),
            isTrue,
          );

          await cacheService.remove(forkVersion);

          expect(forkDir.existsSync(), isFalse);
          expect(
            Directory(path.join(tempDir.path, 'mycompany')).existsSync(),
            isFalse,
          );
        },
      );

      test('should not remove fork directory with other versions', () async {
        final version1 = FlutterVersion.parse('mycompany/stable');

        final stableDir = Directory(
          path.join(tempDir.path, 'mycompany', 'stable'),
        )..createSync(recursive: true);

        final betaDir = Directory(path.join(tempDir.path, 'mycompany', 'beta'))
          ..createSync(recursive: true);

        expect(stableDir.existsSync(), isTrue);
        expect(betaDir.existsSync(), isTrue);

        await cacheService.remove(version1);

        expect(stableDir.existsSync(), isFalse);
        expect(betaDir.existsSync(), isTrue);
        expect(
          Directory(path.join(tempDir.path, 'mycompany')).existsSync(),
          isTrue,
        );
      });

      test('handles non-existent fork version gracefully', () {
        final forkVersion = FlutterVersion.parse('mycompany/master');
        expect(cacheService.remove(forkVersion), completes);
      });
    });
  });
}
