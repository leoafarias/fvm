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

          File(path.join(versionDir.path, 'version'))
              .writeAsStringSync('$version (test)');

          File(path.join(versionDir.path, 'bin', 'flutter'))
              .createSync(recursive: true);
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

          Directory(path.join(versionDir.path, '.git'))
              .createSync(recursive: true);
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
      test('removes version directory if it exists', () async {
        final version = FlutterVersion.parse('stable');
        final versionDir = Directory(path.join(tempDir.path, version.name))
          ..createSync(recursive: true);
        expect(versionDir.existsSync(), isTrue);

        await cacheService.remove(version);

        expect(versionDir.existsSync(), isFalse);
      });

      test('does nothing if version directory does not exist', () {
        final version = FlutterVersion.parse('non-existent');
        expect(cacheService.remove(version), completes);
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
    });

    group('Global version management:', () {
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
