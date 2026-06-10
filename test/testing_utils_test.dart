import 'dart:convert';
import 'dart:io';

import 'package:fvm/src/utils/constants.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import 'testing_helpers/prepare_test_environment.dart';
import 'testing_utils.dart';

void main() {
  group('shared FVM test cache layout', () {
    test('older test workspace helpers use the shared cache root', () {
      expect(
        getTempTestDir(),
        p.join(kUserHome, 'fvm_test_cache', 'workspaces'),
      );
      expect(
        getTempTestProjectDir('context-a', 'app'),
        p.join(
          kUserHome,
          'fvm_test_cache',
          'workspaces',
          'context-a',
          'projects',
          'app',
        ),
      );
    });
  });

  group('test temp directories', () {
    test('createTempDir registers cleanup with the current test', () {
      late Directory dir;
      late Directory root;

      addTearDown(() {
        expect(dir.existsSync(), isFalse);
        expect(root.existsSync(), isFalse);
      });

      dir = createTempDir('registered_cleanup');
      root = Directory(p.dirname(dir.path));

      expect(dir.existsSync(), isTrue);
      expect(p.basename(root.path), startsWith('TEST_DIR_fvm_'));
      expect(
        p.isWithin(p.join(kUserHome, 'fvm_test_cache', 'tmp'), root.path),
        isTrue,
      );

      File(p.join(dir.path, 'payload.txt')).writeAsStringSync('data');
    });

    test('stale cleanup deletes only direct TEST_DIR children', () {
      final tempRoot = createTempDir('stale_cleanup_fixture');
      final staleDir = Directory(p.join(tempRoot.path, 'TEST_DIR_legacy'))
        ..createSync();
      final unrelatedDir = Directory(p.join(tempRoot.path, 'fvm_test_data'))
        ..createSync();
      final nestedOwnedDir = Directory(
        p.join(unrelatedDir.path, 'TEST_DIR_nested'),
      )..createSync();

      File(p.join(staleDir.path, 'payload.txt')).writeAsStringSync('data');

      final removed = cleanUpStaleFvmTestTempDirs(
        tempRoot: tempRoot,
        createdBefore: DateTime.now().add(const Duration(seconds: 1)),
      );

      expect(removed, 1);
      expect(staleDir.existsSync(), isFalse);
      expect(unrelatedDir.existsSync(), isTrue);
      expect(nestedOwnedDir.existsSync(), isTrue);
    });

    test('stale cleanup keeps active managed roots', () {
      final tempRoot = createTempDir('active_root_fixture');
      final activeRoot = Directory(p.join(tempRoot.path, 'TEST_DIR_fvm_active'))
        ..createSync();
      File(
        p.join(activeRoot.path, '.fvm_test_temp_root.json'),
      ).writeAsStringSync(jsonEncode({'pid': pid}));

      final removed = cleanUpStaleFvmTestTempDirs(
        tempRoot: tempRoot,
        createdBefore: DateTime.now().add(const Duration(seconds: 1)),
      );

      expect(removed, 0);
      expect(activeRoot.existsSync(), isTrue);
    });
  });
}
