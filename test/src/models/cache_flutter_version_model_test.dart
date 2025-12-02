import 'dart:io';

import 'package:fvm/fvm.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

void main() {
  group('CacheFlutterVersion', () {
    test('fromMap constructor', () {
      final map = {
        'name': 'test',
        'channel': 'stable',
        'type': 'release',
        'directory': '/path/to/cache',
        'flutterSdkVersion': '3.0.0',
        'dartSdkVersion': '2.17.0',
        'isSetup': true,
      };
      final version = CacheFlutterVersion.fromMap(map);
      expect(version.name, 'test');
      expect(version.directory, '/path/to/cache');
      expect(version.type, VersionType.release);
      expect(version.flutterSdkVersion, '3.0.0');
      expect(version.dartSdkVersion, '2.17.0');
      expect(version.isSetup, isTrue);
    });

    test('fromJson constructor', () {
      final json =
          '{"name":"test","type":"release","directory":"/path/to/cache","flutterSdkVersion":"3.0.0","dartSdkVersion":"2.17.0","isSetup":true}';
      final version = CacheFlutterVersion.fromJson(json);
      expect(version.name, 'test');
      expect(version.directory, '/path/to/cache');
      expect(version.type, VersionType.release);
      expect(version.flutterSdkVersion, '3.0.0');
      expect(version.dartSdkVersion, '2.17.0');
      expect(version.isSetup, isTrue);
    });

    test('constructor', () {
      final flutterVersion = FlutterVersion.release('1.0.0');
      final cacheVersion = CacheFlutterVersion.fromVersion(
        flutterVersion,
        directory: '/path/to/cache',
      );
      expect(cacheVersion.name, '1.0.0');
      expect(cacheVersion.directory, '/path/to/cache');
      expect(cacheVersion.releaseChannel, isNull);
      expect(cacheVersion.type, VersionType.release);
    });

    test('binPath getter', () {
      final version = CacheFlutterVersion.fromVersion(
        FlutterVersion.parse('test'),
        directory: '/path/to/cache',
      );
      // Use platform-aware path construction
      expect(version.binPath, path.join('/path/to/cache', 'bin'));
    });

    test('hasOldBinPath getter', () {
      final version1 = CacheFlutterVersion.fromVersion(
        FlutterVersion.release('1.17.5'),
        directory: '/path/to/cache',
      );
      expect(version1.hasOldBinPath, isTrue);

      final version2 = CacheFlutterVersion.fromVersion(
        FlutterVersion.release('2.0.0'),
        directory: '/path/to/cache',
      );
      expect(version2.hasOldBinPath, isFalse);
    });

    test('dartBinPath getter', () {
      final version1 = CacheFlutterVersion.fromVersion(
        FlutterVersion.release('1.17.5'),
        directory: '/path/to/cache',
      );
      expect(
        version1.dartBinPath,
        path.join('/path/to/cache', 'bin', 'cache', 'dart-sdk', 'bin'),
      );

      final version2 = CacheFlutterVersion.fromVersion(
        FlutterVersion.release('2.0.0'),
        directory: '/path/to/cache',
      );
      expect(version2.dartBinPath, path.join('/path/to/cache', 'bin'));
    });

    test('dartExec getter', () {
      final version = CacheFlutterVersion.fromVersion(
        FlutterVersion.release('2.0.0'),
        directory: '/path/to/cache',
      );
      expect(
        version.dartExec,
        path.join('/path/to/cache', 'bin', dartExecFileName),
      );
    });

    test('flutterExec getter', () {
      final version = CacheFlutterVersion.fromVersion(
        FlutterVersion.release('test'),
        directory: '/path/to/cache',
      );
      expect(
        version.flutterExec,
        path.join('/path/to/cache', 'bin', flutterExecFileName),
      );
    });

    test('flutterSdkVersion getter', () {
      // Create a temporary directory for testing
      final tempDir = Directory.systemTemp.createTempSync('cache_version_test');
      final versionFile = File(path.join(tempDir.path, 'version'));
      versionFile.writeAsStringSync('1.0.0');

      final version = CacheFlutterVersion.fromVersion(
        FlutterVersion.release('test'),
        directory: tempDir.path,
      );
      expect(version.flutterSdkVersion, '1.0.0');

      // Clean up the temporary directory
      tempDir.deleteSync(recursive: true);
    });

    test(
        'flutterSdkVersion returns null when no json or legacy version file present',
        () {
      final tempDir = Directory.systemTemp.createTempSync('cache_version_test');
      // Simulate artifacts existing (dart-sdk/version) so we don't rely on git.
      final dartSdkDir =
          Directory(path.join(tempDir.path, 'bin', 'cache', 'dart-sdk'))
            ..createSync(recursive: true);
      File(path.join(dartSdkDir.path, 'version')).writeAsStringSync('3.9.0');

      final version = CacheFlutterVersion.fromVersion(
        FlutterVersion.release('test'),
        directory: tempDir.path,
      );

      expect(version.flutterSdkVersion, isNull);

      tempDir.deleteSync(recursive: true);
    });

    test(
        'flutterSdkVersion reads flutter.version.json when legacy file missing',
        () {
      final tempDir = Directory.systemTemp.createTempSync('cache_version_test');
      final jsonFile = File(
        path.join(tempDir.path, 'bin', 'cache', 'flutter.version.json'),
      )..createSync(recursive: true);

      final fixture =
          File(path.join('test', 'fixtures', 'flutter.version.example.json'));
      expect(fixture.existsSync(), isTrue,
          reason: 'Fixture flutter.version.example.json is missing');
      jsonFile.writeAsStringSync(fixture.readAsStringSync());

      final version = CacheFlutterVersion.fromVersion(
        FlutterVersion.release('test'),
        directory: tempDir.path,
      );

      expect(version.flutterSdkVersion, '3.33.0-1.0.pre-1070');

      tempDir.deleteSync(recursive: true);
    });

    test('dartSdkVersion getter prefers flutter.version.json when present', () {
      final tempDir = Directory.systemTemp.createTempSync('cache_version_test');
      final jsonFile = File(
        path.join(tempDir.path, 'bin', 'cache', 'flutter.version.json'),
      )..createSync(recursive: true);

      final fixture =
          File(path.join('test', 'fixtures', 'flutter.version.example.json'));
      expect(fixture.existsSync(), isTrue,
          reason: 'Fixture flutter.version.example.json is missing');
      jsonFile.writeAsStringSync(fixture.readAsStringSync());

      final version = CacheFlutterVersion.fromVersion(
        FlutterVersion.release('test'),
        directory: tempDir.path,
      );
      expect(
        version.dartSdkVersion,
        '3.10.0 (build 3.10.0-15.0.dev)',
      );

      tempDir.deleteSync(recursive: true);
    });

    test('dartSdkVersion getter', () {
      // Create a temporary directory for testing
      final tempDir = Directory.systemTemp.createTempSync('cache_version_test');
      final dartSdkDir =
          Directory(path.join(tempDir.path, 'bin', 'cache', 'dart-sdk'));
      dartSdkDir.createSync(recursive: true);
      final versionFile = File(path.join(dartSdkDir.path, 'version'));
      versionFile.writeAsStringSync('2.12.0');

      final version = CacheFlutterVersion.fromVersion(
        FlutterVersion.release('test'),
        directory: tempDir.path,
      );
      expect(version.dartSdkVersion, '2.12.0');

      // Clean up the temporary directory
      tempDir.deleteSync(recursive: true);
    });

    test('isNotSetup getter', () {
      final version = CacheFlutterVersion.fromVersion(
        FlutterVersion.release('test'),
        directory: '/path/to/cache',
      );
      expect(version.isNotSetup, isTrue);
    });

    test('isSetup getter', () {
      // Create a temporary directory for testing
      final tempDir = Directory.systemTemp.createTempSync('cache_version_test');
      // isSetup now checks for dart-sdk/bin/ directory existence (more robust)
      final dartSdkBinDir =
          Directory(path.join(tempDir.path, 'bin', 'cache', 'dart-sdk', 'bin'))
            ..createSync(recursive: true);
      // Also create version file so dartSdkVersion is populated
      File(path.join(dartSdkBinDir.parent.path, 'version'))
          .writeAsStringSync('3.9.0');

      final version = CacheFlutterVersion.fromVersion(
        FlutterVersion.release('test'),
        directory: tempDir.path,
      );
      expect(version.isSetup, isTrue);
      expect(version.dartSdkVersion, '3.9.0');

      // Clean up the temporary directory
      tempDir.deleteSync(recursive: true);
    });

    test('flutterSdkVersion is null when no version sources available', () {
      final tempDir = Directory.systemTemp.createTempSync('no_version_');

      final version = CacheFlutterVersion.fromVersion(
        FlutterVersion.parse('test'),
        directory: tempDir.path,
      );

      expect(version.flutterSdkVersion, isNull);
      expect(version.isSetup, isFalse);

      tempDir.deleteSync(recursive: true);
    });
  });
}
