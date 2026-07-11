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
  });
}

Future<File> _createExecutable(Directory directory, String name) async {
  final file = File(
    p.join(directory.path, Platform.isWindows ? '$name.CMD' : name),
  )..writeAsStringSync(Platform.isWindows ? '@echo off\r\n' : '#!/bin/sh\n');

  if (!Platform.isWindows) {
    final result = await Process.run('chmod', ['+x', file.path]);
    expect(result.exitCode, 0, reason: result.stderr.toString());
  }

  return file;
}
