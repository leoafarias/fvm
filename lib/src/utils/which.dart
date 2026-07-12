import 'dart:io';

import 'package:path/path.dart';

// Unlike inspecting mode bits, `test -x` checks access for the current user.
const _posixTestExecutable = '/bin/test';

/// Finds [command] in the executable search path.
///
/// [searchPath] and [pathExtensions] default to `PATH` and `PATHEXT`, and can
/// be supplied explicitly for deterministic callers and tests.
String? which(
  String command, {
  bool binDir = false,
  String? searchPath,
  String? pathExtensions,
}) {
  final pathEnv = searchPath ?? Platform.environment['PATH'];
  final pathExtEnv = Platform.isWindows
      ? (pathExtensions ?? Platform.environment['PATHEXT'])
      : null;

  if (pathEnv == null) {
    return null;
  }

  final paths = pathEnv.split(Platform.isWindows ? ';' : ':');
  final possibleExtensions = pathExtEnv != null ? pathExtEnv.split(';') : [''];

  for (final dir in paths) {
    final fullPath = join(dir, command);
    var executable = File(fullPath);

    if (_isExecutable(executable)) {
      final execPath = executable.absolute.path;

      return binDir ? dirname(execPath) : execPath;
    }

    if (Platform.isWindows && pathExtEnv != null) {
      for (var ext in possibleExtensions) {
        executable = File('$fullPath$ext');
        if (_isExecutable(executable)) {
          final execPath = executable.absolute.path;

          return binDir ? dirname(execPath) : execPath;
        }
      }
    }
  }

  return null;
}

bool _isExecutable(File file) {
  try {
    final stat = file.statSync();
    if (stat.type != FileSystemEntityType.file) return false;
    if (Platform.isWindows) return true;

    final result = Process.runSync(_posixTestExecutable, ['-x', file.path]);

    return result.exitCode == 0;
  } on FileSystemException {
    return false;
  } on ProcessException {
    return false;
  }
}
