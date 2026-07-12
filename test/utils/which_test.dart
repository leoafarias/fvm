import 'dart:io';

import 'package:fvm/src/utils/which.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../testing_utils.dart';

void main() {
  group('which', () {
    test('finds an executable in an injected search path', () async {
      final binDir = createTempDir();
      final executable = await _createExecutable(binDir, 'fvm-which-test');

      expect(
        which(
          'fvm-which-test',
          searchPath: binDir.path,
          pathExtensions: Platform.isWindows ? '.CMD' : null,
        ),
        executable.absolute.path,
      );
      expect(
        which(
          'fvm-which-test',
          binDir: true,
          searchPath: binDir.path,
          pathExtensions: Platform.isWindows ? '.CMD' : null,
        ),
        binDir.absolute.path,
      );
    });

    test('returns null when the executable is absent', () {
      expect(
        which('fvm-which-missing', searchPath: createTempDir().path),
        isNull,
      );
    });

    test(
      'skips non-executable files and continues searching',
      () async {
        final firstDir = createTempDir();
        final secondDir = createTempDir();
        File(p.join(firstDir.path, 'fvm-which-test')).writeAsStringSync('');
        final executable = await _createExecutable(secondDir, 'fvm-which-test');
        final separator = Platform.isWindows ? ';' : ':';
        final searchPath = [firstDir.path, secondDir.path].join(separator);

        expect(
          which('fvm-which-test', searchPath: searchPath),
          executable.absolute.path,
        );
      },
      skip: Platform.isWindows
          ? 'Windows executable lookup is based on PATHEXT, not mode bits.'
          : false,
    );

    test(
      'skips files whose execute bit does not apply to the current user',
      () async {
        final firstDir = createTempDir();
        final secondDir = createTempDir();
        final inaccessible = File(p.join(firstDir.path, 'fvm-which-test'))
          ..writeAsStringSync('#!/bin/sh\n');
        await _setMode(inaccessible, '010');
        final executable = await _createExecutable(secondDir, 'fvm-which-test');
        final separator = Platform.isWindows ? ';' : ':';

        expect(
          which(
            'fvm-which-test',
            searchPath: [firstDir.path, secondDir.path].join(separator),
          ),
          executable.absolute.path,
        );
      },
      skip: Platform.isWindows
          ? 'Windows executable lookup is based on PATHEXT, not mode bits.'
          : _isRootUser()
              ? 'Root may execute a file when any execute bit is set.'
              : false,
    );
  });
}

Future<File> _createExecutable(Directory directory, String name) async {
  final file = File(
    p.join(directory.path, Platform.isWindows ? '$name.CMD' : name),
  )..writeAsStringSync(Platform.isWindows ? '@echo off\r\n' : '#!/bin/sh\n');

  if (!Platform.isWindows) {
    await _setMode(file, '+x');
  }

  return file;
}

Future<void> _setMode(File file, String mode) async {
  final result = await Process.run('chmod', [mode, file.path]);
  expect(result.exitCode, 0, reason: result.stderr.toString());
}

bool _isRootUser() {
  final result = Process.runSync('id', ['-u']);

  return result.exitCode == 0 && result.stdout.toString().trim() == '0';
}
