import 'dart:io';

import 'package:fvm/src/utils/atomic_file.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../../testing_utils.dart';

void main() {
  group('replaceFileAtomically', () {
    test('replaces the target with the staged file', () {
      final dir = createTempDir('atomic_ok');
      final target = File(p.join(dir.path, 'projects.json'))
        ..writeAsStringSync('old');
      final staged = File(p.join(dir.path, 'projects.json.1.tmp'))
        ..writeAsStringSync('new');

      replaceFileAtomically(target: target, staged: staged);

      expect(target.readAsStringSync(), 'new');
      expect(staged.existsSync(), isFalse);
      expect(File('${target.path}.bak').existsSync(), isFalse);
    });

    test('keeps the previous file when the replacement cannot be applied', () {
      final dir = createTempDir('atomic_restore');
      final target = File(p.join(dir.path, 'projects.json'))
        ..writeAsStringSync('old');
      final staged = File(p.join(dir.path, 'projects.json.1.tmp'));

      expect(
        () => replaceFileAtomically(target: target, staged: staged),
        throwsA(isA<FileSystemException>()),
      );
      expect(target.existsSync(), isTrue);
      expect(target.readAsStringSync(), 'old');
      expect(File('${target.path}.bak').existsSync(), isFalse);
    });
  });
}
