import 'dart:io';

import 'package:fvm/src/utils/logger.dart';

/// Returns true if [path] is a directory
bool isDirectory(String path) {
  return FileSystemEntity.typeSync(path) == FileSystemEntityType.directory;
}

/// Creates a symlink from [source] to the [target]
void createLink(Link source, Directory target) {
  // Check if needs to do anything

  final sourceExists = source.existsSync();
  if (sourceExists && source.targetSync() == target.path) {
    logger.detail('Link is setup correctly\n');
    return;
  }

  if (sourceExists) {
    source.deleteSync();
  }

  source.createSync(
    target.path,
    recursive: true,
  );
}
