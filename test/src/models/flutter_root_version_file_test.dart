import 'dart:io';

import 'package:fvm/src/models/flutter_root_version_file.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

void main() {
  group('FlutterRootVersionFile', () {
    test('parses sample file', () {
      final fixturePath =
          path.join('test', 'fixtures', 'flutter.version.example.json');
      final file = File(fixturePath);
      expect(file.existsSync(), isTrue);

      final metadata = FlutterRootVersionFile.tryLoadFromFile(file);
      expect(metadata, isNotNull);
      expect(metadata!.primaryVersion, '3.33.0-1.0.pre-1070');
      expect(metadata.channel, 'master');
      expect(metadata.dartSdkVersion, startsWith('3.10.0'));
    });

    test('falls back to frameworkVersion when flutterVersion missing', () {
      final metadata =
          FlutterRootVersionFile.fromMap({'frameworkVersion': '3.2.0'});

      expect(metadata.primaryVersion, '3.2.0');
    });

    test('returns null when file missing', () {
      final missing = FlutterRootVersionFile.tryLoadFromFile(
        File(path.join('test', 'fixtures', 'no_such_file.json')),
      );

      expect(missing, isNull);
    });

    test('returns null for malformed JSON', () {
      final tempDir = Directory.systemTemp.createTempSync('malformed_');
      final file = File(path.join(tempDir.path, 'flutter.version.json'));
      file.writeAsStringSync('{ invalid json }');

      expect(FlutterRootVersionFile.tryLoadFromFile(file), isNull);

      tempDir.deleteSync(recursive: true);
    });

    test('returns null for JSON array instead of object', () {
      final tempDir = Directory.systemTemp.createTempSync('array_');
      final file = File(path.join(tempDir.path, 'flutter.version.json'));
      file.writeAsStringSync('["3.0.0"]');

      expect(FlutterRootVersionFile.tryLoadFromFile(file), isNull);

      tempDir.deleteSync(recursive: true);
    });

    test('returns null for empty file', () {
      final tempDir = Directory.systemTemp.createTempSync('empty_');
      final file = File(path.join(tempDir.path, 'flutter.version.json'));
      file.writeAsStringSync('');

      expect(FlutterRootVersionFile.tryLoadFromFile(file), isNull);

      tempDir.deleteSync(recursive: true);
    });
  });
}
