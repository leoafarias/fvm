import 'dart:io';

import 'package:fvm/src/utils/extensions.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('extensions_test_');
  });

  tearDown(() {
    if (tempDir.existsSync()) {
      try {
        tempDir.deleteSync(recursive: true);
      } catch (e) {
        // Ignore errors during cleanup
      }
    }
  });

  group('LinkExtensions.createLink', () {
    test('should create a new symlink when none exists', () {
      final linkPath = p.join(tempDir.path, 'test_link');
      final targetPath = p.join(tempDir.path, 'target');

      Directory(targetPath).createSync();
      Link(linkPath).createLink(targetPath);

      expect(Link(linkPath).existsSync(), isTrue);
      expect(Link(linkPath).targetSync(), equals(targetPath));
    });

    test('should do nothing if symlink already points to correct target', () {
      final linkPath = p.join(tempDir.path, 'test_link');
      final targetPath = p.join(tempDir.path, 'target');

      Directory(targetPath).createSync();
      Link(linkPath).createSync(targetPath);

      final modifiedBefore = Link(linkPath).statSync().modified;

      // Call createLink again - should do nothing
      Link(linkPath).createLink(targetPath);

      expect(Link(linkPath).existsSync(), isTrue);
      expect(Link(linkPath).targetSync(), equals(targetPath));

      // Verify link wasn't recreated by checking modified time
      final modifiedAfter = Link(linkPath).statSync().modified;
      expect(modifiedAfter, equals(modifiedBefore));
    });

    test('should update symlink when it points to different target', () {
      final linkPath = p.join(tempDir.path, 'test_link');
      final targetPath1 = p.join(tempDir.path, 'target1');
      final targetPath2 = p.join(tempDir.path, 'target2');

      Directory(targetPath1).createSync();
      Directory(targetPath2).createSync();
      Link(linkPath).createSync(targetPath1);

      expect(Link(linkPath).targetSync(), equals(targetPath1));

      // Update to point to target2
      Link(linkPath).createLink(targetPath2);

      expect(Link(linkPath).existsSync(), isTrue);
      expect(Link(linkPath).targetSync(), equals(targetPath2));
    });

    test('should create parent directories when recursive is true', () {
      final linkPath = p.join(tempDir.path, 'nested', 'dirs', 'test_link');
      final targetPath = p.join(tempDir.path, 'target');

      Directory(targetPath).createSync();

      // Parent directories don't exist yet
      expect(Directory(p.dirname(linkPath)).existsSync(), isFalse);

      Link(linkPath).createLink(targetPath);

      expect(Link(linkPath).existsSync(), isTrue);
      expect(Link(linkPath).targetSync(), equals(targetPath));
      expect(Directory(p.dirname(linkPath)).existsSync(), isTrue);
    });

    test('should handle broken symlink gracefully', () {
      final linkPath = p.join(tempDir.path, 'test_link');
      final targetPath = p.join(tempDir.path, 'target');

      Directory(targetPath).createSync();

      // Create a broken symlink (target doesn't exist)
      final brokenTarget = p.join(tempDir.path, 'nonexistent');
      Link(linkPath).createSync(brokenTarget);

      // Verify it's broken (targetSync() should throw)
      expect(() => Link(linkPath).targetSync(), throwsA(isA<FileSystemException>()));

      // createLink should handle this and recreate with correct target
      Link(linkPath).createLink(targetPath);

      expect(Link(linkPath).existsSync(), isTrue);
      expect(Link(linkPath).targetSync(), equals(targetPath));
    });
  });

  group('DirectoryExtensions', () {
    test('deleteIfExists should delete existing directory', () {
      final dir = Directory(p.join(tempDir.path, 'test_dir'))..createSync();
      expect(dir.existsSync(), isTrue);

      dir.deleteIfExists();
      expect(dir.existsSync(), isFalse);
    });

    test('deleteIfExists should not throw if directory does not exist', () {
      final dir = Directory(p.join(tempDir.path, 'nonexistent'));
      expect(dir.existsSync(), isFalse);

      // Should not throw
      dir.deleteIfExists();
      expect(dir.existsSync(), isFalse);
    });

    test('ensureExists should create directory if it does not exist', () {
      final dir = Directory(p.join(tempDir.path, 'test_dir'));
      expect(dir.existsSync(), isFalse);

      dir.ensureExists();
      expect(dir.existsSync(), isTrue);
    });

    test('ensureExists should not throw if directory already exists', () {
      final dir = Directory(p.join(tempDir.path, 'test_dir'))..createSync();
      expect(dir.existsSync(), isTrue);

      // Should not throw
      dir.ensureExists();
      expect(dir.existsSync(), isTrue);
    });
  });

  group('FileExtensions', () {
    test('read should return file contents if file exists', () {
      final file = File(p.join(tempDir.path, 'test.txt'));
      file.writeAsStringSync('test content');

      expect(file.read(), equals('test content'));
    });

    test('read should return null if file does not exist', () {
      final file = File(p.join(tempDir.path, 'nonexistent.txt'));
      expect(file.read(), isNull);
    });

    test('write should update existing file', () {
      final file = File(p.join(tempDir.path, 'test.txt'));
      file.writeAsStringSync('initial');

      file.write('updated');
      expect(file.readAsStringSync(), equals('updated'));
    });

    test('write should create file and parent directories if they do not exist', () {
      final file = File(p.join(tempDir.path, 'nested', 'test.txt'));
      expect(file.existsSync(), isFalse);

      file.write('content');
      expect(file.existsSync(), isTrue);
      expect(file.readAsStringSync(), equals('content'));
    });
  });

  group('IOExtensions', () {
    test('should correctly identify file types', () {
      final file = File(p.join(tempDir.path, 'test.txt'))
        ..writeAsStringSync('test');
      final dir = Directory(p.join(tempDir.path, 'test_dir'))..createSync();
      final nonexistent = p.join(tempDir.path, 'nonexistent');

      expect(file.path.isFile(), isTrue);
      expect(file.path.isDir(), isFalse);
      expect(file.path.exists(), isTrue);

      expect(dir.path.isDir(), isTrue);
      expect(dir.path.isFile(), isFalse);
      expect(dir.path.exists(), isTrue);

      expect(nonexistent.exists(), isFalse);
      expect(nonexistent.isFile(), isFalse);
      expect(nonexistent.isDir(), isFalse);
    });
  });

  group('StringExtensions', () {
    test('capitalize should capitalize first letter', () {
      expect('hello'.capitalize, equals('Hello'));
      expect('world'.capitalize, equals('World'));
      expect('UPPER'.capitalize, equals('UPPER'));
      expect('a'.capitalize, equals('A'));
    });

    test('capitalize should handle empty string', () {
      expect(''.capitalize, equals(''));
    });

    test('capitalize should preserve rest of string', () {
      expect('helloWorld'.capitalize, equals('HelloWorld'));
      expect('hello_world'.capitalize, equals('Hello_world'));
    });
  });
}
