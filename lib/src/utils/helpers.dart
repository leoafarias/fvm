import 'dart:async';

import 'dart:io';

/// Checks if path is a directory
bool isDirectory(String path) {
  return FileSystemEntity.typeSync(path) == FileSystemEntityType.directory;
}

/// Moves assets from theme directory into brand-app
Future<void> createLink(Link source, FileSystemEntity target) async {
  try {
    if (await source.exists()) {
      await source.delete();
    }
    await source.create(target.path);
  } on FileSystemException {
    if (Platform.isWindows) {
      throw Exception(
          'On Windows FVM requires to run in developer mode or as an administrator');
    }
  } on Exception {
    throw Exception('Sorry could not link ${target.path}');
  }
}
