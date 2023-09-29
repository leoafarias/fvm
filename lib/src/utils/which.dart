import 'dart:io';

import 'package:path/path.dart';

String? which(String command) {
  String? pathEnv = Platform.environment['PATH'];
  String? pathExtEnv =
      Platform.isWindows ? Platform.environment['PATHEXT'] : null;

  if (pathEnv == null) {
    return null;
  }

  List<String> paths = pathEnv.split(Platform.isWindows ? ';' : ':');
  List<String> possibleExtensions =
      pathExtEnv != null ? pathExtEnv.split(';') : [''];

  for (String dir in paths) {
    String fullPath = join(dir, command);
    File exec = File(fullPath);

    if (exec.existsSync()) {
      return exec.absolute.path;
    }

    if (Platform.isWindows && pathExtEnv != null) {
      for (var ext in possibleExtensions) {
        String winPath = '$fullPath$ext';
        exec = File(winPath);
        if (exec.existsSync()) {
          return exec.absolute.path;
        }
      }
    }
  }

  return null;
}
