import 'dart:io';

import 'package:fvm/fvm.dart';
import 'package:fvm/src/models/flutter_version_model.dart';
import 'package:test/test.dart';

void main() {
  group('CacheFlutterVersion', () {
    test('fromMap constructor', () {
      final map = {
        'name': 'test',
        'directory': '/path/to/cache',
        'releaseFromChannel': 'stable',
        'type': 'release',
      };
      final version = CacheFlutterVersion.fromMap(map);
      expect(version.name, 'test');
      expect(version.directory, '/path/to/cache');
      expect(version.releaseFromChannel, 'stable');
      expect(version.type, VersionType.release);
    });

    test('fromJson constructor', () {
      final json =
          '{"name":"test","directory":"/path/to/cache","releaseFromChannel":"stable","type":"release"}';
      final version = CacheFlutterVersion.fromJson(json);
      expect(version.name, 'test');
      expect(version.directory, '/path/to/cache');
      expect(version.releaseFromChannel, 'stable');
      expect(version.type, VersionType.release);
    });

    test('constructor', () {
      final flutterVersion = FlutterVersion.release('1.0.0');
      final cacheVersion =
          CacheFlutterVersion(flutterVersion, directory: '/path/to/cache');
      expect(cacheVersion.name, '1.0.0');
      expect(cacheVersion.directory, '/path/to/cache');
      expect(cacheVersion.releaseFromChannel, isNull);
      expect(cacheVersion.type, VersionType.release);
    });

    test('binPath getter', () {
      final version = CacheFlutterVersion.raw('test',
          directory: '/path/to/cache',
          releaseFromChannel: null,
          type: VersionType.release);
      expect(version.binPath, '/path/to/cache/bin');
    });

    test('hasOldBinPath getter', () {
      final version1 = CacheFlutterVersion.raw('1.17.5',
          directory: '/path/to/cache',
          releaseFromChannel: null,
          type: VersionType.release);
      expect(version1.hasOldBinPath, isTrue);

      final version2 = CacheFlutterVersion.raw('2.0.0',
          directory: '/path/to/cache',
          releaseFromChannel: null,
          type: VersionType.release);
      expect(version2.hasOldBinPath, isFalse);
    });

    test('dartBinPath getter', () {
      final version1 = CacheFlutterVersion.raw('1.17.5',
          directory: '/path/to/cache',
          releaseFromChannel: null,
          type: VersionType.release);
      expect(version1.dartBinPath, '/path/to/cache/bin/cache/dart-sdk/bin');

      final version2 = CacheFlutterVersion.raw('2.0.0',
          directory: '/path/to/cache',
          releaseFromChannel: null,
          type: VersionType.release);
      expect(version2.dartBinPath, '/path/to/cache/bin');
    });

    test('dartExec getter', () {
      final version = CacheFlutterVersion.raw('2.0.0',
          directory: '/path/to/cache',
          releaseFromChannel: null,
          type: VersionType.release);
      expect(version.dartExec, '/path/to/cache/bin/dart');
    });

    test('flutterExec getter', () {
      final version = CacheFlutterVersion.raw('test',
          directory: '/path/to/cache',
          releaseFromChannel: null,
          type: VersionType.release);
      expect(version.flutterExec, '/path/to/cache/bin/flutter');
    });

    test('flutterSdkVersion getter', () {
      // Create a temporary directory for testing
      final tempDir = Directory.systemTemp.createTempSync('cache_version_test');
      final versionFile = File('${tempDir.path}/version');
      versionFile.writeAsStringSync('1.0.0');

      final version = CacheFlutterVersion.raw('test',
          directory: tempDir.path,
          releaseFromChannel: null,
          type: VersionType.release);
      expect(version.flutterSdkVersion, '1.0.0');

      // Clean up the temporary directory
      tempDir.deleteSync(recursive: true);
    });

    test('dartSdkVersion getter', () {
      // Create a temporary directory for testing
      final tempDir = Directory.systemTemp.createTempSync('cache_version_test');
      final dartSdkDir = Directory('${tempDir.path}/bin/cache/dart-sdk');
      dartSdkDir.createSync(recursive: true);
      final versionFile = File('${dartSdkDir.path}/version');
      versionFile.writeAsStringSync('2.12.0');

      final version = CacheFlutterVersion.raw('test',
          directory: tempDir.path,
          releaseFromChannel: null,
          type: VersionType.release);
      expect(version.dartSdkVersion, '2.12.0');

      // Clean up the temporary directory
      tempDir.deleteSync(recursive: true);
    });

    test('isNotSetup getter', () {
      final version = CacheFlutterVersion.raw('test',
          directory: '/path/to/cache',
          releaseFromChannel: null,
          type: VersionType.release);
      expect(version.isNotSetup, isTrue);
    });

    test('isSetup getter', () {
      // Create a temporary directory for testing
      final tempDir = Directory.systemTemp.createTempSync('cache_version_test');
      final versionFile = File('${tempDir.path}/version');
      versionFile.writeAsStringSync('1.0.0');

      final version = CacheFlutterVersion.raw('test',
          directory: tempDir.path,
          releaseFromChannel: null,
          type: VersionType.release);
      expect(version.isSetup, isTrue);

      // Clean up the temporary directory
      tempDir.deleteSync(recursive: true);
    });
  });
}
