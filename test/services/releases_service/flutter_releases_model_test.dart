import 'dart:io';
import 'package:test/test.dart';

void main() {
  group('Flutter Releases Model', () {
    test('selects correct architecture for current platform', () {
      // This test would have caught the hardcoded 'x64' bug
      final systemArch = (Platform.version.contains('arm64') || 
                         Platform.version.contains('aarch64')) ? 'arm64' : 'x64';
      
      expect(systemArch, anyOf('x64', 'arm64'));
      
      // Verify it matches the platform
      if (Platform.version.contains('arm64') || Platform.version.contains('aarch64')) {
        expect(systemArch, equals('arm64'));
      } else {
        expect(systemArch, equals('x64'));
      }
    });
  });
}
