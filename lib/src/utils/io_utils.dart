import 'dart:io';

import 'package:fvm/src/services/logger_service.dart';

/// Returns true if [path] is a directory
bool isDirectory(String path) {
  return FileSystemEntity.typeSync(path) == FileSystemEntityType.directory;
}

/// Creates a symlink from [source] to the [target]
void createLink(String sourcePath, String targetPath) {
  // Check if needs to do anything
  final source = Link(sourcePath);
  final target = Directory(targetPath);

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
