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
  });
}
